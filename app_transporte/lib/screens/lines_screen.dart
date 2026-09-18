import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/transporte_provider.dart';
import '../theme/glass_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_search_bar.dart';
import 'line_detail_screen.dart';

/// Tela de Busca e Exploração de Linhas de Transporte em Vidro Líquido Neutro
/// Layout adaptado milimetricamente para mobile com controle segmentado Apple HIG.
class LinesScreen extends StatefulWidget {
  const LinesScreen({super.key});

  @override
  State<LinesScreen> createState() => _LinesScreenState();
}

class _LinesScreenState extends State<LinesScreen> {
  final TextEditingController _buscaController = TextEditingController();
  int _filtroSentido = 0; // 0: Todos, 1: Ida, 2: Volta

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransporteProvider>();

    // Aplica filtro de sentido na lista
    final linhasExibidas = provider.linhas.where((l) {
      if (_filtroSentido == 1) return l.sl == 1;
      if (_filtroSentido == 2) return l.sl == 2;
      return true;
    }).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
      children: [
        // Barra de Busca e Filtros
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassSearchBar(
                controller: _buscaController,
                hintText: 'Digite o número ou nome da linha...',
                prefixIcon: Icons.directions_bus_rounded,
                isLoading: provider.carregando,
                onSubmitted: (val) => provider.buscarLinhas(val),
                onSearch: () => provider.buscarLinhas(_buscaController.text),
                onClear: () {
                  _buscaController.clear();
                  provider.buscarLinhas('');
                },
              ),
              const SizedBox(height: 8),

              // Controle Segmentado Apple HIG para Sentido (100% Responsivo no Celular)
              Container(
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(2.5),
                child: Row(
                  children: [
                    _buildSegment('Todos', 0),
                    _buildSegment('Ida (Sentido 1)', 1),
                    _buildSegment('Volta (Sentido 2)', 2),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Aviso de Erro ou Alerta
        if (provider.erro != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: GlassContainer(
              borderRadius: GlassTheme.radiusInput,
              fillOpacity: 0.12,
              borderOpacity: 0.18,
              borderColor: GlassTheme.systemOrange.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: GlassTheme.systemOrange, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      provider.erro!,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
                    onPressed: () => provider.limparErro(),
                  ),
                ],
              ),
            ),
          ),

        // Lista de Resultados com scroll suave sob a tab bar
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
                        'Buscando linhas no catálogo...',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : linhasExibidas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _buscaController.text.trim().isEmpty
                                ? Icons.search_rounded
                                : Icons.search_off_rounded,
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _buscaController.text.trim().isEmpty
                                ? 'Pesquisar Linhas'
                                : 'Nenhuma linha encontrada',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _buscaController.text.trim().isEmpty
                                ? 'Digite o número ou destino acima para pesquisar.'
                                : 'Não encontramos resultados para "${_buscaController.text.trim()}".',
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
                      itemCount: linhasExibidas.length,
                      itemBuilder: (context, index) {
                        final linha = linhasExibidas[index];
                        final isAcompanhada = provider.linhaAcompanhada?.cl == linha.cl;
                        final isFav = provider.isLinhaFavorita(linha.cl.toString());

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassContainer(
                            borderRadius: GlassTheme.radiusCard,
                            fillOpacity: isAcompanhada ? 0.16 : 0.08,
                            borderOpacity: isAcompanhada ? 0.28 : 0.12,
                            borderColor: isAcompanhada ? Colors.white.withValues(alpha: 0.35) : null,
                            withBlur: false, // Performance estrita em listas que rolam
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Cabeçalho do Card: Badge + Sentido + Favorito
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 3.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: GlassTheme.accentDarkGreen,
                                        borderRadius: BorderRadius.circular(7),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.16),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        linha.lt,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          linha.sentidoDescricao,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: Colors.white.withValues(alpha: 0.80),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    if (linha.lc) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Circular',
                                          style: GoogleFonts.inter(
                                            fontSize: 10.5,
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () {
                                        if (isFav) {
                                          provider.desfavoritarLinha(linha.cl.toString());
                                        } else {
                                          provider.favoritarLinha(linha);
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
                                Text(
                                  linha.tp,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.5,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Destino: ${linha.ts}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: GlassTheme.textTertiary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Botões em grid simétrica 50% / 50%
                                Row(
                                  children: [
                                    Expanded(
                                      child: GlassButton(
                                        label: 'Itinerário',
                                        icon: const Icon(Icons.alt_route_rounded, size: 14, color: Colors.white70),
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => LineDetailScreen(linha: linha),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: GlassButton(
                                        isPrimary: !isAcompanhada,
                                        label: isAcompanhada ? 'Acompanhando' : 'Ver no Mapa',
                                        icon: Icon(
                                          isAcompanhada ? Icons.check_rounded : Icons.map_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        onTap: () => provider.acompanharLinha(linha),
                                      ),
                                    ),
                                  ],
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

  Widget _buildSegment(String label, int value) {
    final isSelected = _filtroSentido == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filtroSentido = value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                    width: 1,
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : Colors.white60,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
