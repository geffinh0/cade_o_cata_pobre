# App Android - APS Sistemas Distribuidos

Cliente Kotlin que consome o middleware (nao a API Olho Vivo diretamente):
busca linhas/paradas via REST e recebe posicoes dos onibus em tempo real via
Socket.IO. Favoritos ficam salvos localmente com Room.

## Como montar o projeto no Android Studio

1. Crie um projeto novo: **Empty Activity**, linguagem **Kotlin**, template
   com **Jetpack Compose**, minSdk 24+.
2. Nomeie o pacote como `com.example.apstransporte` (ou ajuste os `package`
   no topo de cada arquivo `.kt` se usar outro nome).
3. Copie o conteudo de `app/src/main/java/com/example/apstransporte/` deste
   pacote para o mesmo caminho no seu projeto.
4. Abra `app/build.gradle.kts` do seu projeto e:
   - adicione `id("kotlin-kapt")` no bloco `plugins {}`
   - cole as dependencias de `app-build.gradle.kts.snippet` no bloco
     `dependencies {}`
5. Adicione ao `AndroidManifest.xml` o conteudo de
   `AndroidManifest.xml.snippet`.
6. Ajuste `BASE_URL` em `RetrofitClient.kt` e `serverUrl` em
   `RealtimeClient.kt`:
   - Emulador Android: `10.0.2.2` (ja configurado, aponta pro localhost da
     maquina host)
   - Celular fisico na mesma rede: use o IP local da maquina rodando o
     middleware (ex: `192.168.0.10`)
7. Rode o middleware (`../middleware`) antes de testar o app.
8. Rode o app no emulador ou dispositivo fisico.

## Estrutura

```
data/model/     -> classes de dados (Linha, Parada, Veiculo, Previsao)
data/remote/    -> Retrofit (REST) e Socket.IO (tempo real)
data/local/     -> Room (favoritos)
repository/     -> ponto unico que a UI usa, esconde a origem dos dados
ui/             -> ViewModel + tela em Compose
```

## Pontos para o grupo evoluir

- Persistir e listar os favoritos na tela (a estrutura em `FavoritoDao` ja
  esta pronta, falta ligar na UI).
- Notificacao quando o onibus favorito estiver a X minutos da parada.
- Mostrar as posicoes num mapa (Google Maps SDK ou OSMDroid) em vez de lista.
- Tratamento de erro na UI quando o middleware ou a API Olho Vivo cair.
- Modo offline com a ultima posicao conhecida em cache.
