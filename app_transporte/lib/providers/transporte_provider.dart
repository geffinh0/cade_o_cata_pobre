import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../data/favoritos_dao.dart';
import '../models/linha.dart';
import '../models/metrica_sistema.dart';
import '../models/parada.dart';
import '../models/previsao.dart';
import '../models/trajeto.dart';
import '../models/veiculo.dart';
import '../services/api_service.dart';
import '../services/realtime_service.dart';

/// Gerenciador de Estado Reativo Global da Aplicação
///
/// [Conceito de SD: Desacoplamento e Padrão Observer]
/// A UI reage às mutações de estado publicadas por este provider sem se preocupar
/// com os detalhes de protocolos HTTP/REST ou WebSockets.
class TransporteProvider extends ChangeNotifier {
  final ApiService _apiService;
  final RealtimeService _realtimeService;
  final FavoritosDao _favoritosDao;

  StreamSubscription<PosicaoEvento>? _posicoesSub;
  StreamSubscription<bool>? _conexaoSub;
  StreamSubscription<int>? _latenciaSub;
  Timer? _metricasTimer;

  // Estado - Linhas e Itinerário
  List<Linha> _linhasEncontradas = [];
  Linha? _linhaAcompanhada;
  TrajetoLinha? _trajetoLinhaAcompanhada;
  List<Parada> _paradasLinhaAcompanhada = [];

  // Estado - Tempo Real
  List<Veiculo> _veiculosEmTempoReal = [];
  Veiculo? _veiculoSelecionado;
  bool _modoSeguirVeiculo = false;
  DateTime? _ultimaAtualizacao;

  // Estado - Localização do Usuário (GPS)
  LatLng? _localizacaoUsuario;
  double? _rumoUsuario; // Direção / Bússola em graus (0..360)
  bool _obtendoLocalizacao = false;
  String? _erroLocalizacao;
  StreamSubscription<Position>? _posicaoUsuarioSub;

  // Estado - Paradas e Previsões
  List<Parada> _paradasEncontradas = [];
  Parada? _paradaSelecionada;
  Previsao? _previsaoParadaSelecionada;
  bool _carregandoPrevisao = false;

  // Estado - Favoritos e Histórico
  List<Map<String, String>> _favoritosLinhas = [];
  List<Map<String, dynamic>> _favoritosParadas = [];
  List<String> _historicoBuscas = [];

  // Estado - Conexão e Métricas Distribuídas
  bool _carregando = false;
  String? _mensagemErro;
  bool _conectadoSocket = false;
  int _latenciaMs = 0;
  MetricaSistema? _metricasServidor;
  String _baseUrlConfigurada;

  // Estado - Interface e Preferências
  ThemeMode _temaModo = ThemeMode.dark;
  String _estiloMapa = 'padrao'; // 'padrao' (OpenStreetMap) ou 'satelite' (ESRI Satélite)
  int _indiceAba = 0;

  TransporteProvider({
    required ApiService apiService,
    required RealtimeService realtimeService,
    required FavoritosDao favoritosDao,
  })  : _apiService = apiService,
        _realtimeService = realtimeService,
        _favoritosDao = favoritosDao,
        _baseUrlConfigurada = apiService.baseUrl {
    _inicializar();
  }

  // Getters Linhas & Tempo Real
  List<Linha> get linhas => _linhasEncontradas;
  Linha? get linhaAcompanhada => _linhaAcompanhada;
  TrajetoLinha? get trajetoLinhaAcompanhada => _trajetoLinhaAcompanhada;
  List<Parada> get paradasLinhaAcompanhada => _paradasLinhaAcompanhada;
  List<Veiculo> get veiculos => _veiculosEmTempoReal;
  Veiculo? get veiculoSelecionado => _veiculoSelecionado;
  bool get modoSeguirVeiculo => _modoSeguirVeiculo;
  DateTime? get ultimaAtualizacao => _ultimaAtualizacao;

  // Getters Paradas & Previsão
  List<Parada> get paradas => _paradasEncontradas;
  Parada? get paradaSelecionada => _paradaSelecionada;
  Previsao? get previsaoParada => _previsaoParadaSelecionada;
  bool get carregandoPrevisao => _carregandoPrevisao;

  // Getters Favoritos & Histórico
  List<Map<String, String>> get favoritos => _favoritosLinhas;
  List<Map<String, dynamic>> get paradasFavoritas => _favoritosParadas;
  List<String> get historicoBuscas => _historicoBuscas;

  // Getters Conexão & SD
  bool get carregando => _carregando;
  String? get erro => _mensagemErro;
  bool get conectado => _conectadoSocket;
  int get latenciaMs => _latenciaMs;
  int get totalEventosRecebidos => _realtimeService.totalEventosRecebidos;
  MetricaSistema? get metricas => _metricasServidor;
  String get baseUrl => _baseUrlConfigurada;

  // Getters UI
  ThemeMode get tema => _temaModo;
  String get estiloMapa => _estiloMapa;
  int get indiceAba => _indiceAba;

  // Getters Localização
  LatLng? get localizacaoUsuario => _localizacaoUsuario;
  double? get rumoUsuario => _rumoUsuario;
  bool get obtendoLocalizacao => _obtendoLocalizacao;
  String? get erroLocalizacao => _erroLocalizacao;

  Future<void> _inicializar() async {
    // 1. Carrega preferências salvas
    await _carregarPreferencias();

    // 2. Obtém localização atual do usuário (não bloqueante)
    obterLocalizacaoAtual();

    // 3. Conecta o WebSocket
    _realtimeService.conectar(_baseUrlConfigurada);

    _conexaoSub = _realtimeService.statusConexaoStream.listen((status) {
      _conectadoSocket = status;
      notifyListeners();
    });

    _latenciaSub = _realtimeService.latenciaStream.listen((lat) {
      _latenciaMs = lat;
      notifyListeners();
    });

    _posicoesSub = _realtimeService.posicoesStream.listen((evento) {
      if (_linhaAcompanhada != null &&
          evento.codigoLinha == _linhaAcompanhada!.cl.toString()) {
        _veiculosEmTempoReal = evento.dados.vs;
        _ultimaAtualizacao = DateTime.now();

        // Se o modo seguir veículo estiver ativo, atualiza a referência do veículo selecionado
        if (_veiculoSelecionado != null) {
          final atualizado = _veiculosEmTempoReal.cast<Veiculo?>().firstWhere(
                (v) => v?.p == _veiculoSelecionado!.p,
                orElse: () => null,
              );
          if (atualizado != null) {
            _veiculoSelecionado = atualizado;
          }
        }

        notifyListeners();
      }
    });

    // 3. Carrega favoritos locais e histórico
    await carregarFavoritos();
    await carregarHistorico();

    // 4. Inicia polling de métricas do sistema distribuído a cada 10s
    atualizarMetricas();
    _metricasTimer = Timer.periodic(const Duration(seconds: 10), (_) => atualizarMetricas());

    // 5. Verifica conectividade com o middleware (sem busca demonstrativa)
    _verificarConectividade();
  }

  Future<void> _verificarConectividade() async {
    try {
      final saude = await _apiService.checarSaude();
      if (saude['status'] == 'ok') {
        _mensagemErro = null;
      } else if (saude['status'] == 'indisponivel') {
        _mensagemErro = 'Middleware indisponível em $_baseUrlConfigurada. Verifique se o servidor está rodando.';
      }
    } catch (_) {
      _mensagemErro = 'Não foi possível conectar ao middleware em $_baseUrlConfigurada';
    }
    notifyListeners();
  }

  Future<void> _carregarPreferencias() async {
    final temaStr = await _favoritosDao.obterTema();
    if (temaStr == 'light') {
      _temaModo = ThemeMode.light;
    } else if (temaStr == 'dark') {
      _temaModo = ThemeMode.dark;
    } else {
      _temaModo = ThemeMode.system;
    }

    final estiloSalvo = await _favoritosDao.obterEstiloMapa();
    _estiloMapa = (estiloSalvo == 'satelite') ? 'satelite' : 'padrao';
    final urlSalva = await _favoritosDao.obterServidorUrl();
    if (urlSalva != null && urlSalva.trim().isNotEmpty) {
      _baseUrlConfigurada = urlSalva.trim();
      _apiService.atualizarBaseUrl(_baseUrlConfigurada);
    }
  }

  void mudarAba(int index) {
    _indiceAba = index.clamp(0, 3);
    notifyListeners();
  }

  void alternarTema(ThemeMode novoTema) {
    _temaModo = novoTema;
    String str = 'dark';
    if (novoTema == ThemeMode.light) str = 'light';
    if (novoTema == ThemeMode.system) str = 'system';
    _favoritosDao.salvarTema(str);
    notifyListeners();
  }

  void alternarTipoMapa() {
    _estiloMapa = (_estiloMapa == 'satelite') ? 'padrao' : 'satelite';
    _favoritosDao.salvarEstiloMapa(_estiloMapa);
    notifyListeners();
  }

  void alternarEstiloMapa(String estilo) {
    _estiloMapa = (estilo == 'satelite') ? 'satelite' : 'padrao';
    _favoritosDao.salvarEstiloMapa(_estiloMapa);
    notifyListeners();
  }

  void atualizarServidor(String novaUrl) {
    if (novaUrl.trim().isEmpty) return;
    _baseUrlConfigurada = novaUrl.trim();
    _favoritosDao.salvarServidorUrl(_baseUrlConfigurada);
    _apiService.atualizarBaseUrl(_baseUrlConfigurada);
    _realtimeService.conectar(_baseUrlConfigurada);
    atualizarMetricas();
    notifyListeners();
  }

  Future<void> atualizarMetricas() async {
    try {
      _metricasServidor = await _apiService.obterMetricas();
      notifyListeners();
    } catch (_) {}
  }

  // ==========================================================================
  // LOCALIZAÇÃO DO USUÁRIO (GPS)
  // ==========================================================================

  Future<LatLng?> obterLocalizacaoAtual() async {
    _obtendoLocalizacao = true;
    _erroLocalizacao = null;

    try {
      // 1. Resposta Instantânea (0ms): tenta pegar a última posição conhecida do dispositivo
      try {
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) {
          _localizacaoUsuario = LatLng(lastPos.latitude, lastPos.longitude);
          if (lastPos.heading != 0) _rumoUsuario = lastPos.heading;
          notifyListeners();
        }
      } catch (_) {}

      // 2. Valida permissões de localização
      if (!kIsWeb) {
        bool servicoAtivo = await Geolocator.isLocationServiceEnabled();
        if (!servicoAtivo) {
          _erroLocalizacao = 'Serviço de localização desativado';
          _obtendoLocalizacao = false;
          notifyListeners();
          return _localizacaoUsuario;
        }
      }

      LocationPermission permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
        if (permissao == LocationPermission.denied) {
          _erroLocalizacao = 'Permissão de localização negada';
          _obtendoLocalizacao = false;
          notifyListeners();
          return _localizacaoUsuario;
        }
      }

      if (permissao == LocationPermission.deniedForever) {
        _erroLocalizacao = 'Permissão de localização negada permanentemente';
        _obtendoLocalizacao = false;
        notifyListeners();
        return _localizacaoUsuario;
      }

      // 3. Localização ágil (precisão balanceada com timeout de 3.5s para não travar a UI)
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(milliseconds: 3500),
        ),
      );

      _localizacaoUsuario = LatLng(pos.latitude, pos.longitude);
      if (pos.heading != 0) _rumoUsuario = pos.heading;
      _obtendoLocalizacao = false;
      notifyListeners();

      _iniciarStreamLocalizacao();
      return _localizacaoUsuario;
    } catch (e) {
      // Se deu timeout mas já temos a última conhecida, mantém ela
      if (_localizacaoUsuario != null) {
        _obtendoLocalizacao = false;
        notifyListeners();
        _iniciarStreamLocalizacao();
        return _localizacaoUsuario;
      }
      _erroLocalizacao = 'Erro ao obter localização: $e';
      _obtendoLocalizacao = false;
      notifyListeners();
      return null;
    }
  }

  void _iniciarStreamLocalizacao() {
    _posicaoUsuarioSub?.cancel();
    _posicaoUsuarioSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 4,
      ),
    ).listen((pos) {
      _localizacaoUsuario = LatLng(pos.latitude, pos.longitude);
      if (pos.heading != 0) {
        _rumoUsuario = pos.heading;
      }
      notifyListeners();
    }, onError: (_) {});
  }

  // ==========================================================================
  // LINHAS E ITINERÁRIO
  // ==========================================================================

  Future<void> buscarLinhas(String termo) async {
    final t = termo.trim();
    if (t.isEmpty) return;

    _carregando = true;
    _mensagemErro = null;
    notifyListeners();

    try {
      // 1. Tenta buscar na API Olho Vivo em tempo real
      List<Linha> resultado = await _apiService.buscarLinhas(t);

      // 2. Se a API não retornou resultados, tenta no GTFS (dados estáticos)
      if (resultado.isEmpty) {
        try {
          resultado = await _apiService.buscarLinhasGtfs(t);
        } catch (_) {}
      }

      _linhasEncontradas = resultado;
      if (resultado.isEmpty) {
        _mensagemErro = 'Nenhuma linha encontrada para "$t"';
      } else {
        await _favoritosDao.adicionarHistoricoBusca(t);
        await carregarHistorico();
      }
    } catch (e) {
      _mensagemErro = e.toString().replaceFirst('Exception: ', '');
      _linhasEncontradas = [];
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> acompanharLinha(Linha linha) async {
    _linhaAcompanhada = linha;
    _veiculosEmTempoReal = [];
    _veiculoSelecionado = null;
    _modoSeguirVeiculo = false;
    _ultimaAtualizacao = null;

    // Assina no Socket.IO
    _realtimeService.assinarLinha(linha.cl.toString());

    // Carrega trajeto vetorial e paradas da linha
    _apiService.buscarTrajetoLinha(linha.cl, routeId: linha.routeId, letreiro: linha.lt).then((trajeto) {
      _trajetoLinhaAcompanhada = trajeto;
      notifyListeners();
    });

    _apiService.buscarParadasPorLinha(linha.cl, routeId: linha.routeId, letreiro: linha.lt).then((paradas) {
      _paradasLinhaAcompanhada = paradas;
      notifyListeners();
    });

    _indiceAba = 0; // Direciona para a aba do mapa ao vivo
    notifyListeners();
  }

  void pararAcompanhamento() {
    if (_linhaAcompanhada != null) {
      _realtimeService.cancelarLinha(_linhaAcompanhada!.cl.toString());
      _linhaAcompanhada = null;
      _trajetoLinhaAcompanhada = null;
      _paradasLinhaAcompanhada = [];
      _veiculosEmTempoReal = [];
      _veiculoSelecionado = null;
      _modoSeguirVeiculo = false;
      _ultimaAtualizacao = null;
      notifyListeners();
    }
  }

  void selecionarVeiculo(Veiculo? veiculo, {bool seguir = false}) {
    _veiculoSelecionado = veiculo;
    _modoSeguirVeiculo = seguir;
    notifyListeners();
  }

  void alternarModoSeguir() {
    _modoSeguirVeiculo = !_modoSeguirVeiculo;
    notifyListeners();
  }

  void desativarModoSeguir() {
    if (_modoSeguirVeiculo) {
      _modoSeguirVeiculo = false;
      notifyListeners();
    }
  }

  // ==========================================================================
  // PARADAS E PREVISÕES (ETA)
  // ==========================================================================

  Future<void> buscarParadas(String termo) async {
    final t = termo.trim();
    if (t.isEmpty) return;

    _carregando = true;
    _mensagemErro = null;
    notifyListeners();

    try {
      final resultado = await _apiService.buscarParadas(t);
      _paradasEncontradas = resultado;
      if (resultado.isEmpty) {
        _mensagemErro = 'Nenhum ponto de ônibus encontrado para "$t"';
      }
    } catch (e) {
      _mensagemErro = e.toString().replaceFirst('Exception: ', '');
      _paradasEncontradas = [];
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> selecionarParadaECarregarPrevisao(Parada parada) async {
    _paradaSelecionada = parada;
    _carregandoPrevisao = true;
    _previsaoParadaSelecionada = null;
    notifyListeners();

    try {
      final prev = await _apiService.previsaoParada(parada.cp);
      _previsaoParadaSelecionada = prev;
    } catch (_) {} finally {
      _carregandoPrevisao = false;
      notifyListeners();
    }
  }

  void fecharPrevisaoParada() {
    _paradaSelecionada = null;
    _previsaoParadaSelecionada = null;
    _carregandoPrevisao = false;
    notifyListeners();
  }

  // ==========================================================================
  // FAVORITOS E HISTÓRICO
  // ==========================================================================

  Future<void> carregarFavoritos() async {
    _favoritosLinhas = await _favoritosDao.listarFavoritos();
    _favoritosParadas = await _favoritosDao.listarParadasFavoritas();
    notifyListeners();
  }

  Future<void> carregarHistorico() async {
    _historicoBuscas = await _favoritosDao.listarHistoricoBuscas();
    notifyListeners();
  }

  Future<void> favoritarLinha(Linha linha) async {
    await _favoritosDao.adicionar(
      linha.cl.toString(),
      '${linha.tp} / ${linha.ts}',
      letreiro: linha.lt,
    );
    await carregarFavoritos();
  }

  Future<void> desfavoritarLinha(String codigoLinha) async {
    await _favoritosDao.remover(codigoLinha);
    await carregarFavoritos();
  }

  bool isLinhaFavorita(String codigoLinha) {
    return _favoritosLinhas.any((f) => f['codigo_linha'] == codigoLinha);
  }

  Future<void> favoritarParada(Parada parada) async {
    await _favoritosDao.adicionarParada(parada.cp, parada.np, parada.py, parada.px);
    await carregarFavoritos();
  }

  Future<void> desfavoritarParada(int codigoParada) async {
    await _favoritosDao.removerParada(codigoParada);
    await carregarFavoritos();
  }

  bool isParadaFavorita(int codigoParada) {
    return _favoritosParadas.any((p) => p['codigo_parada'] == codigoParada);
  }

  Future<void> favoritar(Linha linha) => favoritarLinha(linha);
  Future<void> desfavoritar(String codigoLinha) => desfavoritarLinha(codigoLinha);
  bool isFavorito(String codigoLinha) => isLinhaFavorita(codigoLinha);

  Future<void> limparHistorico() async {
    await _favoritosDao.limparHistoricoBuscas();
    await carregarHistorico();
  }

  void limparErro() {
    _mensagemErro = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _posicaoUsuarioSub?.cancel();
    _posicoesSub?.cancel();
    _conexaoSub?.cancel();
    _latenciaSub?.cancel();
    _metricasTimer?.cancel();
    _realtimeService.dispose();
    _apiService.fechar();
    super.dispose();
  }
}
