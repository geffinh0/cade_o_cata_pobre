# Guia de Execução e Apresentação — App SPTrans em Flutter (Sistemas Distribuídos)

Este documento orienta o grupo sobre a estrutura do aplicativo Flutter, como executá-lo e como apresentar os conceitos de **Sistemas Distribuídos** no relatório e na banca.

---

## 1. Arquitetura da Solução

O projeto segue a arquitetura distribuída em camadas exigida pelo trabalho:

1. **Camada de Provedor Externo**: API Olho Vivo SPTrans (REST).
2. **Camada de Middleware (Node.js)**: 
   - Autentica e centraliza as consultas externas com controle de taxa.
   - Fornece endpoints REST para buscas e detalhes.
   - Fornece canal de tempo real com **WebSocket (Socket.IO)** sob o modelo **Publish/Subscribe**.
   - Possui **Modo Simulação** automático (caso o token da SPTrans não esteja configurado no `.env`), emitindo frotas com telemetria realista em São Paulo.
3. **Camada de Cliente Móvel (Flutter)**:
   - **`models/`**: Representação de domínio (`Linha`, `Parada`, `Veiculo`, `Previsao`).
   - **`services/`**: `ApiService` (REST) e `RealtimeService` (WebSocket Socket.IO).
   - **`data/`**: `FavoritosDao` (persistência local).
   - **`providers/`**: `TransporteProvider` (gerenciamento de estado reativo).
   - **`screens/`**: `HomeScreen` (Interface com busca, mapa interativo `flutter_map` OpenStreetMap e favoritos).

---

## 2. Como Rodar o Projeto

### A. Iniciar o Middleware
No terminal, dentro da pasta `middleware/`:
```bash
npm install
npm start
```
O servidor estará ativo em `http://localhost:3000`.

### B. Rodar o App Flutter
No terminal, dentro da pasta `app_transporte/`:

- **Para testar no Navegador Chrome (Web):**
  ```bash
  flutter run -d chrome
  ```
- **Para testar no Emulador Android:**
  ```bash
  flutter run
  ```
- **Para instalar o APK gerado no Celular Android físico:**
  O arquivo APK pronto para instalação encontra-se em:
  `app_transporte/build/app/outputs/flutter-apk/app-debug.apk`

---

## 3. Fundamentação Teórica para o "Relatório com Linhas de Código"

Abaixo está o mapeamento dos conceitos de **Sistemas Distribuídos** implementados no código:

| Conceito de SD | Arquivo / Classe | Linhas | Explicação para o Relatório |
| :--- | :--- | :--- | :--- |
| **Arquitetura em Camadas e Desacoplamento** | `main.dart` e `services/api_service.dart` | Injeção em `main()` e requisições HTTP em `ApiService` | O dispositivo móvel não conversa diretamente com a SPTrans. O Middleware atua como proxy inteligente, gerenciando credenciais e cache. |
| **Paradigma Publish/Subscribe (Event-Driven)** | `services/realtime_service.dart` | `assinarLinha()`, `desassinarLinha()`, `socket.on('posicoes')` | Em vez de fazer polling contínuo (requisições repetidas que gastam bateria e banda), o app assina a linha desejada e o servidor faz *Push* das posições. |
| **Transparência de Acesso** | `services/api_service.dart` | Métodos `buscarLinhas()`, `buscarPosicaoLinha()` | A interface gráfica recebe objetos tipados (`Linha`, `Veiculo`) de forma transparente, sem precisar manipular conexões de rede ou decodificação manual de JSON. |
| **Tolerância a Falhas e Resiliência** | `services/realtime_service.dart` | Opções de reconexão (`enableReconnection()`, `reconnectionAttempts`) | Se a conexão de rede móvel oscilar ou cair momentaneamente, o cliente tenta reconectar sozinho sem travar o aplicativo. |
| **Persistência Local (Desconexão)** | `data/favoritos_dao.dart` | `salvarFavorito()`, `listarFavoritos()` | Permite que preferências e rotas favoritas fiquem salvas no dispositivo mesmo quando offline. |
| **Estado Reativo e Propagação de Eventos** | `providers/transporte_provider.dart` | `notifyListeners()`, `acompanharLinha()` | Implementa o padrão Observer: dados que chegam pelo socket notificam o estado e atualizam os marcadores no mapa instantaneamente. |
