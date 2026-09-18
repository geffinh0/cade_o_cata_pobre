import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/glass_theme.dart';
import 'glass_container.dart';

/// Campo de Texto em Vidro Líquido Neutro (Padrão Apple HIG)
class GlassTextField extends StatelessWidget {
  const GlassTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon = Icons.search_rounded,
    this.suffixIcon,
    this.onSubmitted,
    this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: GlassTheme.radiusInput, // 10.0
      fillOpacity: 0.07,                    // 7% fill padrão
      borderOpacity: 0.14,                  // 14% borda quase invisível
      blurSigma: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            color: Colors.white38,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: Colors.white54,
            size: 19,
          ),
          suffixIcon: suffixIcon,
        ),
        onSubmitted: onSubmitted,
        onChanged: onChanged,
      ),
    );
  }
}
