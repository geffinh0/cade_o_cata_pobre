/// Modelo de Linha de Ônibus da SPTrans (API Olho Vivo)
/// 
/// [Conceito de SD: Transparência de Acesso e Representação]
/// O cliente móvel consome este modelo desacoplado da fonte original de dados.
/// O middleware atua como intermediário, padronizando a serialização em JSON
/// independente do protocolo interno da SPTrans.
class Linha {
  final int cl; // Código identificador interno da linha
  final bool lc; // Indica se o trajeto é circular
  final String lt; // Letreiro numérico da linha (ex: "8000-10")
  final int sl; // Sentido: 1 = Terminal Principal -> Secundário, 2 = Secundário -> Principal
  final int tl; // Tipo da linha
  final String tp; // Nome do Terminal Principal (Origem)
  final String ts; // Nome do Terminal Secundário (Destino)
  final String? routeId; // ID da rota GTFS (ex: "8000-10")
  final String? cor; // Cor da rota

  const Linha({
    required this.cl,
    required this.lc,
    required this.lt,
    required this.sl,
    required this.tl,
    required this.tp,
    required this.ts,
    this.routeId,
    this.cor,
  });

  /// Converte o JSON repassado pelo middleware em uma instância fortemente tipada
  factory Linha.fromJson(Map<String, dynamic> json) {
    return Linha(
      cl: json['cl'] as int? ?? 0,
      lc: json['lc'] as bool? ?? false,
      lt: json['lt'] as String? ?? '',
      sl: json['sl'] as int? ?? 1,
      tl: json['tl'] as int? ?? 0,
      tp: json['tp'] as String? ?? '',
      ts: json['ts'] as String? ?? '',
      routeId: json['route_id'] as String?,
      cor: json['cor'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cl': cl,
      'lc': lc,
      'lt': lt,
      'sl': sl,
      'tl': tl,
      'tp': tp,
      'ts': ts,
      if (routeId != null) 'route_id': routeId,
      if (cor != null) 'cor': cor,
    };
  }

  /// Destino para onde este veículo está se deslocando no sentido atual
  String get destino => (sl == 1) ? ts : tp;

  /// Origem de onde este veículo partiu no sentido atual
  String get origem => (sl == 1) ? tp : ts;

  /// Letreiro do visor frontal do ônibus (nome do destino)
  String get letreiroDestino => destino.isNotEmpty ? destino : tp;

  /// Rótulo curto do sentido ('IDA', 'VOLTA', 'CIRCULAR')
  String get sentidoRotulo {
    if (lc) return 'CIRCULAR';
    return sl == 1 ? 'IDA' : 'VOLTA';
  }

  /// Indica se é sentido Ida (1: TP -> TS)
  bool get isIda => sl == 1;

  /// Indica se é sentido Volta (2: TS -> TP)
  bool get isVolta => sl == 2;

  /// Indica se o trajeto é circular
  bool get isCircular => lc;

  /// Descrição explicada do trajeto com seta direcional
  String get trajetoCompleto {
    if (lc) return '$origem (Circular)';
    return '$origem ➔ $destino';
  }

  /// Descrição amigável para exibição no app
  String get nomeExibicao => '$lt • Para: $destino ($sentidoRotulo)';
  String get sentidoDescricao => '$sentidoRotulo ($origem ➔ $destino)';
}
