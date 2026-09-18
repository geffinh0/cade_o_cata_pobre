/// Modelo de Métricas de Sistemas Distribuídos do Middleware
///
/// [Conceito de SD: Observabilidade e Telemetria de Redes Distribuídas]
/// Fornece indicadores em tempo real da saúde do cluster/servidor intermediário:
/// - Clientes ativos e canais pub/sub
/// - Throughput de mensagens push
/// - Eficiência de cache no API Gateway
class MetricaSistema {
  final String status;
  final bool modoSimulado;
  final bool autenticado;
  final int tempoAtividadeSegundos;
  final int totalConexoesSocket;
  final int clientesConectadosAgora;
  final int linhasAcompanhadasAgora;
  final List<String> listaLinhasAssinadas;
  final int totalRequisicoesHttp;
  final int totalPollsRealizados;
  final int totalPushesEmitidos;
  final int totalItensEmCache;
  final int intervaloPollingMs;
  final String dataHoraServidor;

  const MetricaSistema({
    required this.status,
    required this.modoSimulado,
    required this.autenticado,
    required this.tempoAtividadeSegundos,
    required this.totalConexoesSocket,
    required this.clientesConectadosAgora,
    required this.linhasAcompanhadasAgora,
    required this.listaLinhasAssinadas,
    required this.totalRequisicoesHttp,
    required this.totalPollsRealizados,
    required this.totalPushesEmitidos,
    required this.totalItensEmCache,
    required this.intervaloPollingMs,
    required this.dataHoraServidor,
  });

  factory MetricaSistema.fromJson(Map<String, dynamic> json) {
    final rawLinhas = json['listaLinhasAssinadas'] as List<dynamic>? ?? [];
    return MetricaSistema(
      status: json['status']?.toString() ?? 'ok',
      modoSimulado: json['modoSimulado'] as bool? ?? true,
      autenticado: json['autenticado'] as bool? ?? false,
      tempoAtividadeSegundos: json['tempoAtividadeSegundos'] as int? ?? 0,
      totalConexoesSocket: json['totalConexoesSocket'] as int? ?? 0,
      clientesConectadosAgora: json['clientesConectadosAgora'] as int? ?? 0,
      linhasAcompanhadasAgora: json['linhasAcompanhadasAgora'] as int? ?? 0,
      listaLinhasAssinadas: rawLinhas.map((e) => e.toString()).toList(),
      totalRequisicoesHttp: json['totalRequisicoesHttp'] as int? ?? 0,
      totalPollsRealizados: json['totalPollsRealizados'] as int? ?? 0,
      totalPushesEmitidos: json['totalPushesEmitidos'] as int? ?? 0,
      totalItensEmCache: json['totalItensEmCache'] as int? ?? 0,
      intervaloPollingMs: json['intervaloPollingMs'] as int? ?? 15000,
      dataHoraServidor: json['dataHoraServidor']?.toString() ?? '',
    );
  }

  String get tempoAtividadeFormatado {
    final horas = tempoAtividadeSegundos ~/ 3600;
    final minutos = (tempoAtividadeSegundos % 3600) ~/ 60;
    final segundos = tempoAtividadeSegundos % 60;
    return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }
}
