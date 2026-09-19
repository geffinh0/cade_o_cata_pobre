import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/linha.dart';
import '../theme/glass_theme.dart';

/// Badge visual de alto contraste e rápida identificação do Sentido da Linha (Ida / Volta / Circular)
class SentidoBadge extends StatelessWidget {
  const SentidoBadge({
    super.key,
    required this.linha,
    this.compact = false,
  });

  final Linha linha;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;
    IconData icon;
    String label;

    if (linha.isCircular) {
      bg = const Color(0xFF282015);
      border = const Color(0xFF8D6E42);
      text = const Color(0xFFFFB74D);
      icon = Icons.loop_rounded;
      label = 'CIRCULAR';
    } else if (linha.isVolta) {
      // Sentido Volta (TS -> TP) em azul-petróleo escuro
      bg = const Color(0xFF112233);
      border = const Color(0xFF2A557A);
      text = const Color(0xFF64B5F6);
      icon = Icons.arrow_back_rounded;
      label = 'VOLTA';
    } else {
      // Sentido Ida (TP -> TS) em verde-floresta
      bg = const Color(0xFF13281C);
      border = const Color(0xFF2D613F);
      text = const Color(0xFF4ADE80);
      icon = Icons.arrow_forward_rounded;
      label = 'IDA';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2.5 : 3.5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(GlassTheme.radiusChip),
        border: Border.all(
          color: border.withValues(alpha: 0.60),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 11 : 12, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: text,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
