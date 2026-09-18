import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/linha.dart';
import '../models/parada.dart';
import '../providers/transporte_provider.dart';
import '../services/api_service.dart';
import '../theme/glass_theme.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_container.dart';
import '../widgets/previsao_modal.dart';

/// Tela de Detalhes e Itinerário Completo da Linha em Vidro Líquido Neutro
class LineDetailScreen extends StatefulWidget {
  final Linha linha;

  const LineDetailScreen({super.key, required this.linha});

  @override
  State<LineDetailScreen> createState() => _LineDetailScreenState();
}

class _LineDetailScreenState extends State<LineDetailScreen> {
  List<Parada> _paradas = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarParadas();
  }

  Future<void> _carregarParadas() async {
    final apiService = ApiService(
      baseUrl: context.read<TransporteProvider>().baseUrl,
    );
    try {
      final resultado = await apiService.buscarParadasPorLinha(
        widget.linha.cl,
        routeId: widget.linha.routeId,
        letreiro: widget.linha.lt,
      );
      if (mounted) {
        setState(() {
          _paradas = resultado;
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransporteProvider>();
    final isAcompanhada = provider.linhaAcompanhada?.cl == widget.linha.cl;
    final isFav = provider.isLinhaFavorita(widget.linha.cl.toString());

    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Glass Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: GlassContainer(
                  borderRadius: GlassTheme.radiusCard,
                  blurSigma: GlassTheme.blurSurface,
                  fillOpacity: GlassTheme.fillSurface,
                  borderOpacity: GlassTheme.borderDefault,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${widget.linha.lt} • Itinerário',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: isFav ? 'Remover dos favoritos' : 'Favoritar linha',
                        icon: Icon(
                          isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: isFav ? GlassTheme.systemOrange : Colors.white60,
                          size: 24,
                        ),
                        onPressed: () {
                          if (isFav) {
                            provider.desfavoritarLinha(widget.linha.cl.toString());
                          } else {
                            provider.favoritarLinha(widget.linha);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Banner de cabeçalho da linha
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: GlassContainer(
                  borderRadius: GlassTheme.radiusCard,
                  blurSigma: 14,
                  fillOpacity: 0.10,
                  borderOpacity: 0.14,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: GlassTheme.accentDarkGreen,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                            ),
                            child: Text(
                              widget.linha.lt,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.linha.tp,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.5,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Destino: ${widget.linha.ts}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: GlassTheme.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.linha.sentidoDescricao,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (widget.linha.lc) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Linha Circular',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Título da lista de paradas
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Paradas Atendidas (${_paradas.length})',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (_carregando)
                      const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                  ],
                ),
              ),

              // Lista de Paradas em Linha do Tempo
              Expanded(
                child: _carregando
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : _paradas.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                'Nenhuma parada registrada para esta linha.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: GlassTheme.textTertiary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            itemCount: _paradas.length,
                            itemBuilder: (context, index) {
                              final parada = _paradas[index];
                              final isFirst = index == 0;
                              final isLast = index == _paradas.length - 1;
                              final isTerminal = isFirst || isLast;

                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Coluna da timeline (linha + círculo)
                                    SizedBox(
                                      width: 40,
                                      child: Column(
                                        children: [
                                          // Conector superior
                                          Expanded(
                                            flex: 1,
                                            child: Container(
                                              width: isFirst ? 0 : 2.5,
                                              decoration: BoxDecoration(
                                                gradient: isFirst
                                                    ? null
                                                    : LinearGradient(
                                                        begin: Alignment.topCenter,
                                                        end: Alignment.bottomCenter,
                                                        colors: [
                                                          Colors.white.withValues(alpha: 0.08),
                                                          Colors.white.withValues(alpha: 0.18),
                                                        ],
                                                      ),
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                          ),
                                          // Indicador numérico circular
                                          Container(
                                            width: isTerminal ? 28 : 22,
                                            height: isTerminal ? 28 : 22,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: isTerminal
                                                  ? const LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                      colors: [
                                                        Color(0xFF3D8B63),
                                                        Color(0xFF264E36),
                                                      ],
                                                    )
                                                  : null,
                                              color: isTerminal ? null : const Color(0xFF1B2620),
                                              border: Border.all(
                                                color: isTerminal
                                                    ? Colors.white.withValues(alpha: 0.50)
                                                    : Colors.white.withValues(alpha: 0.22),
                                                width: isTerminal ? 2.0 : 1.5,
                                              ),
                                              boxShadow: isTerminal
                                                  ? [
                                                      BoxShadow(
                                                        color: const Color(0xFF3D8B63)
                                                            .withValues(alpha: 0.25),
                                                        blurRadius: 8,
                                                        spreadRadius: 1,
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            alignment: Alignment.center,
                                            child: isTerminal
                                                ? Icon(
                                                    isFirst
                                                        ? Icons.play_arrow_rounded
                                                        : Icons.flag_rounded,
                                                    size: 14,
                                                    color: Colors.white,
                                                  )
                                                : Text(
                                                    '${index + 1}',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w700,
                                                      color: Colors.white.withValues(alpha: 0.65),
                                                    ),
                                                  ),
                                          ),
                                          // Conector inferior
                                          Expanded(
                                            flex: 1,
                                            child: Container(
                                              width: isLast ? 0 : 2.5,
                                              decoration: BoxDecoration(
                                                gradient: isLast
                                                    ? null
                                                    : LinearGradient(
                                                        begin: Alignment.topCenter,
                                                        end: Alignment.bottomCenter,
                                                        colors: [
                                                          Colors.white.withValues(alpha: 0.18),
                                                          Colors.white.withValues(alpha: 0.08),
                                                        ],
                                                      ),
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Card da parada
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: GlassContainer(
                                          borderRadius: isTerminal
                                              ? GlassTheme.radiusCard
                                              : GlassTheme.radiusInput,
                                          fillOpacity: isTerminal ? 0.12 : 0.06,
                                          borderOpacity: isTerminal ? 0.18 : 0.10,
                                          borderColor: isTerminal
                                              ? Colors.white.withValues(alpha: 0.22)
                                              : null,
                                          withBlur: false,
                                          padding: EdgeInsets.all(isTerminal ? 14 : 10),
                                          child: Row(
                                            children: [
                                              if (isTerminal)
                                                Container(
                                                  margin: const EdgeInsets.only(right: 10),
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: GlassTheme.accentDarkGreen
                                                        .withValues(alpha: 0.30),
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(
                                                      color: Colors.white.withValues(alpha: 0.12),
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    isFirst
                                                        ? Icons.trip_origin_rounded
                                                        : Icons.place_rounded,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    if (isTerminal)
                                                      Padding(
                                                        padding: const EdgeInsets.only(bottom: 2),
                                                        child: Text(
                                                          isFirst ? 'PARTIDA' : 'DESTINO FINAL',
                                                          style: GoogleFonts.inter(
                                                            fontSize: 9.5,
                                                            fontWeight: FontWeight.w700,
                                                            color: const Color(0xFF5EBD85),
                                                            letterSpacing: 1.2,
                                                          ),
                                                        ),
                                                      ),
                                                    Text(
                                                      parada.np,
                                                      style: GoogleFonts.inter(
                                                        fontWeight:
                                                            isTerminal ? FontWeight.w700 : FontWeight.w600,
                                                        fontSize: isTerminal ? 14 : 13,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Ponto ${parada.cp}',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        color: GlassTheme.textTertiary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.access_time_rounded,
                                                  color: Colors.white.withValues(alpha: 0.55),
                                                  size: 18,
                                                ),
                                                tooltip: 'Ver previsões neste ponto',
                                                onPressed: () {
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
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),

              // Botão Inferior de Acompanhar Linha com margem segura para mobile
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: GlassButton(
                  isPrimary: !isAcompanhada,
                  width: double.infinity,
                  label: isAcompanhada ? 'Acompanhando no Mapa ao Vivo' : 'Acompanhar Linha no Mapa',
                  icon: Icon(
                    isAcompanhada ? Icons.check_circle_rounded : Icons.map_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                  onTap: () {
                    provider.acompanharLinha(widget.linha);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
