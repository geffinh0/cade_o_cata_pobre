/// Modelo de Veículo (Ônibus) com telemetria por GPS da SPTrans
///
/// [Conceito de SD: Sincronização de Relógio e Telemetria em Tempo Real]
/// Cada veículo atua como um nó sensor móvel que envia sua telemetria
/// periódica com carimbo de tempo (ta). A reconciliação desses dados é tratada
/// no middleware e propagada para os clientes.
class Veiculo {
  final String p; // Prefixo do veículo (número impresso no ônibus)
  final bool a; // Se possui acessibilidade (elevador para cadeirantes)
  final String ta; // Timestamp da posição (ISO 8601 ou UTC)
  final double py; // Latitude atual
  final double px; // Longitude atual

  const Veiculo({
    required this.p,
    required this.a,
    required this.ta,
    required this.py,
    required this.px,
  });

  factory Veiculo.fromJson(Map<String, dynamic> json) {
    return Veiculo(
      p: json['p']?.toString() ?? '',
      a: json['a'] as bool? ?? false,
      ta: json['ta'] as String? ?? '',
      py: (json['py'] as num?)?.toDouble() ?? 0.0,
      px: (json['px'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'p': p,
      'a': a,
      'ta': ta,
      'py': py,
      'px': px,
    };
  }
}

/// Agregação de veículos de uma linha em um determinado instante (hr)
class PosicaoLinha {
  final String hr; // Hora da apuração (ex: "15:32")
  final List<Veiculo> vs; // Lista de veículos ativos na linha

  const PosicaoLinha({
    required this.hr,
    required this.vs,
  });

  factory PosicaoLinha.fromJson(Map<String, dynamic> json) {
    final rawVs = json['vs'] as List<dynamic>? ?? [];
    return PosicaoLinha(
      hr: json['hr'] as String? ?? '',
      vs: rawVs
          .whereType<Map<String, dynamic>>()
          .map((item) => Veiculo.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hr': hr,
      'vs': vs.map((v) => v.toJson()).toList(),
    };
  }
}

/// Payload do evento 'posicoes' emitido pelo canal Socket.IO do middleware
class PosicaoEvento {
  final String codigoLinha;
  final PosicaoLinha dados;
  final int timestamp;

  const PosicaoEvento({
    required this.codigoLinha,
    required this.dados,
    required this.timestamp,
  });

  factory PosicaoEvento.fromJson(Map<String, dynamic> json) {
    final rawDados = json['dados'] as Map<String, dynamic>? ?? {};
    return PosicaoEvento(
      codigoLinha: json['codigoLinha']?.toString() ?? '',
      dados: PosicaoLinha.fromJson(rawDados),
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
