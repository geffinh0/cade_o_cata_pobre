import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/glass_theme.dart';
import 'glass_container.dart';

/// Controles flutuantes sobre o mapa interativo — Simples e direto
/// Permite alternar rapidamente entre "Mapa" (OpenStreetMap) e "Satélite"
class MapaControlesWidget extends StatelessWidget {
  final VoidCallback onRecentralizar;
  final VoidCallback onAlternarSeguir;
  final bool modoSeguirAtivo;
  final VoidCallback onAlternarTipoMapa;
  final bool isSatelite;
  final VoidCallback onZoomMais;
  final VoidCallback onZoomMenos;
  final VoidCallback? onResetarNorte;
  final VoidCallback? onMinhaLocalizacao;
  final bool temLocalizacaoUsuario;
  final double rotacao;

  const MapaControlesWidget({
    super.key,
    required this.onRecentralizar,
    required this.onAlternarSeguir,
    required this.modoSeguirAtivo,
    required this.onAlternarTipoMapa,
    required this.isSatelite,
    required this.onZoomMais,
    required this.onZoomMenos,
    this.onResetarNorte,
    this.onMinhaLocalizacao,
    this.temLocalizacaoUsuario = false,
    this.rotacao = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool rotacionado = rotacao.abs() > 0.05;

    return GlassContainer(
      borderRadius: 20,
      blurSigma: 18,
      fillOpacity: 0.14,
      borderOpacity: 0.18,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Alternar Mapa / Satélite com 1 toque
          _botaoControle(
            icon: isSatelite ? Icons.map_rounded : Icons.satellite_alt_rounded,
            tooltip: isSatelite ? 'Mudar para Mapa' : 'Mudar para Satélite',
            isActive: isSatelite,
            onPressed: onAlternarTipoMapa,
          ),

          _separador(),

          // Minha Localização Atual (GPS)
          if (onMinhaLocalizacao != null) ...[
            _botaoControle(
              icon: Icons.my_location_rounded,
              tooltip: 'Minha Localização',
              isActive: temLocalizacaoUsuario,
              corDestaque: temLocalizacaoUsuario ? const Color(0xFF007AFF) : null,
              onPressed: onMinhaLocalizacao!,
            ),
          ],

          // Centralizar na rota da linha acompanhada
          _botaoControle(
            icon: Icons.alt_route_rounded,
            tooltip: 'Ajustar para toda a linha',
            onPressed: onRecentralizar,
          ),

          // Reset para o norte (se o mapa estiver rotacionado)
          if (rotacionado && onResetarNorte != null) ...[
            Transform.rotate(
              angle: -rotacao * (math.pi / 180),
              child: _botaoControle(
                icon: CupertinoIcons.compass,
                tooltip: 'Alinhar ao Norte',
                onPressed: onResetarNorte!,
                corDestaque: const Color(0xFFFF5252),
              ),
            ),
          ],

          // Seguir ônibus
          _botaoControle(
            icon: modoSeguirAtivo
                ? Icons.navigation_rounded
                : Icons.navigation_outlined,
            tooltip: modoSeguirAtivo
                ? 'Desativar Seguir Ônibus'
                : 'Seguir Ônibus Selecionado',
            isActive: modoSeguirAtivo,
            onPressed: onAlternarSeguir,
          ),

          _separador(),

          // Zoom
          _botaoControle(
            icon: Icons.add_rounded,
            tooltip: 'Aumentar Zoom',
            onPressed: onZoomMais,
          ),
          _botaoControle(
            icon: Icons.remove_rounded,
            tooltip: 'Diminuir Zoom',
            onPressed: onZoomMenos,
          ),
        ],
      ),
    );
  }

  Widget _separador() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        width: 22,
        height: 1,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _botaoControle({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
    Color? corDestaque,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(GlassTheme.radiusPill),
            onTap: onPressed,
            splashColor: Colors.white.withValues(alpha: 0.15),
            highlightColor: Colors.white.withValues(alpha: 0.08),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(GlassTheme.radiusPill),
                color: isActive
                    ? const Color(0xFF264E36).withValues(alpha: 0.65)
                    : Colors.transparent,
                border: isActive
                    ? Border.all(
                        color: GlassTheme.systemGreen.withValues(alpha: 0.60),
                        width: 1,
                      )
                    : null,
              ),
              child: Icon(
                icon,
                size: 20,
                color: corDestaque ??
                    (isActive ? Colors.white : Colors.white.withValues(alpha: 0.85)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
