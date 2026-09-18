# ==============================================================================
# ESTÁGIO 1: Build do Flutter Web
# ==============================================================================
FROM ghcr.io/cirruslabs/flutter:stable AS flutter_builder
WORKDIR /app/app_transporte

# Baixar dependências do Flutter
COPY app_transporte/pubspec.yaml app_transporte/pubspec.lock ./
RUN flutter pub get

# Copiar código fonte do Flutter e compilar para web release
COPY app_transporte/ .
RUN flutter build web --release

# ==============================================================================
# ESTÁGIO 2: Servidor Node.js (Express + Socket.IO + Gateway)
# ==============================================================================
FROM node:18-alpine
WORKDIR /app

# Instalar dependências do Node.js
COPY middleware/package*.json ./
RUN npm install --omit=dev

# Copiar código do middleware e dados GTFS
COPY middleware/ .

# Copiar o Flutter Web compilado para o diretório public
COPY --from=flutter_builder /app/app_transporte/build/web ./public

# Configurações de execução
ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

CMD ["node", "src/server.js"]
