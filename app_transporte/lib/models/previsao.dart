/// Modelos para Previsão de Chegada em Parada (API Olho Vivo SPTrans)
///
/// [Conceito de SD: Agregação e Processamento em Lote]
/// Em vez do cliente calcular estimativas de rota para cada ônibus,
/// o provedor central agrega a malha viária e processa as previsões de chegada,
/// entregando um payload aninhado com alta coesão e reduzindo o processamento móvel.
library;

class PrevisaoVeiculo {
  final String p; // Prefixo do veículo
  final String t; // Horário previsto de chegada (ex: "15:45")
  final double py; // Latitude atual do veículo
  final double px; // Longitude atual do veículo

  const PrevisaoVeiculo({
    required this.p,
    required this.t,
    required this.py,
    required this.px,
  });

  factory PrevisaoVeiculo.fromJson(Map<String, dynamic> json) {
    return PrevisaoVeiculo(
      p: json['p']?.toString() ?? '',
      t: json['t']?.toString() ?? '',
      py: (json['py'] as num?)?.toDouble() ?? 0.0,
      px: (json['px'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'p': p,
      't': t,
      'py': py,
      'px': px,
    };
  }
}

class PrevisaoLinha {
  final String c; // Letreiro completo da linha (ex: "8000-10")
  final int cl; // Código interno da linha
  final int sl; // Sentido (1 = Ida, 2 = Volta)
  final int qv; // Quantidade de veículos com previsão
  final List<PrevisaoVeiculo> vs; // Lista de veículos previstos

  const PrevisaoLinha({
    required this.c,
    required this.cl,
    required this.sl,
    required this.qv,
    required this.vs,
  });

  factory PrevisaoLinha.fromJson(Map<String, dynamic> json) {
    final rawVs = json['vs'] as List<dynamic>? ?? [];
    return PrevisaoLinha(
      c: json['c']?.toString() ?? '',
      cl: json['cl'] as int? ?? 0,
      sl: json['sl'] as int? ?? 1,
      qv: json['qv'] as int? ?? 0,
      vs: rawVs
          .whereType<Map<String, dynamic>>()
          .map((item) => PrevisaoVeiculo.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'c': c,
      'cl': cl,
      'sl': sl,
      'qv': qv,
      'vs': vs.map((v) => v.toJson()).toList(),
    };
  }
}

class Previsao {
  final int cp; // Código da parada
  final String np; // Nome da parada
  final double py; // Latitude da parada
  final double px; // Longitude da parada
  final List<PrevisaoLinha> l; // Linhas que atendem a parada com veículos previstos

  const Previsao({
    required this.cp,
    required this.np,
    required this.py,
    required this.px,
    required this.l,
  });

  factory Previsao.fromJson(Map<String, dynamic> json) {
    // A SPTrans aninha os dados da parada dentro da chave 'p'
    Map<String, dynamic> paradaMap = json;
    if (json.containsKey('p') && json['p'] is Map<String, dynamic>) {
      paradaMap = json['p'] as Map<String, dynamic>;
    }

    final rawL = paradaMap['l'] as List<dynamic>? ?? [];
    return Previsao(
      cp: (paradaMap['cp'] as num?)?.toInt() ?? 0,
      np: paradaMap['np'] as String? ?? '',
      py: (paradaMap['py'] as num?)?.toDouble() ?? 0.0,
      px: (paradaMap['px'] as num?)?.toDouble() ?? 0.0,
      l: rawL
          .whereType<Map<String, dynamic>>()
          .map((item) => PrevisaoLinha.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cp': cp,
      'np': np,
      'py': py,
      'px': px,
      'l': l.map((linha) => linha.toJson()).toList(),
    };
  }
}
