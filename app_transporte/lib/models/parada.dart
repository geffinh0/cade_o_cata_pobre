/// Modelo de Ponto de Ônibus / Parada da SPTrans
///
/// [Conceito de SD: Localização e Georreferenciamento Distribuído]
/// As coordenadas geográficas (py: latitude, px: longitude) permitem que
/// diferentes nós (middleware, cliente móvel, serviço de mapas) compartilhem
/// um referencial espacial comum (WGS84).
class Parada {
  final int cp; // Código da parada
  final String np; // Nome da parada / logradouro
  final String ed; // Endereço de localização da parada
  final double py; // Latitude
  final double px; // Longitude

  const Parada({
    required this.cp,
    required this.np,
    this.ed = '',
    required this.py,
    required this.px,
  });

  factory Parada.fromJson(Map<String, dynamic> json) {
    return Parada(
      cp: json['cp'] as int? ?? 0,
      np: json['np'] as String? ?? '',
      ed: json['ed'] as String? ?? '',
      py: (json['py'] as num?)?.toDouble() ?? 0.0,
      px: (json['px'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cp': cp,
      'np': np,
      'ed': ed,
      'py': py,
      'px': px,
    };
  }
}
