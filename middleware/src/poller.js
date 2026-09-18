// Controla quais linhas tem pelo menos um cliente inscrito e faz o polling
// periodico na API Olho Vivo, republicando os dados via Socket.IO.
// Isso e o que caracteriza o middleware como parte de um sistema distribuido:
// uma unica chamada externa abastece N clientes conectados.

const { reauthenticate } = require('./auth');

const state = {
  linhasAcompanhadas: new Map(), // codigoLinha -> numero de assinantes
  totalPolls: 0,
  totalPushes: 0,
  errosCount: 0,
  ultimaExecucao: null,
  reautenticacoesRealizadas: 0,
};

function trackLine(codigoLinha) {
  const codStr = String(codigoLinha);
  const atual = state.linhasAcompanhadas.get(codStr) || 0;
  state.linhasAcompanhadas.set(codStr, atual + 1);
}

function untrackLine(codigoLinha) {
  const codStr = String(codigoLinha);
  const atual = state.linhasAcompanhadas.get(codStr) || 0;
  if (atual <= 1) {
    state.linhasAcompanhadas.delete(codStr);
  } else {
    state.linhasAcompanhadas.set(codStr, atual - 1);
  }
}

/**
 * Busca a posição dos veículos de uma linha específica na API real.
 * Normaliza o payload para o formato que o Flutter espera:
 * { codigoLinha, dados: { hr, vs }, timestamp }
 * 
 * A API SPTrans /Posicao/Linha retorna: { hr: "19:57", vs: [...] }
 */
async function fetchLinePosition(client, codigoLinha, token) {
  if (!codigoLinha || String(codigoLinha) === '0' || Number(codigoLinha) <= 0) {
    return {
      codigoLinha: String(codigoLinha),
      dados: { hr: '', vs: [] },
      timestamp: Date.now(),
    };
  }

  try {
    const { data } = await client.get(`/Posicao/Linha?codigoLinha=${codigoLinha}`);

    // Normaliza: a API pode retornar null/undefined se não há veículos ativos
    const hr = data?.hr || new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
    const vs = data?.vs || [];

    return {
      codigoLinha: String(codigoLinha),
      dados: { hr, vs },
      timestamp: Date.now(),
    };
  } catch (err) {
    // Detecta sessão expirada (401) e tenta reautenticar
    if (err.response && err.response.status === 401 && token) {
      const reautenticado = await reauthenticate(client, token);
      if (reautenticado) {
        state.reautenticacoesRealizadas++;
        // Tenta novamente após reautenticação
        const { data } = await client.get(`/Posicao/Linha?codigoLinha=${codigoLinha}`);
        const hr = data?.hr || new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
        const vs = data?.vs || [];
        return {
          codigoLinha: String(codigoLinha),
          dados: { hr, vs },
          timestamp: Date.now(),
        };
      }
    }
    throw err;
  }
}

/**
 * Faz o poll de uma linha específica imediatamente e emite o resultado.
 * Usado quando um cliente assina uma linha pela primeira vez para resposta imediata.
 */
async function pollImmediateForLine(client, io, codigoLinha, token) {
  try {
    const resultado = await fetchLinePosition(client, codigoLinha, token);
    state.totalPushes++;
    io.to(`linha:${codigoLinha}`).emit('posicoes', resultado);
    return resultado;
  } catch (err) {
    state.errosCount++;
    console.warn(`[poller] API indisponível para linha ${codigoLinha}: ${err.message}`);
    const vazio = {
      codigoLinha: String(codigoLinha),
      dados: { hr: '', vs: [] },
      timestamp: Date.now(),
    };
    io.to(`linha:${codigoLinha}`).emit('posicoes', vazio);
    return vazio;
  }
}

/**
 * Executa um ciclo de polling para todas as linhas assinadas.
 */
async function pollOnce(client, io, token) {
  state.totalPolls++;
  state.ultimaExecucao = new Date().toISOString();

  for (const codigoLinha of state.linhasAcompanhadas.keys()) {
    try {
      const resultado = await fetchLinePosition(client, codigoLinha, token);
      state.totalPushes++;
      io.to(`linha:${codigoLinha}`).emit('posicoes', resultado);
    } catch (err) {
      state.errosCount++;
      console.error(`[poller] erro ao buscar posição da linha ${codigoLinha}:`, err.message);
      io.to(`linha:${codigoLinha}`).emit('erro', {
        codigoLinha,
        mensagem: 'Falha temporária ao consultar a API Olho Vivo',
      });
    }
  }
}

/**
 * Inicia o loop de polling periódico com o intervalo especificado.
 */
function startPolling(client, io, intervalMs, token) {
  // Poll imediato na inicialização
  pollOnce(client, io, token);
  
  setInterval(() => pollOnce(client, io, token), intervalMs);
  console.log(`[poller] iniciado em MODO PRODUÇÃO, intervalo de ${intervalMs}ms`);
}

module.exports = { trackLine, untrackLine, startPolling, pollImmediateForLine, state };
