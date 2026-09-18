import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/linha.dart';
import '../models/veiculo.dart';
import '../theme/glass_theme.dart';
import 'glass_button.dart';
import 'glass_container.dart';

/// Modal com telemetria detalhada de um veículo selecionado — Layout Premium
class PainelVeiculoDetalheWidget extends StatelessWidget {
  final Veiculo veiculo;
  final Linha linha;
  final bool isSeguindo;
  final VoidCallback onAlternarSeguir;
  final VoidCallback onFechar;

  const PainelVeiculoDetalheWidget({
    super.key,
    required this.veiculo,
    required this.linha,
    required this.isSeguindo,
    required this.onAlternarSeguir,
    required this.onFechar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      child: GlassContainer(
        borderRadius: GlassTheme.radiusModal, // 24
        blurSigma: GlassTheme.blurOverlay,    // 25
        fillOpacity: GlassTheme.fillOverlay,  // 0.16
        borderOpacity: GlassTheme.borderHighlight, // 0.18
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de arraste
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF3D8B63),
                        Color(0xFF264E36),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D5A42).withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ônibus ${veiculo.p}',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        '${linha.lt} • ${linha.tp}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: GlassTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: onFechar,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
            const SizedBox(height: 18),

            // Informações de telemetria em grid de cards
            _itemInfo(
              icon: Icons.accessible_forward_rounded,
              titulo: 'Acessibilidade PMR',
              valor: veiculo.a ? 'Equipado com Elevador' : 'Padrão (Sem Elevador)',
              corIcone: veiculo.a ? GlassTheme.systemGreen : Colors.white54,
              corFundo: veiculo.a
                  ? GlassTheme.systemGreen.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.06),
            ),
            const SizedBox(height: 10),
            _itemInfo(
              icon: Icons.navigation_rounded,
              titulo: 'Coordenadas GPS',
              valor: 'Lat ${veiculo.py.toStringAsFixed(5)}, Lon ${veiculo.px.toStringAsFixed(5)}',
              corIcone: const Color(0xFF5EBD85),
              corFundo: const Color(0xFF5EBD85).withValues(alpha: 0.08),
            ),
            const SizedBox(height: 10),
            _itemInfo(
              icon: Icons.access_time_rounded,
              titulo: 'Horário do Pacote',
              valor: veiculo.ta.isNotEmpty ? veiculo.ta : 'Recebido via WebSocket Push',
              corIcone: Colors.white70,
              corFundo: Colors.white.withValues(alpha: 0.06),
            ),

            const SizedBox(height: 22),

            // Botão de ação
            SizedBox(
              width: double.infinity,
              child: GlassButton(
                isPrimary: true,
                label: isSeguindo ? 'Câmera Travada no Veículo' : 'Seguir este Ônibus no Mapa',
                icon: Icon(
                  isSeguindo ? Icons.videocam_rounded : Icons.navigation_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                onTap: onAlternarSeguir,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemInfo({
    required IconData icon,
    required String titulo,
    required String valor,
    required Color corIcone,
    required Color corFundo,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: corIcone.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: corIcone.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: corIcone),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.50),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  valor,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
