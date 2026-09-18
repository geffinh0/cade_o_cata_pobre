import 'package:latlong2/latlong.dart';

/// Representação do Trajeto Georreferenciado de uma Linha (Polyline)
///
/// [Conceito de SD: Representação Espacial e Georreferenciamento]
/// O trajeto contém a sequência ordenada de coordenadas geográficas (WGS84)
/// que compõem o percurso viário percorrido pelos veículos da linha.
class TrajetoLinha {
  final int codigoLinha;
  final String letreiro;
  final String nome;
  final String corHex;
  final List<LatLng> pontos;

  const TrajetoLinha({
    required this.codigoLinha,
    required this.letreiro,
    required this.nome,
    required this.corHex,
    required this.pontos,
  });

  factory TrajetoLinha.fromJson(Map<String, dynamic> json) {
    final rawPontos = json['pontos'] as List<dynamic>? ?? [];
    final pontos = rawPontos.map((p) {
      final py = (p['py'] as num?)?.toDouble() ?? 0.0;
      final px = (p['px'] as num?)?.toDouble() ?? 0.0;
      return LatLng(py, px);
    }).toList();

    return TrajetoLinha(
      codigoLinha: json['codigoLinha'] as int? ?? 0,
      letreiro: json['letreiro'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      corHex: json['cor'] as String? ?? '#C00000',
      pontos: pontos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigoLinha': codigoLinha,
      'letreiro': letreiro,
      'nome': nome,
      'cor': corHex,
      'pontos': pontos.map((p) => {'py': p.latitude, 'px': p.longitude}).toList(),
    };
  }

  bool get temPontos => pontos.isNotEmpty;
}
