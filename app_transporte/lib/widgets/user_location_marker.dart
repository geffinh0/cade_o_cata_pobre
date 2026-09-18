import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Marcador de Localização Atual do Usuário no Mapa (Padrão Apple Maps / iOS HIG)
/// Exibe um ponto azul vibrante com feixe de direção (rumo), anel de pulsação suave e borda de alto contraste.
class UserLocationMarkerWidget extends StatefulWidget {
  final VoidCallback? onTap;
  final double? rumo; // Direção / Bússola em graus (0..360)

  const UserLocationMarkerWidget({
    super.key,
    this.onTap,
    this.rumo,
  });

  @override
  State<UserLocationMarkerWidget> createState() => _UserLocationMarkerWidgetState();
}

class _UserLocationMarkerWidgetState extends State<UserLocationMarkerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 18.0, end: 44.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutQuad),
    );

    _opacityAnimation = Tween<double>(begin: 0.40, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutQuad),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color blueColor = Color(0xFF007AFF); // Apple iOS Blue

    return GestureDetector(
      onTap: widget.onTap,
      child: Center(
        child: SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 0. Feixe de Direção da Pessoa (Cone de visão / bússola)
              if (widget.rumo != null)
                Transform.rotate(
                  angle: widget.rumo! * (math.pi / 180),
                  child: CustomPaint(
                    size: const Size(60, 60),
                    painter: _DirectionConePainter(color: blueColor),
                  ),
                ),
              // 1. Halo pulsante de sinal GPS
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: _pulseAnimation.value,
                    height: _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: blueColor.withValues(alpha: _opacityAnimation.value),
                    ),
                  );
                },
              ),

              // 2. Halo fixo suave
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: blueColor.withValues(alpha: 0.18),
                ),
              ),

              // 3. Ponto central azul com borda branca e sombra
              Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: blueColor,
                  border: Border.all(
                    color: Colors.white,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Desenha o feixe suave cônico de visão/caminhada da pessoa (Padrão Apple/Google Maps)
class _DirectionConePainter extends CustomPainter {
  final Color color;

  const _DirectionConePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.38),
          color.withValues(alpha: 0.14),
          Colors.transparent,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Arco frontal de 60 graus centrado para cima (-pi/2)
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2 - 0.52,
        1.04,
        false,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DirectionConePainter oldDelegate) =>
      oldDelegate.color != color;
}
