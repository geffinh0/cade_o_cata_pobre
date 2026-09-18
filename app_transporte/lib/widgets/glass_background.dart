import 'package:flutter/material.dart';

/// Fundo líquido escuro e neutro com profundidade multi-camada (Padrão Apple HIG)
/// Três blobs ambientais com nuances de verde floresta e azulado para sensação de profundidade viva.
class GlassBackground extends StatelessWidget {
  const GlassBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Fundo Base Preto Profundo / Neutro
        Container(
          color: const Color(0xFF08090A),
        ),

        // 2. Nuance Ambiental Sutil no Topo (Verde Floresta Ultra Escuro)
        Positioned(
          top: -120,
          left: -100,
          child: Container(
            width: 450,
            height: 450,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1B3B2B).withValues(alpha: 0.20),
                  const Color(0xFF14281E).withValues(alpha: 0.10),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),

        // 3. Nuance Ambiental no Canto Inferior Direito (Azulado/Índigo Ultra Escuro)
        Positioned(
          bottom: -80,
          right: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1A2230).withValues(alpha: 0.18),
                  const Color(0xFF151B24).withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),

        // 4. Nuance Ambiental Central-Inferior (Grafite Quente com Toque de Bordô)
        Positioned(
          bottom: 120,
          left: 60,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1C221F).withValues(alpha: 0.14),
                  Colors.transparent,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),

        // 5. Grão de Textura Muito Sutil — Simula a textura visual de vidro fosco
        // Utiliza um gradiente linear com noise simulado por micro-stops
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.012),
                Colors.transparent,
                Colors.white.withValues(alpha: 0.008),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),

        // 6. Conteúdo sobreposto
        child,
      ],
    );
  }
}
