import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/transporte_provider.dart';
import '../theme/glass_theme.dart';
import '../widgets/distribuido_badge.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_container.dart';
import 'favorites_screen.dart';
import 'lines_screen.dart';
import 'map_screen.dart';
import 'stops_screen.dart';

/// Tela Principal com Floating Glass Navigation Bar no Padrão Apple HIG
/// Menu simétrico, com 4 abas equilibradas e adaptadas milimetricamente para mobile.
class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransporteProvider>();

    final telas = const [
      MapScreen(),
      LinesScreen(),
      StopsScreen(),
      FavoritesScreen(),
    ];

    final titulos = [
      'Mapa ao Vivo',
      'Linhas de Ônibus',
      'Paradas & Chegadas',
      'Favoritos',
    ];

    final subtitulos = [
      'Trajetos e monitoramento de frota',
      'Consulta de itinerários e sentidos',
      'Pontos e previsões em tempo real',
      'Rotas salvas no dispositivo',
    ];

    final totalFavoritos = provider.favoritos.length + provider.paradasFavoritas.length;
    final veiculosAtivos = provider.veiculos.length;

    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // 1. Estrutura Principal (Header Compacto + Telas)
              Column(
                children: [
                  // Top Glass Header — Compacto e Mobile-First
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                    child: GlassContainer(
                      borderRadius: 16,
                      blurSigma: GlassTheme.blurSurface,
                      fillOpacity: 0.08,
                      borderOpacity: 0.12,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/cata_pobre_icon.png',
                            width: 34,
                            height: 34,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Cadê o Cata Pobre',
                                      style: GoogleFonts.inter(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.16),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        titulos[provider.indiceAba].toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withValues(alpha: 0.75),
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  provider.indiceAba == 0
                                      ? 'Onde tá o busão? • Rastreamento ao vivo'
                                      : subtitulos[provider.indiceAba],
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w400,
                                    color: GlassTheme.textTertiary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Indicador sutil de conexão
                          DistribuidoBadgeWidget(
                            conectado: provider.conectado,
                            latenciaMs: provider.latenciaMs,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Área de Visualização das Telas (Full height com scroll sob a tab bar)
                  Expanded(
                    child: IndexedStack(
                      index: provider.indiceAba,
                      children: telas,
                    ),
                  ),
                ],
              ),

              // 2. Floating Glass Bottom Navigation Bar (4 Abas Perfeitamente Simétricas)
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: GlassContainer(
                  borderRadius: 24,
                  blurSigma: 20,
                  fillOpacity: 0.14,
                  borderOpacity: 0.16,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabItem(
                          index: 0,
                          currentIndex: provider.indiceAba,
                          iconOutlined: CupertinoIcons.map,
                          iconFilled: CupertinoIcons.map_fill,
                          label: 'Mapa',
                          badgeCount: veiculosAtivos,
                          onTap: () => provider.mudarAba(0),
                        ),
                      ),
                      Expanded(
                        child: _buildTabItem(
                          index: 1,
                          currentIndex: provider.indiceAba,
                          iconOutlined: Icons.directions_bus_outlined,
                          iconFilled: Icons.directions_bus_rounded,
                          label: 'Linhas',
                          onTap: () => provider.mudarAba(1),
                        ),
                      ),
                      Expanded(
                        child: _buildTabItem(
                          index: 2,
                          currentIndex: provider.indiceAba,
                          iconOutlined: CupertinoIcons.placemark,
                          iconFilled: CupertinoIcons.placemark_fill,
                          label: 'Paradas',
                          onTap: () => provider.mudarAba(2),
                        ),
                      ),
                      Expanded(
                        child: _buildTabItem(
                          index: 3,
                          currentIndex: provider.indiceAba,
                          iconOutlined: CupertinoIcons.star,
                          iconFilled: CupertinoIcons.star_fill,
                          label: 'Favoritos',
                          badgeCount: totalFavoritos,
                          onTap: () => provider.mudarAba(3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required int currentIndex,
    required IconData iconOutlined,
    required IconData iconFilled,
    required String label,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    final isSelected = index == currentIndex;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.16),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? iconFilled : iconOutlined,
                  size: 20,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.65),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    top: -3,
                    right: -7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : GlassTheme.accentDarkGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF141615)
                              : Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.65),
                letterSpacing: -0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
