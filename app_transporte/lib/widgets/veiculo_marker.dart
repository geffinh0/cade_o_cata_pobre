import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/veiculo.dart';

/// Marcador de veículo (ônibus) no mapa — limpo e sem animação
class VeiculoMarkerWidget extends StatelessWidget {
  final Veiculo veiculo;
  final bool isSelecionado;
  final VoidCallback onTap;

  const VeiculoMarkerWidget({
    super.key,
    required this.veiculo,
    required this.isSelecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelecionado ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge com prefixo do ônibus
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSelecionado
                    ? const Color(0xFF264E36)
                    : const Color(0xF0121413),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelecionado
                      ? Colors.white.withValues(alpha: 0.80)
                      : Colors.white.withValues(alpha: 0.25),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    veiculo.p,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (veiculo.a) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.accessible_rounded,
                      size: 11,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 3),
            // Ícone circular do ônibus — estático, sem pulsação
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isSelecionado
                      ? [
                          const Color(0xFF3D8B63),
                          const Color(0xFF2D5A42),
                        ]
                      : [
                          const Color(0xFF264E36),
                          const Color(0xFF1B3B2B),
                        ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(
                      alpha: isSelecionado ? 0.90 : 0.45),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.40),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
