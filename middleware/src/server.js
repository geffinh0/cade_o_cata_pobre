require('dotenv').config();
const express = require('express');
const http = require('http');
const cors = require('cors');
const { Server } = require('socket.io');
const { createClient, authenticate, reauthenticate } = require('./auth');
const { trackLine, untrackLine, startPolling, pollImmediateForLine, state } = require('./poller');
const gtfs = require('./gtfs_loader');

const PORT = process.env.PORT || 3000;
const TOKEN = process.env.SPTRANS_TOKEN;
const POLL_INTERVAL_MS = Number(process.env.POLL_INTERVAL_MS || 15000);
const INICIO_TIMESTAMP = Date.now();

const app = express();

// Middleware CORS e JSON
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

const client = createClient();

// Cache em memória (Conceito de SD: Cache no API Gateway para redução de carga externa)
const cache = new Map();
function obterCache(chave, ttlSegundos = 60) {
  const item = cache.get(chave);
  if (!item) return null;
  if (Date.now() - item.criadoEm > ttlSegundos * 1000) {
    cache.delete(chave);
    return null;
  }
  return item.valor;
}
function salvarCache(chave, valor) {
  cache.set(chave, { valor, criadoEm: Date.now() });
}

let totalRequisicoesHttp = 0;
let totalConexoesSocket = 0;
let apiAutenticada = false;

// Log de requisições e métricas
app.use((req, res, next) => {
  totalRequisicoesHttp++;
  next();
});

/**
 * Helper: executa uma chamada à API SPTrans com reautenticação automática em caso de 401.
 */
async function chamarApiComReauth(endpoint) {
  try {
    const { data } = await client.get(endpoint);
    return data;
  } catch (err) {
    if (err.response && err.response.status === 401 && TOKEN) {
      console.warn(`[server] 401 em ${endpoint}, reautenticando...`);
      const ok = await reauthenticate(client, TOKEN);
      if (ok) {
        const { data } = await client.get(endpoint);
        return data;
      }
    }
    throw err;
  }
}

// ============================================================================
// ROTAS REST (Gateway e Provedor de Dados — Modo Produção Real)
// ============================================================================

// 1. Buscar Linhas por termo (API Olho Vivo com fallback GTFS)
app.get('/linhas', async (req, res) => {
  try {
    const termo = (req.query.termo || '').trim();

    if (!termo) {
      return res.json([]);
    }

    const cacheKey = `linhas_${termo.toLowerCase()}`;
    const cached = obterCache(cacheKey, 120);
    if (cached) return res.json(cached);

    // Tenta a API Olho Vivo primeiro
    let resultado = [];
    if (apiAutenticada) {
      try {
        const data = await chamarApiComReauth(`/Linha/Buscar?termosBusca=${encodeURIComponent(termo)}`);
        resultado = Array.isArray(data) ? data : [];
      } catch (apiErr) {
        console.warn(`[server] API falhou para /linhas: ${apiErr.message}, usando GTFS como fallback`);
      }
    }

    // Fallback para GTFS se API não retornou dados
    if (resultado.length === 0) {
      const gtfsResultados = gtfs.buscarRotas(termo, 50);
      resultado = gtfsResultados.map(r => ({
        cl: 0,
        lc: false,
        lt: r.route_short_name,
        sl: 1,
        tl: 10,
        tp: r.route_long_name.split(' - ')[0] || r.route_long_name,
        ts: r.route_long_name.split(' - ')[1] || '',
        route_id: r.route_id,
        cor: r.route_color,
      }));
    }

    salvarCache(cacheKey, resultado);
    res.json(resultado);
  } catch (err) {
    console.error('[server] erro /linhas:', err.message);
    res.status(502).json({ erro: 'Falha ao consultar linhas' });
  }
});

// 2. Buscar Paradas da Linha (Itinerário de paradas - com suporte a GTFS)
app.get('/linhas/:codigoLinha/paradas', async (req, res) => {
  try {
    const codigoLinha = Number(req.params.codigoLinha);
    const routeIdParam = req.query.routeId || null;
    const letreiroParam = req.query.letreiro || null;

    const cacheKey = `paradas_linha_${codigoLinha}_${routeIdParam || ''}_${letreiroParam || ''}`;
    const cached = obterCache(cacheKey, 300);
    if (cached) return res.json(cached);

    let resultado = [];

    // Tenta API Olho Vivo se autenticada e código for válido
    if (apiAutenticada && codigoLinha > 0) {
      try {
        const data = await chamarApiComReauth(`/Parada/BuscarParadasPorLinha?codigoLinha=${codigoLinha}`);
        resultado = Array.isArray(data) ? data : [];
      } catch (apiErr) {
        console.warn(`[server] API falhou para paradas da linha ${codigoLinha}: ${apiErr.message}`);
      }
    }

    // Fallback para GTFS se API indisponível ou linha for do GTFS (cl=0)
    if (resultado.length === 0) {
      let targetRouteId = routeIdParam;
      if (!targetRouteId && letreiroParam) {
        targetRouteId = gtfs.encontrarRouteIdPorLetreiro(letreiroParam, 10);
      }
      if (!targetRouteId && codigoLinha > 0) {
        targetRouteId = gtfs.encontrarRouteIdPorLetreiro(String(codigoLinha), 10);
      }
      if (targetRouteId) {
        resultado = gtfs.obterParadasRota(targetRouteId);
      }
    }

    salvarCache(cacheKey, resultado);
    res.json(resultado);
  } catch (err) {
    console.error('[server] erro /linhas/:codigoLinha/paradas:', err.message);
    res.json([]);
  }
});

// 3. Obter Trajeto Georreferenciado da Linha (Shape GTFS real + fallback paradas API)
app.get('/linhas/:codigoLinha/trajeto', async (req, res) => {
  try {
    const codigoLinha = Number(req.params.codigoLinha);
    const routeIdParam = req.query.routeId || null;
    const letreiroParam = req.query.letreiro || null;

    const cacheKey = `trajeto_${codigoLinha}_${routeIdParam || ''}_${letreiroParam || ''}`;
    const cached = obterCache(cacheKey, 600);
    if (cached) return res.json(cached);

    let pontos = [];
    let cor = '#C00000';
    let fonteShape = 'nenhum';
    let letreiro = letreiroParam || String(codigoLinha);
    let nome = `Linha ${codigoLinha}`;

    // 1. Se temos um routeId GTFS direto, usa ele
    let targetRouteId = routeIdParam;
    if (!targetRouteId && letreiroParam) {
      targetRouteId = gtfs.encontrarRouteIdPorLetreiro(letreiroParam, 10);
    }
    if (!targetRouteId && codigoLinha > 0) {
      targetRouteId = gtfs.encontrarRouteIdPorLetreiro(String(codigoLinha), 10);
    }

    if (targetRouteId) {
      const shapeGtfs = gtfs.obterShapeRota(targetRouteId);
      if (shapeGtfs && shapeGtfs.length > 0) {
        pontos = shapeGtfs;
        fonteShape = 'gtfs';
        const rotaGtfs = gtfs.obterRota(targetRouteId);
        if (rotaGtfs) {
          cor = rotaGtfs.route_color || cor;
          letreiro = rotaGtfs.route_short_name || letreiro;
          nome = rotaGtfs.route_long_name || nome;
        }
      }
    }

    // 2. Tenta obter info da API Olho Vivo se ainda sem pontos e autenticado
    if (pontos.length === 0 && codigoLinha > 0 && apiAutenticada) {
      try {
        let infoLinha = null;
        const linhasData = await chamarApiComReauth(`/Linha/BuscarLinhaSentido?termosBusca=${codigoLinha}&sentido=1`);
        if (Array.isArray(linhasData) && linhasData.length > 0) {
          infoLinha = linhasData.find(l => l.cl === codigoLinha) || linhasData[0];
        }

        if (infoLinha) {
          letreiro = infoLinha.lt || letreiro;
          nome = `${infoLinha.tp} ➔ ${infoLinha.ts}`;
          const tl = infoLinha.tl || 10;
          const sentido = infoLinha.sl || 1;
          const routeId = gtfs.encontrarRouteIdPorLetreiro(letreiro, tl);

          if (routeId) {
            const directionId = sentido === 1 ? 0 : 1;
            const shapeGtfs = gtfs.obterShapeRota(routeId, directionId);
            if (shapeGtfs && shapeGtfs.length > 0) {
              pontos = shapeGtfs;
              fonteShape = 'gtfs';
              const rotaGtfs = gtfs.obterRota(routeId);
              if (rotaGtfs && rotaGtfs.route_color) {
                cor = rotaGtfs.route_color;
              }
            }
          }
        }
      } catch (_) {}
    }

    // 3. Fallback: constrói polyline a partir das paradas da API
    if (pontos.length === 0 && codigoLinha > 0 && apiAutenticada) {
      try {
        const paradas = await chamarApiComReauth(`/Parada/BuscarParadasPorLinha?codigoLinha=${codigoLinha}`);
        const paradasArr = Array.isArray(paradas) ? paradas : [];
        pontos = paradasArr.map(p => ({ py: p.py, px: p.px }));
        if (pontos.length > 0) fonteShape = 'paradas';
      } catch (_) {}
    }

    // 4. Fallback paradas GTFS se disponíveis
    if (pontos.length === 0 && targetRouteId) {
      const paradasGtfs = gtfs.obterParadasRota(targetRouteId);
      pontos = paradasGtfs.map(p => ({ py: p.py, px: p.px }));
      if (pontos.length > 0) fonteShape = 'gtfs_paradas';
    }

    const resultado = {
      codigoLinha,
      letreiro,
      nome,
      cor,
      pontos,
      fonteShape,
    };

    salvarCache(cacheKey, resultado);
    res.json(resultado);
  } catch (err) {
    console.error('[server] erro /linhas/:codigoLinha/trajeto:', err.message);
    res.json({
      codigoLinha: Number(req.params.codigoLinha),
      letreiro: '',
      nome: '',
      cor: '#C00000',
      pontos: [],
      fonteShape: 'nenhum',
    });
  }
});

// 4. Buscar Paradas por nome ou termo (API Olho Vivo com fallback GTFS)
app.get('/paradas', async (req, res) => {
  try {
    const termo = (req.query.termo || '').trim();

    if (!termo) {
      return res.json([]);
    }

    const cacheKey = `paradas_${termo.toLowerCase()}`;
    const cached = obterCache(cacheKey, 180);
    if (cached) return res.json(cached);

    let resultado = [];
    if (apiAutenticada) {
      try {
        const fetchPromise = chamarApiComReauth(`/Parada/Buscar?termosBusca=${encodeURIComponent(termo)}`);
        const timeoutPromise = new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), 2500));
        const data = await Promise.race([fetchPromise, timeoutPromise]);
        resultado = Array.isArray(data) ? data : [];
      } catch (apiErr) {
        console.warn(`[server] API lenta/falhou para /paradas (${apiErr.message}), usando GTFS imediato`);
      }
    }

    // Fallback rápido para GTFS se a API estiver indisponível, lenta ou sem resultados
    if (resultado.length === 0) {
      resultado = gtfs.buscarParadas(termo, 50);
    }

    salvarCache(cacheKey, resultado);
    res.json(resultado);
  } catch (err) {
    console.error('[server] erro /paradas:', err.message);
    const paradasGtfs = gtfs.buscarParadas((req.query.termo || '').trim(), 50);
    res.json(paradasGtfs);
  }
});

// 5. Previsão de chegada por Parada
app.get(['/previsao/:codigoParada', '/previsao/parada/:codigoParada'], async (req, res) => {
  try {
    const cp = req.params.codigoParada;
    const cacheKey = `previsao_parada_${cp}`;
    const cached = obterCache(cacheKey, 10);
    if (cached) return res.json(cached);

    const data = await chamarApiComReauth(`/Previsao/Parada?codigoParada=${cp}`);
    let resultado = data || { cp: Number(cp), np: '', py: 0, px: 0, l: [] };

    // Se a SPTrans aninhou a parada sob a chave 'p', expõe também no nível raiz para máxima compatibilidade
    if (data && data.p && typeof data.p === 'object') {
      resultado = {
        hr: data.hr || '',
        cp: data.p.cp || Number(cp),
        np: data.p.np || '',
        py: data.p.py || 0,
        px: data.p.px || 0,
        l: Array.isArray(data.p.l) ? data.p.l : [],
        p: data.p,
      };
    }

    salvarCache(cacheKey, resultado);
    res.json(resultado);
  } catch (err) {
    console.error('[server] erro /previsao/parada:', err.message);
    res.status(502).json({ cp: Number(req.params.codigoParada), np: '', py: 0, px: 0, l: [], erro: 'Falha ao consultar previsão da parada' });
  }
});

// 6. Previsão de chegada por Linha
app.get('/previsao/linha/:codigoLinha', async (req, res) => {
  try {
    const cl = req.params.codigoLinha;

    const data = await chamarApiComReauth(`/Previsao/Linha?codigoLinha=${cl}`);
    res.json(data || { hr: '', ps: [] });
  } catch (err) {
    console.error('[server] erro /previsao/linha:', err.message);
    res.status(502).json({ erro: 'Falha ao consultar previsão da linha' });
  }
});

// 7. Posição dos veículos de uma linha (REST — alternativa ao WebSocket)
app.get('/posicao/linha/:codigoLinha', async (req, res) => {
  try {
    const cl = req.params.codigoLinha;
    const data = await chamarApiComReauth(`/Posicao/Linha?codigoLinha=${cl}`);
    res.json(data || { hr: '', vs: [] });
  } catch (err) {
    console.error('[server] erro /posicao/linha:', err.message);
    res.status(502).json({ erro: 'Falha ao consultar posição dos veículos' });
  }
});

// ============================================================================
// ROTAS GTFS (Dados estáticos de linhas/trajetos/paradas reais da SPTrans)
// ============================================================================

// 8. Buscar rotas GTFS por termo
app.get('/gtfs/linhas', (req, res) => {
  try {
    const termo = (req.query.termo || '').trim();
    if (!termo) {
      // Sem termo: lista paginada
      const pagina = parseInt(req.query.pagina || '1', 10);
      const porPagina = parseInt(req.query.porPagina || '50', 10);
      return res.json(gtfs.listarRotas(pagina, porPagina));
    }
    const resultados = gtfs.buscarRotas(termo, 50);
    // Converte para formato compatível com a API Olho Vivo para o Flutter
    const linhasCompativeis = resultados.map(r => ({
      cl: 0, // Sem código interno da API, mas route_id serve como identificador
      lc: false,
      lt: r.route_short_name,
      sl: 1,
      tl: 10,
      tp: r.route_long_name.split(' - ')[0] || r.route_long_name,
      ts: r.route_long_name.split(' - ')[1] || '',
      route_id: r.route_id,
      cor: r.route_color,
    }));
    res.json(linhasCompativeis);
  } catch (err) {
    console.error('[server] erro /gtfs/linhas:', err.message);
    res.status(500).json({ erro: 'Falha ao consultar rotas GTFS' });
  }
});

// 9. Obter shape (trajeto real) de uma rota GTFS
app.get('/gtfs/linhas/:routeId/shape', (req, res) => {
  try {
    const routeId = req.params.routeId;
    const direction = req.query.direction !== undefined ? parseInt(req.query.direction, 10) : null;

    const cacheKey = `gtfs_shape_${routeId}_${direction}`;
    const cached = obterCache(cacheKey, 3600);
    if (cached) return res.json(cached);

    const rota = gtfs.obterRota(routeId);
    if (!rota) {
      return res.status(404).json({ erro: `Rota GTFS '${routeId}' não encontrada` });
    }

    const pontos = gtfs.obterShapeRota(routeId, direction);
    if (!pontos || pontos.length === 0) {
      return res.status(404).json({ erro: `Shape não disponível para a rota '${routeId}'` });
    }

    const resultado = {
      routeId,
      letreiro: rota.route_short_name,
      nome: rota.route_long_name,
      cor: rota.route_color,
      pontos,
      totalPontos: pontos.length,
    };

    salvarCache(cacheKey, resultado);
    res.json(resultado);
  } catch (err) {
    console.error('[server] erro /gtfs/linhas/:routeId/shape:', err.message);
    res.status(500).json({ erro: 'Falha ao obter shape GTFS' });
  }
});

// 10. Obter paradas de uma rota GTFS
app.get('/gtfs/linhas/:routeId/paradas', (req, res) => {
  try {
    const routeId = req.params.routeId;

    const cacheKey = `gtfs_paradas_${routeId}`;
    const cached = obterCache(cacheKey, 3600);
    if (cached) return res.json(cached);

    const paradas = gtfs.obterParadasRota(routeId);
    salvarCache(cacheKey, paradas);
    res.json(paradas);
  } catch (err) {
    console.error('[server] erro /gtfs/linhas/:routeId/paradas:', err.message);
    res.status(500).json({ erro: 'Falha ao obter paradas GTFS' });
  }
});

// 11. Estatísticas do GTFS carregado
app.get('/gtfs/stats', (req, res) => {
  res.json(gtfs.obterEstatisticas());
});

// 12. Status de integridade
app.get('/saude', (req, res) => res.json({
  status: 'ok',
  modoSimulado: false,
  autenticado: apiAutenticada,
  intervaloPollingMs: POLL_INTERVAL_MS,
  gtfs: gtfs.obterEstatisticas(),
  timestamp: new Date().toISOString()
}));

// 9. Métricas detalhadas de Sistemas Distribuídos
app.get('/metricas', (req, res) => {
  const uptimeSegundos = Math.floor((Date.now() - INICIO_TIMESTAMP) / 1000);
  res.json({
    status: 'ok',
    modoSimulado: false,
    autenticado: true,
    tempoAtividadeSegundos: uptimeSegundos,
    totalConexoesSocket,
    clientesConectadosAgora: io.engine.clientsCount,
    linhasAcompanhadasAgora: state.linhasAcompanhadas.size,
    listaLinhasAssinadas: Array.from(state.linhasAcompanhadas.keys()),
    totalRequisicoesHttp,
    totalPollsRealizados: state.totalPolls,
    totalPushesEmitidos: state.totalPushes,
    totalItensEmCache: cache.size,
    intervaloPollingMs: POLL_INTERVAL_MS,
    totalErrosPoller: state.errosCount,
    totalReautenticacoes: state.reautenticacoesRealizadas,
    dataHoraServidor: new Date().toISOString()
  });
});

// ============================================================================
// CANAL TEMPO REAL: WebSocket (Socket.IO Pub/Sub)
// ============================================================================

io.on('connection', (socket) => {
  totalConexoesSocket++;
  console.log(`[middleware] Cliente conectado: ${socket.id} (Total ativos: ${io.engine.clientsCount})`);
  let linhaAssinada = null;

  // Medição de latência RTT (Ping/Pong)
  socket.on('ping_check', (timestampCliente) => {
    socket.emit('pong_check', {
      timestampCliente,
      timestampServidor: Date.now()
    });
  });

  socket.on('assinar_linha', async (codigoLinha) => {
    const codStr = String(codigoLinha);
    if (linhaAssinada) {
      socket.leave(`linha:${linhaAssinada}`);
      untrackLine(linhaAssinada);
    }
    linhaAssinada = codStr;
    socket.join(`linha:${codStr}`);
    trackLine(codStr);
    console.log(`[middleware] Cliente ${socket.id} assinou linha ${codStr}`);

    // Emissão inicial imediata com dados reais da API
    await pollImmediateForLine(client, io, codStr, TOKEN);
  });

  socket.on('cancelar_linha', (codigoLinha) => {
    const codStr = String(codigoLinha);
    socket.leave(`linha:${codStr}`);
    untrackLine(codStr);
    if (linhaAssinada === codStr) linhaAssinada = null;
    console.log(`[middleware] Cliente ${socket.id} cancelou linha ${codStr}`);
  });

  socket.on('disconnect', () => {
    if (linhaAssinada) untrackLine(linhaAssinada);
    console.log(`[middleware] Cliente desconectado: ${socket.id} (Restantes: ${io.engine.clientsCount})`);
  });
});

// Inicialização

// Serve o frontend Flutter Web compilado diretamente do Gateway Express
const path = require('path');
const fs = require('fs');
const caminhosPossiveis = [
  path.join(__dirname, '../../app_transporte/build/web'),
  path.join(__dirname, '../public'),
  path.join(__dirname, '../../public'),
  path.join(process.cwd(), 'public'),
];
const flutterWebPath = caminhosPossiveis.find(p => fs.existsSync(p));
if (flutterWebPath) {
  app.use(express.static(flutterWebPath));
  app.get('*', (req, res, next) => {
    if (req.path.startsWith('/linhas') || req.path.startsWith('/paradas') ||
        req.path.startsWith('/gtfs') || req.path.startsWith('/previsao') ||
        req.path.startsWith('/posicao') || req.path.startsWith('/saude') ||
        req.path.startsWith('/metricas') || req.path.startsWith('/socket.io')) {
      return next();
    }
    res.sendFile(path.join(flutterWebPath, 'index.html'));
  });
  console.log(`[middleware] 🌐 Frontend Flutter Web montado em http://localhost:${PORT}`);
}

// Inicia o servidor HTTP imediatamente para o Render detectar a porta aberta sem atraso
server.listen(PORT, () => {
  console.log(`\n======================================================`);
  console.log(`🚀 [middleware] Rodando em http://localhost:${PORT}`);
  console.log(`   Saúde da API:  http://localhost:${PORT}/saude`);
  console.log(`   Métricas SD:   http://localhost:${PORT}/metricas`);
  console.log(`   GTFS Stats:    http://localhost:${PORT}/gtfs/stats`);
  console.log(`   Carregando serviços em segundo plano...`);
  console.log(`======================================================\n`);
});

(async () => {
  try {
    // 1. Carrega dados GTFS em segundo plano (otimizado com streaming para 38MB RAM)
    try {
      await gtfs.carregarGtfs();
      const stats = gtfs.obterEstatisticas();
      console.log(`[middleware] ✅ GTFS pronto: ${stats.totalRotas} rotas | ${stats.totalShapes} shapes | ${stats.totalParadas} paradas`);
    } catch (gtfsErr) {
      console.warn(`[middleware] Aviso: falha ao carregar GTFS: ${gtfsErr.message}`);
      console.warn('[middleware] O servidor continuará sem dados GTFS (trajetos simplificados).');
    }

    // 2. Tenta autenticar na API Olho Vivo (não-fatal: servidor funciona em modo degradado)
    if (!TOKEN || TOKEN === 'coloque_aqui_seu_token' || TOKEN === 'seu_token_aqui') {
      console.warn('\n======================================================');
      console.warn('⚠️  [middleware] SPTRANS_TOKEN não configurado!');
      console.warn('   O servidor funcionará em modo GTFS-only (sem tempo real).');
      console.warn('   Edite o arquivo middleware/.env e insira seu token.');
      console.warn('   Obtenha em: https://www.sptrans.com.br/desenvolvedores/');
      console.warn('======================================================\n');
    } else {
      try {
        await authenticate(client, TOKEN);
        apiAutenticada = true;
        console.log('[middleware] ✅ Autenticado na API Olho Vivo com sucesso');

        // Inicia polling real com a API SPTrans Olho Vivo
        startPolling(client, io, POLL_INTERVAL_MS, TOKEN);

        // Reautenticação preventiva a cada 10 minutos para manter a sessão viva
        setInterval(async () => {
          try {
            await authenticate(client, TOKEN, 1);
            apiAutenticada = true;
            console.log('[middleware] Reautenticação preventiva realizada com sucesso');
          } catch (err) {
            apiAutenticada = false;
            console.warn(`[middleware] Falha na reautenticação preventiva: ${err.message}`);
          }
        }, 10 * 60 * 1000);
      } catch (authErr) {
        console.warn(`\n======================================================`);
        console.warn(`⚠️  [middleware] Falha na autenticação da API Olho Vivo: ${authErr.message}`);
        console.warn(`   O servidor funcionará em MODO DEGRADADO:`);
        console.warn(`   ✅ Endpoints GTFS (linhas, shapes, paradas): DISPONÍVEIS`);
        console.warn(`   ❌ Endpoints tempo real (posição, previsão): INDISPONÍVEIS`);
        console.warn(`   Verifique se o token no .env é válido.`);
        console.warn(`======================================================\n`);

        // Tenta reautenticar a cada 2 minutos
        setInterval(async () => {
          if (apiAutenticada) return;
          try {
            await authenticate(client, TOKEN, 1);
            apiAutenticada = true;
            console.log('[middleware] ✅ Reautenticação bem-sucedida! Modo produção ativado.');
            startPolling(client, io, POLL_INTERVAL_MS, TOKEN);
          } catch (err) {
            console.warn(`[middleware] Tentativa de reautenticação falhou: ${err.message}`);
          }
        }, 2 * 60 * 1000);
      }
    }
  } catch (err) {
    console.error('[middleware] Erro fatal ao iniciar:', err.message);
    process.exit(1);
  }
})();
