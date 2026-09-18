import 'package:flutter/material.dart';
import '../theme/glass_theme.dart';

/// Indicador minimalista de status da conexão (Padrão Apple HIG)
/// Exibe apenas o ponto circular com a cor de status da conexão (Verde = Ao vivo, Laranja/Vermelho = Offline)
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
    final corPonto = conectado ? const Color(0xFF30D158) : GlassTheme.systemRed;
    final tooltipTexto = conectado
        ? 'Ao vivo • Conectado ($latenciaMs ms)'
        : 'Desconectado do servidor';

    return Tooltip(
      message: tooltipTexto,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: corPonto.withValues(alpha: 0.12),
            border: Border.all(
              color: corPonto.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Center(
            child: Container(
              width: 8.5,
              height: 8.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: corPonto,
                boxShadow: [
                  BoxShadow(
                    color: corPonto.withValues(alpha: 0.60),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

