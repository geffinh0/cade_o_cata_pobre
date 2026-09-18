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

  /// Descrição amigável para exibição no app
  String get nomeExibicao => '$lt - $tp / $ts';
  String get sentidoDescricao => sl == 1 ? 'Ida ($tp → $ts)' : 'Volta ($ts → $tp)';
}
