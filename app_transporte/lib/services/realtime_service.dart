import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../models/veiculo.dart';

/// Serviço de Comunicação em Tempo Real via WebSocket (Socket.IO)
///
/// [Conceito de SD: Paradigma Publish/Subscribe e Orientação a Eventos]
/// Em vez do dispositivo móvel realizar polling contínuo (requisições periódicas
/// desgastantes para a bateria e largura de banda), utiliza-se o padrão Pub/Sub:
/// 1. O app "assina" o tópico da linha desejada (`assinar_linha`).
/// 2. O middleware agrupa todas as assinaturas e consulta a SPTrans uma única vez.
/// 3. Quando chegam novos dados, o middleware faz "Push" para os clientes inscritos.
class RealtimeService {
  socket_io.Socket? _socket;
  final StreamController<PosicaoEvento> _posicoesController =
      StreamController<PosicaoEvento>.broadcast();
  final StreamController<bool> _statusConexaoController =
      StreamController<bool>.broadcast();
  final StreamController<int> _latenciaController =
      StreamController<int>.broadcast();

  bool _conectado = false;
  String? _linhaAssinadaAtual;
  String? _ultimoBaseUrl;
  int _latenciaMs = 0;
  int _totalEventosRecebidos = 0;
  Timer? _pingTimer;

  Stream<PosicaoEvento> get posicoesStream => _posicoesController.stream;
  Stream<bool> get statusConexaoStream => _statusConexaoController.stream;
  Stream<int> get latenciaStream => _latenciaController.stream;

  bool get isConectado => _conectado;
  String? get linhaAssinadaAtual => _linhaAssinadaAtual;
  int get latenciaAtual => _latenciaMs;
  int get totalEventosRecebidos => _totalEventosRecebidos;

  /// Inicializa e abre o canal de WebSocket com o Middleware
  void conectar(String baseUrl) {
    if (_socket != null && _ultimoBaseUrl == baseUrl && _socket!.connected) {
      return;
    }

    desconectar();
    _ultimoBaseUrl = baseUrl;

    try {
      _socket = socket_io.io(
        baseUrl,
        socket_io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(2000)
            .build(),
      );

      _socket!.onConnect((_) {
        _conectado = true;
        _statusConexaoController.add(true);
        _iniciarPingLoop();

        if (_linhaAssinadaAtual != null) {
          _socket!.emit('assinar_linha', _linhaAssinadaAtual);
        }
      });

      _socket!.onDisconnect((_) {
        _conectado = false;
        _statusConexaoController.add(false);
        _pararPingLoop();
      });

      _socket!.onConnectError((err) {
        _conectado = false;
        _statusConexaoController.add(false);
      });

      // Recepção do evento 'posicoes' transmitido pelo Middleware
      _socket!.on('posicoes', (dynamic data) {
        _totalEventosRecebidos++;
        try {
          if (data is Map<String, dynamic>) {
            final evento = PosicaoEvento.fromJson(data);
            _posicoesController.add(evento);
          } else if (data is Map) {
            final evento = PosicaoEvento.fromJson(Map<String, dynamic>.from(data));
            _posicoesController.add(evento);
          }
        } catch (_) {}
      });

      // Medição de latência RTT Pong
      _socket!.on('pong_check', (dynamic data) {
        if (data is Map) {
          final enviado = data['timestampCliente'] as int? ?? 0;
          if (enviado > 0) {
            _latenciaMs = DateTime.now().millisecondsSinceEpoch - enviado;
            _latenciaController.add(_latenciaMs);
          }
        }
      });

      _socket!.connect();
    } catch (e) {
      _conectado = false;
      _statusConexaoController.add(false);
    }
  }

  void _iniciarPingLoop() {
    _pararPingLoop();
    _pingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_socket != null && _socket!.connected) {
        _socket!.emit('ping_check', DateTime.now().millisecondsSinceEpoch);
      }
    });
  }

  void _pararPingLoop() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  /// Registra interesse (Subscribe) no tópico da linha informada
  void assinarLinha(String codigoLinha) {
    if (_linhaAssinadaAtual != null && _linhaAssinadaAtual != codigoLinha) {
      cancelarLinha(_linhaAssinadaAtual!);
    }
    _linhaAssinadaAtual = codigoLinha;
    if (_socket != null && _socket!.connected) {
      _socket!.emit('assinar_linha', codigoLinha);
    }
  }

  /// Cancela o interesse (Unsubscribe) no tópico da linha
  void cancelarLinha(String codigoLinha) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('cancelar_linha', codigoLinha);
    }
    if (_linhaAssinadaAtual == codigoLinha) {
      _linhaAssinadaAtual = null;
    }
  }

  /// Encerra as conexões e limpa recursos de rede
  void desconectar() {
    _pararPingLoop();
    if (_socket != null) {
      try {
        _socket!.disconnect();
        _socket!.dispose();
      } catch (_) {}
      _socket = null;
    }
    _conectado = false;
    _statusConexaoController.add(false);
  }

  void dispose() {
    desconectar();
    _posicoesController.close();
    _statusConexaoController.close();
    _latenciaController.close();
  }
}
