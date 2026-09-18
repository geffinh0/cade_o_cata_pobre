import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/transporte_provider.dart';
import '../theme/glass_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_search_bar.dart';
import '../widgets/previsao_modal.dart';

/// Tela de Busca de Paradas/Pontos de Ônibus e Consulta de Chegadas (ETA) em Vidro Líquido Neutro
/// Layout adaptado milimetricamente para mobile evitando compressão de texto.
class StopsScreen extends StatefulWidget {
  const StopsScreen({super.key});

  @override
  State<StopsScreen> createState() => _StopsScreenState();
}

class _StopsScreenState extends State<StopsScreen> {
  final TextEditingController _buscaController = TextEditingController();

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransporteProvider>();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
      children: [
        // Barra de Busca
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassSearchBar(
                controller: _buscaController,
                hintText: 'Digite a rua, avenida ou ponto...',
                prefixIcon: Icons.location_on_rounded,
                isLoading: provider.carregando,
                onSubmitted: (val) => provider.buscarParadas(val),
                onSearch: () => provider.buscarParadas(_buscaController.text),
                onClear: () {
                  _buscaController.clear();
                  provider.buscarParadas('');
                },
              ),
            ],
          ),
        ),

        // Lista de Paradas com rolagem suave sob a tab bar
        Expanded(
          child: provider.carregando
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Localizando pontos de parada...',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : provider.paradas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _buscaController.text.trim().isEmpty
                                ? Icons.place_outlined
                                : Icons.location_off_rounded,
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _buscaController.text.trim().isEmpty
                                ? 'Buscar Paradas'
                                : 'Nenhum ponto encontrado',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _buscaController.text.trim().isEmpty
                                ? 'Digite a rua, avenida ou terminal acima para buscar pontos.'
                                : 'Não encontramos paradas para "${_buscaController.text.trim()}".',
                            style: GoogleFonts.inter(
                              color: GlassTheme.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: provider.paradas.length,
                      itemBuilder: (context, index) {
                        final parada = provider.paradas[index];
                        final isFav = provider.isParadaFavorita(parada.cp);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassContainer(
                            borderRadius: GlassTheme.radiusCard,
                            fillOpacity: 0.08,
                            borderOpacity: 0.12,
                            withBlur: false, // Performance estrita
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Linha Superior: Ícone + Nome + Favorito
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
                                            parada.np,
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14.5,
                                              color: Colors.white,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Ponto ${parada.cp}',
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
                                      onTap: () {
                                        if (isFav) {
                                          provider.desfavoritarParada(parada.cp);
                                        } else {
                                          provider.favoritarParada(parada);
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Icon(
                                          isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                                          color: isFav ? GlassTheme.systemOrange : Colors.white54,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Ação de Previsão em Linha Dedicada e Confortável
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
        ),
      ],
    ),
  ),
);
  }
}
