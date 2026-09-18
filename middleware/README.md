# Middleware - APS Sistemas Distribuidos

Middleware que autentica na API Olho Vivo (SPTrans), faz polling periodico das
linhas acompanhadas e republica as posicoes em tempo real para os apps
conectados via Socket.IO. Tambem expoe endpoints REST simples para buscas
pontuais (linhas, paradas, previsao).

## Como rodar

1. Instale as dependencias:
   ```
   npm install
   ```
2. Copie `.env.example` para `.env` e cole o token obtido em
   https://www.sptrans.com.br/desenvolvedores/ (area "Meus Aplicativos"):
   ```
   cp .env.example .env
   ```
3. Inicie o servidor:
   ```
   npm start
   ```
4. Teste se subiu: `http://localhost:3000/saude` deve responder `{"status":"ok"}`.

## Endpoints REST

- `GET /linhas?termo=8000` - busca linhas por numero/nome
- `GET /paradas?termo=lapa` - busca paradas por nome/endereco
- `GET /previsao/:codigoParada` - previsao de chegada numa parada

## Eventos Socket.IO

- Cliente emite `assinar_linha` com o `codigoLinha` (campo `cl` retornado por
  `/linhas`) para comecar a receber posicoes daquela linha.
- Servidor emite `posicoes` com `{ codigoLinha, dados, timestamp }` a cada
  ciclo de polling (`POLL_INTERVAL_MS`, padrao 15s).
- Cliente emite `cancelar_linha` para parar de receber atualizacoes.

## Pontos para o grupo evoluir (contam pra nota)

- Cache mais robusto (evitar repolling se ninguem estiver inscrito ha muito
  tempo, ja parcialmente tratado pelo contador de assinantes em `poller.js`).
- Tratamento de reautenticacao automatica se a sessao expirar.
- Logs estruturados e testes automatizados.
- Persistir historico de posicoes (ex.: para estatisticas de atraso).
