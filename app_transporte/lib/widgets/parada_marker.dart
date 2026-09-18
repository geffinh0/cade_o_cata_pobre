import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/parada.dart';

/// Marcador estilizado de ponto de ônibus / parada no mapa (Premium)
/// Maior, com label ao selecionar, e com melhor contraste visual.
class ParadaMarkerWidget extends StatelessWidget {
  final Parada parada;
  final bool isSelecionada;
  final bool isCompact;
  final VoidCallback onTap;

  const ParadaMarkerWidget({
    super.key,
    required this.parada,
    required this.isSelecionada,
    this.isCompact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact && !isSelecionada) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3D8B63),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.70),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: '${parada.np} (Ponto ${parada.cp})',
        child: AnimatedScale(
          scale: isSelecionada ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label do nome da parada (só quando selecionada)
              if (isSelecionada)
                Container(
                  margin: const EdgeInsets.only(bottom: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  constraints: const BoxConstraints(maxWidth: 120),
                  decoration: BoxDecoration(
                    color: const Color(0xF0121413),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    parada.np,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),

              // Marcador circular principal
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelecionada
                      ? const Color(0xFF2D5A42)
                      : const Color(0xFF14241B),
                  border: Border.all(
                    color: isSelecionada
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
                    width: isSelecionada ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.40),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.departure_board_rounded,
                  color: Colors.white,
                  size: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
