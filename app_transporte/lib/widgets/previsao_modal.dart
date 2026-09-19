import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/parada.dart';
import '../models/previsao.dart';
import '../providers/transporte_provider.dart';
import '../theme/glass_theme.dart';
import 'glass_container.dart';

/// Modal em Vidro Líquido Neutro (Padrão Apple HIG - Nível 3 Overlay)
/// Exibe previsões de chegada (ETA) da parada em tempo real com reatividade direta.
class PrevisaoModalWidget extends StatelessWidget {
  final Parada parada;
  final VoidCallback onFechar;

  // Parâmetros opcionais para retrocompatibilidade
  final Previsao? previsao;
  final bool? carregando;

  const PrevisaoModalWidget({
    super.key,
    required this.parada,
    required this.onFechar,
    this.previsao,
    this.carregando,
  });

  @override
  Widget build(BuildContext context) {
    // Escuta o provider diretamente para atualizar a interface assim que a resposta chegar
    final provider = context.watch<TransporteProvider>();
    final estaCarregando = provider.carregandoPrevisao;
    final dadosPrevisao = provider.previsaoParada ?? previsao;
    final isFav = provider.isParadaFavorita(parada.cp);

    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 580,
              maxHeight: MediaQuery.of(context).size.height * 0.82,
            ),
            child: GlassContainer(
            borderRadius: GlassTheme.radiusModal, // 24.0 (Overlay)
            blurSigma: GlassTheme.blurOverlay,    // 25.0
            fillOpacity: GlassTheme.fillOverlay,  // 0.16 (16%)
            borderOpacity: GlassTheme.borderHighlight, // 0.18 (18%)
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de arraste minimalista
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Cabeçalho da parada
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: GlassTheme.accentDarkGreen.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parada.np,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ponto ${parada.cp}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: GlassTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isFav ? 'Remover dos favoritos' : 'Favoritar parada',
                  icon: Icon(
                    isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isFav ? GlassTheme.systemOrange : Colors.white60,
                    size: 24,
                  ),
                  onPressed: () {
                    if (isFav) {
                      provider.desfavoritarParada(parada.cp);
                    } else {
                      provider.favoritarParada(parada);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: onFechar,
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Próximas Chegadas Previstas',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                if (estaCarregando)
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
            const SizedBox(height: 10),

            // Conteúdo das previsões
            Flexible(
              child: estaCarregando && dadosPrevisao == null
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Consultando telemetria ao vivo...',
                              style: TextStyle(color: Colors.white60, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    )
                  : (dadosPrevisao == null || dadosPrevisao.l.isEmpty)
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_off_outlined,
                                size: 34,
                                color: Colors.white.withValues(alpha: 0.30),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Nenhuma previsão transmitida para este ponto no momento.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: dadosPrevisao.l.length,
                          separatorBuilder: (_, index) => Divider(
                            color: Colors.white.withValues(alpha: 0.06),
                            height: 12,
                          ),
                          itemBuilder: (context, index) {
                            final linhaPrev = dadosPrevisao.l[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: GlassTheme.accentDarkGreen,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          linhaPrev.c,
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: linhaPrev.sl == 2
                                              ? const Color(0xFF112233)
                                              : const Color(0xFF13281C),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: linhaPrev.sl == 2
                                                ? const Color(0xFF2A557A)
                                                : const Color(0xFF2D613F),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              linhaPrev.sl == 2
                                                  ? Icons.arrow_back_rounded
                                                  : Icons.arrow_forward_rounded,
                                              size: 11,
                                              color: linhaPrev.sl == 2
                                                  ? const Color(0xFF64B5F6)
                                                  : const Color(0xFF4ADE80),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              linhaPrev.sl == 2 ? 'VOLTA' : 'IDA',
                                              style: GoogleFonts.inter(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                color: linhaPrev.sl == 2
                                                    ? const Color(0xFF64B5F6)
                                                    : const Color(0xFF4ADE80),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${linhaPrev.vs.length} em aproximação',
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          color: Colors.white60,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: linhaPrev.vs.map((v) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.07),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.12),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.access_time_rounded,
                                              size: 13,
                                              color: Colors.white70,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              v.t,
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '(Ônibus ${v.p})',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: Colors.white54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
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
