const axios = require('axios');
const { wrapper } = require('axios-cookiejar-support');
const { CookieJar } = require('tough-cookie');

const BASE_URL = 'https://api.olhovivo.sptrans.com.br/v2.1';

// Cria um client axios com suporte a cookies de sessao, necessario porque a
// API Olho Vivo autentica via POST e depois mantem a sessao usando cookie.
function createClient() {
  const jar = new CookieJar();
  const client = wrapper(axios.create({
    baseURL: BASE_URL,
    jar,
    withCredentials: true,
    timeout: 15000,
  }));
  return client;
}

/**
 * Autentica na API Olho Vivo com retry e backoff exponencial.
 * A sessão é mantida via cookies pelo axios-cookiejar-support.
 * 
 * @param {import('axios').AxiosInstance} client - Cliente axios com cookie jar
 * @param {string} token - Token de acesso da API Olho Vivo
 * @param {number} maxRetries - Número máximo de tentativas (default: 3)
 * @returns {Promise<boolean>} true se autenticado com sucesso
 */
async function authenticate(client, token, maxRetries = 3) {
  if (!token) {
    throw new Error('SPTRANS_TOKEN não configurado no .env - obtenha em https://www.sptrans.com.br/desenvolvedores/');
  }

  let lastError = null;
  for (let tentativa = 1; tentativa <= maxRetries; tentativa++) {
    try {
      const response = await client.post(`/Login/Autenticar?token=${token}`);
      if (response.data === true) {
        console.log(`[auth] Autenticado com sucesso na API Olho Vivo (tentativa ${tentativa}/${maxRetries})`);
        return true;
      }
      throw new Error('API retornou false - token pode estar inválido ou expirado');
    } catch (err) {
      lastError = err;
      const isLastAttempt = tentativa === maxRetries;
      if (isLastAttempt) break;

      const delayMs = Math.min(1000 * Math.pow(2, tentativa - 1), 10000);
      console.warn(`[auth] Tentativa ${tentativa}/${maxRetries} falhou: ${err.message}. Retentando em ${delayMs}ms...`);
      await new Promise(resolve => setTimeout(resolve, delayMs));
    }
  }

  throw new Error(`Falha ao autenticar após ${maxRetries} tentativas: ${lastError?.message || 'erro desconhecido'}`);
}

/**
 * Reautentica silenciosamente. Usado pelo poller quando detecta sessão expirada (401).
 * Retorna true se conseguiu reautenticar, false caso contrário.
 */
async function reauthenticate(client, token) {
  try {
    console.log('[auth] Sessão expirada detectada, reautenticando...');
    await authenticate(client, token, 2);
    console.log('[auth] Reautenticação bem-sucedida');
    return true;
  } catch (err) {
    console.error(`[auth] Falha na reautenticação: ${err.message}`);
    return false;
  }
}

module.exports = { createClient, authenticate, reauthenticate, BASE_URL };
