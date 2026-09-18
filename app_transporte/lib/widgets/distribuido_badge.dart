import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/glass_theme.dart';
import 'glass_container.dart';

/// Indicador discreto de status ao vivo da conexão (Padrão Apple HIG)
class DistribuidoBadgeWidget extends StatelessWidget {
  final bool conectado;
  final int latenciaMs;
  final VoidCallback? onTap;

  const DistribuidoBadgeWidget({
    super.key,
    required this.conectado,
    required this.latenciaMs,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final corPonto = conectado ? GlassTheme.systemGreen : GlassTheme.systemRed;
    final texto = conectado ? 'Ao Vivo' : 'Offline';

    return GlassContainer(
      borderRadius: GlassTheme.radiusPill,
      fillOpacity: 0.08,
      borderOpacity: 0.14,
      blurSigma: 12,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.5,
            height: 6.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: corPonto,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.90),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
