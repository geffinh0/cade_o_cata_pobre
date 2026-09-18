import 'package:flutter/material.dart';

/// Marcador de Localização Atual do Usuário no Mapa (Padrão Apple Maps / iOS HIG)
/// Exibe um ponto azul vibrante com anel de pulsação suave e borda branca de alto contraste.
class UserLocationMarkerWidget extends StatefulWidget {
  final VoidCallback? onTap;

  const UserLocationMarkerWidget({
    super.key,
    this.onTap,
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
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
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
