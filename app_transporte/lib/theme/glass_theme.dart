import 'package:flutter/material.dart';

/// Design System Glassmorphism Neutro (Padrão Apple HIG)
///
/// Superfície de vidro líquido fosco, preenchimento neutro em baixa opacidade,
/// borda sutil de 1px, sombra discreta e detalhes em verde escuro simples e contidos.
class GlassTheme {
  // Cores de Base Neutra (Grayscale)
  static const Color bgDark = Color(0xFF08090A);
  static const Color surfaceDark = Color(0xFF141615);
  static const Color surfaceCard = Color(0xFF1C1E1D);

  // Acentos Discretos em Verde Escuro (Substituem os antigos neons)
  static const Color accentDarkGreen = Color(0xFF264E36);
  static const Color accentForest = Color(0xFF1E3A2B);
  static const Color accentPine = Color(0xFF2D5A42);
  static const Color accentSurface = Color(0xFF15261C);

  // Cores Funcionais de Sistema (Estilo iOS HIG)
  static const Color systemGreen = Color(0xFF30D158); // Sucesso / Status Ao Vivo
  static const Color systemRed = Color(0xFFFF453A);   // Destrutivo / Desconectado
  static const Color systemOrange = Color(0xFFFF9F0A);// Alerta / Atenção
  static const Color systemBlue = Color(0xFF0071E3);  // Ação primária alternativa
  static const Color skyInfo = systemBlue;

  // Tipografia / Inks Neutros
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFFC7C7CC);
  static const Color textTertiary = Color(0xFF8E8E93);
  static const Color textMuted = Color(0x73FFFFFF); // ~45%

  // Raios de Borda (Escala do Guia de Design)
  static const double radiusChip = 8.0;     // Chips e tags
  static const double radiusInput = 10.0;   // Campos e inputs
  static const double radiusButton = 14.0;  // Botões
  static const double radiusCard = 18.0;    // Cards padrão
  static const double radiusModal = 24.0;   // Modais e sheets
  static const double radiusPill = 999.0;   // Nav bar e pílulas

  // Tints de Vidro Escuro (Preenchimento Sólido Neutro para Vidro Líquido Escuro)
  static const double fillBase = 0.60;      // 60% - Background layer
  static const double fillSubtle = 0.72;    // 72% - Superfície sutil
  static const double fillSurface = 0.82;   // 82% - Card padrão / painéis flutuantes
  static const double fillOverlay = 0.88;   // 88% - Modal / overlay
  static const double fillPressed = 0.92;   // 92% - Estado pressed

  // Opacidade de Borda (1px)
  static const double borderSubtle = 0.10;  // 10%
  static const double borderDefault = 0.14; // 14%
  static const double borderHighlight = 0.18; // 18%

  // Blur Sigmas
  static const double blurBase = 12.0;
  static const double blurSurface = 18.0;
  static const double blurOverlay = 25.0;

  // Sombras Neutras e Discretas (Curta, suave, sem cor)
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get modalShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.22),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];
}
