import 'dart:ui';
import 'package:flutter/material.dart';

/// Painel de vidro líquido escuro neutro no padrão Apple HIG (Dark Material):
/// Base escura translúcida fosca com alta legibilidade sobre mapas claros ou fundos escuros,
/// borda especular sutil de 1px e sombra suave de elevação.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.borderRadius = 18,
    this.blurSigma = 18,
    this.fillOpacity = 0.82,
    this.borderOpacity = 0.15,
    this.tint = const Color(0xFF121614),
    this.width,
    this.height,
    this.withBlur = true,
    this.borderColor,
    this.onTap,
    this.customShadows,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final double fillOpacity;
  final double borderOpacity;
  final Color tint;
  final double? width;
  final double? height;
  final bool withBlur;
  final Color? borderColor;
  final VoidCallback? onTap;
  final List<BoxShadow>? customShadows;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    // Cor de preenchimento do vidro líquido escuro:
    // Garante que elementos flutuando sobre mapas claros (ou telas escuras)
    // fiquem perfeitamente visíveis com contraste premium.
    final bool isDefaultNeutral = (tint == Colors.white ||
        tint == const Color(0xFF121614) ||
        tint == const Color(0xFF101412) ||
        tint == const Color(0xFF141716) ||
        tint == const Color(0xFF0F1311));

    final Color effectiveTint = isDefaultNeutral
        ? const Color(0xFF121614)
        : tint;

    // Se o valor de fillOpacity for da escala antiga (< 0.50),
    // mapeia proporcionalmente para a faixa de vidro escuro (0.78 - 0.88)
    final double effectiveAlpha = (fillOpacity < 0.50)
        ? (0.78 + (fillOpacity * 0.7)).clamp(0.78, 0.88)
        : fillOpacity;

    final Color borderCol = borderColor ??
        (isDefaultNeutral
            ? Colors.white.withValues(alpha: borderOpacity < 0.12 ? 0.15 : borderOpacity)
            : tint.withValues(alpha: borderOpacity));

    final decoration = BoxDecoration(
      borderRadius: radius,
      color: effectiveTint.withValues(alpha: effectiveAlpha),
      border: Border.all(
        color: borderCol,
        width: 1,
      ),
      boxShadow: customShadows ??
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
    );

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          child: content,
        ),
      );
    }

    if (!withBlur || blurSigma <= 0) {
      return Container(
        margin: margin,
        child: content,
      );
    }

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.compose(
            outer: ColorFilter.matrix(_saturate(1.2)),
            inner: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          ),
          child: content,
        ),
      ),
    );
  }

  static List<double> _saturate(double s) {
    const l = [0.2126, 0.7152, 0.0722];
    return [
      l[0] * (1 - s) + s, l[1] * (1 - s),     l[2] * (1 - s),     0, 0,
      l[0] * (1 - s),     l[1] * (1 - s) + s, l[2] * (1 - s),     0, 0,
      l[0] * (1 - s),     l[1] * (1 - s),     l[2] * (1 - s) + s, 0, 0,
      0,                  0,                  0,                  1, 0,
    ];
  }
}
