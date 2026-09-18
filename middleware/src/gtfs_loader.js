// Módulo de carregamento e indexação dos dados GTFS da SPTrans
// Parseia os CSVs (routes, trips, shapes, stops, stop_times) na inicialização
// e mantém índices em memória para consulta rápida.
//
// Os shapes GTFS fornecem os trajetos reais das vias percorridas pelos ônibus,
// algo que a API Olho Vivo NÃO fornece (ela só tem posições e paradas).

const fs = require('fs');
const path = require('path');
const readline = require('readline');
const { parse } = require('csv-parse/sync');

// Diretório padrão dos dados GTFS
const GTFS_DIR = process.env.GTFS_PATH || path.join(__dirname, '..', 'gtfs_data');

// Índices em memória
const routes = new Map();        // route_id -> { route_id, route_short_name, route_long_name, route_color, route_text_color }
const trips = new Map();         // trip_id -> { route_id, service_id, trip_id, trip_headsign, direction_id, shape_id }
const shapes = new Map();        // shape_id -> Float32Array([lat, lon, lat, lon, ...]) para memória ultra-baixa (38MB vs 700MB)
const stops = new Map();         // stop_id -> { stop_id, stop_name, stop_lat, stop_lon }
const routeTrips = new Map();    // route_id -> [trip objects]
const routeStopIds = new Map();  // route_id -> Set<stop_id>
const stopTimesByTrip = new Map(); // trip_id -> [{ stop_id, stop_sequence, arrival_time, departure_time }]

// Índice de busca textual: route_short_name (letreiro) -> route_id
const shortNameIndex = new Map(); // "8000-10" -> route_id

let carregado = false;
let totalRotas = 0;
let totalShapes = 0;
let totalParadas = 0;

/**
 * Lê e parseia um arquivo CSV do GTFS.
 * Os arquivos GTFS da SPTrans usam aspas como delimitador de texto e vírgula como separador.
 */
function lerCsv(nomeArquivo) {
  const caminho = path.join(GTFS_DIR, nomeArquivo);
  if (!fs.existsSync(caminho)) {
    console.warn(`[gtfs] Arquivo não encontrado: ${caminho}`);
    return [];
  }

  const conteudo = fs.readFileSync(caminho, 'utf-8');
  try {
    return parse(conteudo, {
      columns: true,
      skip_empty_lines: true,
      trim: true,
      relax_quotes: true,
      relax_column_count: true,
    });
  } catch (err) {
    console.error(`[gtfs] Erro ao parsear ${nomeArquivo}: ${err.message}`);
    return [];
  }
}

/**
 * Carrega shapes com streaming linha a linha e armazena em Float32Array.
 * Reduz o consumo de memória de ~700MB para ~38MB, permitindo rodar em planos gratuitos (Render 512MB).
 */
function carregarShapesStream(caminho) {
  return new Promise((resolve) => {
    if (!fs.existsSync(caminho)) {
      console.warn(`[gtfs] Arquivo não encontrado: ${caminho}`);
      return resolve();
    }

    const rl = readline.createInterface({
      input: fs.createReadStream(caminho),
      crlfDelay: Infinity,
    });

    let isHeader = true;
    let totalPontos = 0;

    rl.on('line', (line) => {
      if (isHeader) {
        isHeader = false;
        return;
      }
      if (!line) return;
      const c1 = line.indexOf(',');
      if (c1 === -1) return;
      const c2 = line.indexOf(',', c1 + 1);
      if (c2 === -1) return;
      const c3 = line.indexOf(',', c2 + 1);

      let shapeId = line.slice(0, c1);
      let latStr = line.slice(c1 + 1, c2);
      let lonStr = c3 === -1 ? line.slice(c2 + 1) : line.slice(c2 + 1, c3);

      if (shapeId.charCodeAt(0) === 34) {
        shapeId = shapeId.slice(1, -1);
      }
      if (latStr.charCodeAt(0) === 34) {
        latStr = latStr.slice(1, -1);
      }
      if (lonStr.charCodeAt(0) === 34) {
        lonStr = lonStr.slice(1, -1);
      }

      const lat = parseFloat(latStr);
      const lon = parseFloat(lonStr);

      let arr = shapes.get(shapeId);
      if (!arr) {
        arr = [];
        shapes.set(shapeId, arr);
      }
      arr.push(lat, lon);
      totalPontos++;
    });

    rl.on('close', () => {
      for (const [id, arr] of shapes) {
        shapes.set(id, new Float32Array(arr));
      }
      totalShapes = shapes.size;
      console.log(`[gtfs]   ${totalShapes} shapes carregados (${totalPontos} pontos em Float32Array - ~38MB RAM)`);
      resolve();
    });

    rl.on('error', (err) => {
      console.warn(`[gtfs] Erro ao ler stream de shapes: ${err.message}`);
      resolve();
    });
  });
}

/**
 * Carrega todos os dados GTFS na memória de forma otimizada.
 * Chamado uma vez na inicialização do servidor.
 */
async function carregarGtfs() {
  if (carregado) return;

  console.log(`[gtfs] Carregando dados GTFS de: ${GTFS_DIR}`);
  const inicio = Date.now();

  // 1. ROUTES - Rotas/Linhas com cores oficiais
  const rotasRaw = lerCsv('routes.txt');
  for (const r of rotasRaw) {
    const routeId = r.route_id || r.route_short_name;
    if (!routeId) continue;
    const obj = {
      route_id: routeId,
      agency_id: r.agency_id || '',
      route_short_name: r.route_short_name || routeId,
      route_long_name: r.route_long_name || '',
      route_type: parseInt(r.route_type || '3', 10),
      route_color: r.route_color ? `#${r.route_color}` : '#C00000',
      route_text_color: r.route_text_color ? `#${r.route_text_color}` : '#FFFFFF',
    };
    routes.set(routeId, obj);
    shortNameIndex.set(obj.route_short_name.toUpperCase(), routeId);
  }
  totalRotas = routes.size;
  console.log(`[gtfs]   ${totalRotas} rotas carregadas`);

  // 2. TRIPS - Viagens (vinculam route_id a shape_id)
  const tripsRaw = lerCsv('trips.txt');
  for (const t of tripsRaw) {
    const tripId = t.trip_id;
    if (!tripId) continue;
    const obj = {
      route_id: t.route_id || '',
      service_id: t.service_id || '',
      trip_id: tripId,
      trip_headsign: t.trip_headsign || '',
      direction_id: parseInt(t.direction_id || '0', 10),
      shape_id: t.shape_id || '',
    };
    trips.set(tripId, obj);

    if (!routeTrips.has(obj.route_id)) {
      routeTrips.set(obj.route_id, []);
    }
    routeTrips.get(obj.route_id).push(obj);
  }
  console.log(`[gtfs]   ${trips.size} trips carregadas`);

  // 3. SHAPES - Trajetos georreferenciados das vias (Streaming de baixo consumo de RAM)
  console.log(`[gtfs]   Carregando shapes via stream (otimizado para Render free tier)...`);
  const caminhoShapes = path.join(GTFS_DIR, 'shapes.txt');
  await carregarShapesStream(caminhoShapes);

  // 4. STOPS - Paradas com coordenadas
  const stopsRaw = lerCsv('stops.txt');
  for (const s of stopsRaw) {
    const stopId = s.stop_id;
    if (!stopId) continue;
    stops.set(stopId, {
      stop_id: stopId,
      stop_name: s.stop_name || '',
      stop_desc: s.stop_desc || '',
      stop_lat: parseFloat(s.stop_lat || '0'),
      stop_lon: parseFloat(s.stop_lon || '0'),
    });
  }
  totalParadas = stops.size;
  console.log(`[gtfs]   ${totalParadas} paradas carregadas`);

  // 5. STOP_TIMES - Vincula paradas a trips (e consequentemente a rotas)
  const stopTimesRaw = lerCsv('stop_times.txt');
  for (const st of stopTimesRaw) {
    const tripId = st.trip_id;
    if (!tripId) continue;
    if (!stopTimesByTrip.has(tripId)) {
      stopTimesByTrip.set(tripId, []);
    }
    stopTimesByTrip.get(tripId).push({
      stop_id: st.stop_id || '',
      stop_sequence: parseInt(st.stop_sequence || '0', 10),
      arrival_time: st.arrival_time || '',
      departure_time: st.departure_time || '',
    });

    // Indexar stops por rota
    const trip = trips.get(tripId);
    if (trip) {
      if (!routeStopIds.has(trip.route_id)) {
        routeStopIds.set(trip.route_id, new Set());
      }
      routeStopIds.get(trip.route_id).add(st.stop_id);
    }
  }
  // Ordenar stop_times por sequência
  for (const [, sts] of stopTimesByTrip) {
    sts.sort((a, b) => a.stop_sequence - b.stop_sequence);
  }
  console.log(`[gtfs]   ${stopTimesRaw.length} stop_times carregados`);

  const duracaoMs = Date.now() - inicio;
  console.log(`[gtfs] ✅ GTFS carregado com sucesso em ${duracaoMs}ms`);
  carregado = true;
}

// ==========================================================================
// FUNÇÕES DE CONSULTA
// ==========================================================================

/**
 * Busca rotas GTFS por termo (letreiro/número ou nome da linha).
 * Retorna no máximo `limite` resultados.
 */
function buscarRotas(termo, limite = 50) {
  const termoUp = (termo || '').trim().toUpperCase();
  if (!termoUp) return [];

  const resultados = [];
  for (const [, rota] of routes) {
    const shortName = rota.route_short_name.toUpperCase();
    const longName = rota.route_long_name.toUpperCase();

    if (shortName.includes(termoUp) || longName.includes(termoUp)) {
      resultados.push(rota);
      if (resultados.length >= limite) break;
    }
  }

  // Ordena por relevância: match exato no short_name primeiro
  resultados.sort((a, b) => {
    const aExato = a.route_short_name.toUpperCase().startsWith(termoUp) ? 0 : 1;
    const bExato = b.route_short_name.toUpperCase().startsWith(termoUp) ? 0 : 1;
    if (aExato !== bExato) return aExato - bExato;
    return a.route_short_name.localeCompare(b.route_short_name);
  });

  return resultados;
}

/**
 * Converte Float32Array [lat, lon, lat, lon, ...] para array [{ py, px }, ...]
 */
function formatarShape(pontos) {
  if (!pontos || pontos.length === 0) return null;
  const result = [];
  for (let i = 0; i < pontos.length; i += 2) {
    result.push({ py: pontos[i], px: pontos[i + 1] });
  }
  return result;
}

/**
 * Obtém o shape (trajeto georreferenciado) de uma rota pelo route_id.
 * Retorna um array de { py, px } (lat/lon) pronto para consumo pelo app.
 * Tenta primeiro direction_id=0 (ida), depois direction_id=1 (volta).
 */
function obterShapeRota(routeId, directionId = null) {
  const tripsRota = routeTrips.get(routeId) || [];
  if (tripsRota.length === 0) return null;

  // Filtra pela direção desejada, ou tenta ambas
  let tripAlvo = null;
  if (directionId !== null) {
    tripAlvo = tripsRota.find(t => t.direction_id === directionId && t.shape_id);
  }
  if (!tripAlvo) {
    tripAlvo = tripsRota.find(t => t.shape_id);
  }
  if (!tripAlvo || !tripAlvo.shape_id) return null;

  const pontos = shapes.get(tripAlvo.shape_id);
  return formatarShape(pontos);
}

/**
 * Obtém ambos os shapes (ida e volta) de uma rota.
 */
function obterShapesRotaBidirecional(routeId) {
  const tripsRota = routeTrips.get(routeId) || [];
  const result = { ida: null, volta: null };

  for (const trip of tripsRota) {
    if (!trip.shape_id) continue;
    const pontos = shapes.get(trip.shape_id);
    if (!pontos || pontos.length === 0) continue;

    if (trip.direction_id === 0 && !result.ida) {
      result.ida = formatarShape(pontos);
    } else if (trip.direction_id === 1 && !result.volta) {
      result.volta = formatarShape(pontos);
    }
    if (result.ida && result.volta) break;
  }

  return result;
}

/**
 * Obtém as paradas de uma rota a partir dos stop_times GTFS.
 * Retorna no formato compatível com a API Olho Vivo: { cp, np, py, px }
 */
function obterParadasRota(routeId) {
  const tripsRota = routeTrips.get(routeId) || [];
  if (tripsRota.length === 0) return [];

  // Usa a primeira trip (direction_id=0) para obter a sequência de paradas
  let tripAlvo = tripsRota.find(t => t.direction_id === 0) || tripsRota[0];
  const stopTimes = stopTimesByTrip.get(tripAlvo.trip_id) || [];

  const paradasUnicas = new Map();
  for (const st of stopTimes) {
    if (paradasUnicas.has(st.stop_id)) continue;
    const parada = stops.get(st.stop_id);
    if (parada) {
      paradasUnicas.set(st.stop_id, {
        cp: parseInt(parada.stop_id, 10) || 0,
        np: parada.stop_name,
        ed: parada.stop_desc || '',
        py: parada.stop_lat,
        px: parada.stop_lon,
      });
    }
  }

  return Array.from(paradasUnicas.values());
}

/**
 * Obtém informações de uma rota pelo route_id.
 */
function obterRota(routeId) {
  return routes.get(routeId) || null;
}

/**
 * Tenta encontrar um route_id GTFS a partir do letreiro da API Olho Vivo.
 * O letreiro da API Olho Vivo vem como `lt` (ex: "8000") e `tl` (ex: 10),
 * resultando em "8000-10" que corresponde ao route_short_name do GTFS.
 */
function encontrarRouteIdPorLetreiro(letreiro, tl) {
  // Tenta match exato: "8000-10"
  const chaveCompleta = `${letreiro}-${tl}`.toUpperCase();
  if (shortNameIndex.has(chaveCompleta)) {
    return shortNameIndex.get(chaveCompleta);
  }

  // Tenta match com o letreiro como está (já pode conter o sufixo)
  const chaveSimples = letreiro.toUpperCase();
  if (shortNameIndex.has(chaveSimples)) {
    return shortNameIndex.get(chaveSimples);
  }

  // Busca parcial: tenta encontrar rotas que comecem com o letreiro
  for (const [shortName, routeId] of shortNameIndex) {
    if (shortName.startsWith(chaveSimples)) {
      return routeId;
    }
  }

  return null;
}

/**
 * Lista todas as rotas com paginação.
 */
function listarRotas(pagina = 1, porPagina = 50) {
  const todas = Array.from(routes.values());
  const inicio = (pagina - 1) * porPagina;
  return {
    total: todas.length,
    pagina,
    porPagina,
    rotas: todas.slice(inicio, inicio + porPagina),
  };
}

/**
 * Retorna estatísticas do carregamento GTFS.
 */
function obterEstatisticas() {
  return {
    carregado,
    totalRotas,
    totalShapes,
    totalParadas,
    totalTrips: trips.size,
    totalStopTimes: stopTimesByTrip.size,
  };
}

/**
 * Busca paradas GTFS por nome ou descrição.
 */
function buscarParadas(termo, limite = 50) {
  if (!termo) return [];
  const termoLower = termo.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');
  const resultados = [];

  for (const [, parada] of stops) {
    const nomeNorm = (parada.stop_name || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');
    const descNorm = (parada.stop_desc || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');
    const idStr = String(parada.stop_id);

    if (nomeNorm.includes(termoLower) || descNorm.includes(termoLower) || idStr === termo) {
      resultados.push({
        cp: parseInt(parada.stop_id, 10) || 0,
        np: parada.stop_name,
        ed: parada.stop_desc || '',
        py: parada.stop_lat,
        px: parada.stop_lon,
      });
      if (resultados.length >= limite) break;
    }
  }

  return resultados;
}

module.exports = {
  carregarGtfs,
  buscarRotas,
  buscarParadas,
  obterShapeRota,
  obterShapesRotaBidirecional,
  obterParadasRota,
  obterRota,
  encontrarRouteIdPorLetreiro,
  listarRotas,
  obterEstatisticas,
};

