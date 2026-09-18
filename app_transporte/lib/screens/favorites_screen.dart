import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/linha.dart';
import '../models/parada.dart';
import '../providers/transporte_provider.dart';
import '../theme/glass_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_container.dart';
import '../widgets/previsao_modal.dart';

/// Tela de Gerenciamento de Favoritos e Histórico em Vidro Líquido Neutro
/// Layout adaptado milimetricamente para mobile.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransporteProvider>();

    final linhasFav = provider.favoritos;
    final paradasFav = provider.paradasFavoritas;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
      children: [
        // Seletor de Abas Favoritos em Vidro Neutro
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: GlassContainer(
            borderRadius: GlassTheme.radiusPill,
            fillOpacity: 0.08,
            borderOpacity: 0.14,
            blurSigma: 14,
            padding: const EdgeInsets.all(3),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(GlassTheme.radiusPill),
                color: GlassTheme.accentDarkGreen.withValues(alpha: 0.45),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w400),
              tabs: [
                Tab(
                  icon: const Icon(Icons.directions_bus_rounded, size: 16),
                  text: 'Linhas (${linhasFav.length})',
                ),
                Tab(
                  icon: const Icon(Icons.departure_board_rounded, size: 16),
                  text: 'Paradas (${paradasFav.length})',
                ),
              ],
            ),
          ),
        ),

        // Conteúdo das Abas
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 1. Linhas Favoritas
              linhasFav.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: GlassContainer(
                          borderRadius: GlassTheme.radiusCard,
                          fillOpacity: 0.08,
                          borderOpacity: 0.14,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_outline_rounded,
                                size: 46,
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Nenhuma linha favoritada',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Toque na estrela das linhas para fixá-las no topo e acessá-las com 1 toque.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: GlassTheme.textTertiary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: linhasFav.length,
                      itemBuilder: (context, index) {
                        final fav = linhasFav[index];
                        final codLinha = fav['codigo_linha'] ?? '';
                        final desc = fav['descricao'] ?? '';
                        final letreiro = fav['letreiro'] ?? codLinha;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassContainer(
                            borderRadius: GlassTheme.radiusCard,
                            fillOpacity: 0.08,
                            borderOpacity: 0.12,
                            withBlur: false,
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 3.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: GlassTheme.accentDarkGreen,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        letreiro,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        desc,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => provider.desfavoritarLinha(codLinha),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: Icon(
                                          Icons.star_rounded,
                                          color: GlassTheme.systemOrange,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                GlassButton(
                                  isPrimary: true,
                                  label: 'Acompanhar no Mapa',
                                  icon: const Icon(Icons.map_rounded, size: 14, color: Colors.white),
                                  onTap: () {
                                    final cl = int.tryParse(codLinha) ?? 0;
                                    provider.acompanharLinha(
                                      Linha(
                                        cl: cl,
                                        lc: false,
                                        lt: letreiro,
                                        sl: 1,
                                        tl: 10,
                                        tp: desc,
                                        ts: '',
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

              // 2. Paradas Favoritas
              paradasFav.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: GlassContainer(
                          borderRadius: GlassTheme.radiusCard,
                          fillOpacity: 0.08,
                          borderOpacity: 0.14,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_outline_rounded,
                                size: 46,
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Nenhuma parada favoritada',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Favoritar seus pontos frequentes permite consultar as próximas chegadas (ETA) com agilidade.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: GlassTheme.textTertiary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: paradasFav.length,
                      itemBuilder: (context, index) {
                        final fav = paradasFav[index];
                        final cp = (fav['codigo_parada'] as num?)?.toInt() ?? 0;
                        final np = fav['nome_parada']?.toString() ?? 'Parada $cp';
                        final py = (fav['py'] as num?)?.toDouble() ?? 0.0;
                        final px = (fav['px'] as num?)?.toDouble() ?? 0.0;

                        final parada = Parada(cp: cp, np: np, py: py, px: px);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassContainer(
                            borderRadius: GlassTheme.radiusCard,
                            fillOpacity: 0.08,
                            borderOpacity: 0.12,
                            withBlur: false,
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: GlassTheme.accentDarkGreen.withValues(alpha: 0.35),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.12),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.departure_board_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            np,
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Ponto $cp',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: GlassTheme.textTertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => provider.desfavoritarParada(cp),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: Icon(
                                          Icons.star_rounded,
                                          color: GlassTheme.systemOrange,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                GlassButton(
                                  isPrimary: true,
                                  label: 'Ver Previsão de Chegadas (ETA)',
                                  icon: const Icon(Icons.access_time_rounded, size: 14, color: Colors.white),
                                  onTap: () {
                                    provider.selecionarParadaECarregarPrevisao(parada);
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      isScrollControlled: true,
                                      builder: (_) => PrevisaoModalWidget(
                                        parada: parada,
                                        onFechar: () {
                                          provider.fecharPrevisaoParada();
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ],
    ),
  ),
);
  }
}
