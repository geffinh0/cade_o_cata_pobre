import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/transporte_provider.dart';
import '../theme/glass_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_text_field.dart';

/// Painel de Observabilidade e Fundamentação Teórica de Sistemas Distribuídos (APS) em Vidro Líquido Neutro
class SystemMetricsScreen extends StatefulWidget {
  const SystemMetricsScreen({super.key});

  @override
  State<SystemMetricsScreen> createState() => _SystemMetricsScreenState();
}

class _SystemMetricsScreenState extends State<SystemMetricsScreen> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<TransporteProvider>();
    _urlController.text = provider.baseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _aplicarUrl(TransporteProvider provider, String url) {
    provider.atualizarServidor(url);
    _urlController.text = url;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: GlassTheme.accentForest,
        content: Text(
          'Servidor atualizado para: $url',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransporteProvider>();
    final metricas = provider.metricas;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        // 1. Card de Telemetria do Cliente e Latência
        _construirCardCliente(provider),
        const SizedBox(height: 12),

        // 2. Card de Métricas do Middleware
        _construirCardMiddleware(provider, metricas),
        const SizedBox(height: 12),

        // 3. Card de Configuração de Rede do Servidor
        _construirCardConfiguracao(provider),
        const SizedBox(height: 12),

        // 4. Card Didático: Conceitos de Sistemas Distribuídos
        _construirCardFundamentacaoTeorica(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _construirCardCliente(TransporteProvider provider) {
    final conectado = provider.conectado;
    final lat = provider.latenciaMs;
    final eventos = provider.totalEventosRecebidos;

    // Cor funcional da latência (uso legítimo de cores de sistema para status)
    Color corLat = GlassTheme.systemRed;
    if (conectado) {
      if (lat > 0 && lat < 60) {
        corLat = GlassTheme.systemGreen;
      } else if (lat >= 60 && lat < 150) {
        corLat = GlassTheme.systemOrange;
      }
    }

    return GlassContainer(
      borderRadius: GlassTheme.radiusCard,
      fillOpacity: 0.10,
      borderOpacity: 0.18,
      withBlur: false,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (conectado ? GlassTheme.accentDarkGreen : GlassTheme.systemRed)
                      .withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (conectado ? GlassTheme.accentDarkGreen : GlassTheme.systemRed)
                        .withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  conectado ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                  color: conectado ? GlassTheme.systemGreen : GlassTheme.systemRed,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Canal WebSocket (Socket.IO)',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      conectado ? 'Conexão bidirecional ativa • Push em tempo real' : 'Desconectado do servidor',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: conectado ? GlassTheme.textSecondary : GlassTheme.systemRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              GlassButton(
                label: 'Ping',
                icon: const Icon(Icons.refresh_rounded, size: 14, color: Colors.white),
                onTap: () => provider.atualizarMetricas(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.10), height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _indicadorMetrica(
                  titulo: 'Latência RTT',
                  valor: conectado ? (lat > 0 ? '$lat ms' : '< 10 ms') : '--',
                  corValor: corLat,
                  subtitulo: 'Ping/Pong cliente-servidor',
                ),
              ),
              Container(
                width: 1,
                height: 44,
                color: Colors.white.withValues(alpha: 0.10),
              ),
              Expanded(
                child: _indicadorMetrica(
                  titulo: 'Eventos Push',
                  valor: '$eventos',
                  corValor: Colors.white,
                  subtitulo: 'Telemetria recebida',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construirCardMiddleware(TransporteProvider provider, dynamic metricas) {
    return GlassContainer(
      borderRadius: GlassTheme.radiusCard,
      fillOpacity: 0.10,
      borderOpacity: 0.18,
      withBlur: false,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.dns_rounded, color: Colors.white.withValues(alpha: 0.70), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Servidor Intermediário (Middleware)',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (metricas != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (metricas.autenticado ? GlassTheme.accentDarkGreen : GlassTheme.systemRed)
                        .withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (metricas.autenticado ? GlassTheme.accentDarkGreen : GlassTheme.systemRed)
                          .withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        metricas.autenticado ? Icons.verified_rounded : Icons.error_outline,
                        size: 12,
                        color: metricas.autenticado ? GlassTheme.systemGreen : GlassTheme.systemRed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        metricas.autenticado ? 'API Real (Produção)' : 'Aguardando Sinc SPTrans',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: metricas.autenticado ? Colors.white : GlassTheme.systemRed,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withValues(alpha: 0.10), height: 1),
          const SizedBox(height: 14),
          if (metricas == null)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: Text(
                'Métricas indisponíveis. Verifique se o middleware está ativo em http://localhost:3000.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _itemDashboard(
                    'Clientes Conectados',
                    '${metricas.clientesConectadosAgora}',
                    Icons.people_outline,
                  ),
                ),
                Expanded(
                  child: _itemDashboard(
                    'Tópicos Assinados',
                    '${metricas.linhasAcompanhadasAgora}',
                    Icons.alt_route_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _itemDashboard(
                    'Broadcasts Emitidos',
                    '${metricas.totalPushesEmitidos}',
                    Icons.cell_tower_rounded,
                  ),
                ),
                Expanded(
                  child: _itemDashboard(
                    'Polls na Origem',
                    '${metricas.totalPollsRealizados}',
                    Icons.sync_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _itemDashboard(
                    'Cache Gateway',
                    '${metricas.totalItensEmCache} itens',
                    Icons.cached_rounded,
                  ),
                ),
                Expanded(
                  child: _itemDashboard(
                    'Tempo de Atividade',
                    metricas.tempoAtividadeFormatado,
                    Icons.timer_outlined,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirCardConfiguracao(TransporteProvider provider) {
    return GlassContainer(
      borderRadius: GlassTheme.radiusCard,
      fillOpacity: 0.10,
      borderOpacity: 0.18,
      withBlur: false,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings_ethernet_rounded, color: Colors.white.withValues(alpha: 0.70), size: 20),
              const SizedBox(width: 8),
              Text(
                'Endereço de Rede do Servidor',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GlassTextField(
            controller: _urlController,
            hintText: 'http://localhost:3000 ou IP do host',
            prefixIcon: Icons.lan_rounded,
            suffixIcon: IconButton(
              icon: Icon(Icons.check_rounded, color: Colors.white.withValues(alpha: 0.70)),
              tooltip: 'Aplicar URL',
              onPressed: () => _aplicarUrl(provider, _urlController.text),
            ),
            onSubmitted: (val) => _aplicarUrl(provider, val),
          ),
          const SizedBox(height: 12),
          Text(
            'Atalhos de conexão rápida:',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              GlassButton(
                label: 'localhost:3000 (Windows/Web)',
                onTap: () => _aplicarUrl(provider, 'http://localhost:3000'),
              ),
              GlassButton(
                label: '10.0.2.2:3000 (Emulador)',
                onTap: () => _aplicarUrl(provider, 'http://10.0.2.2:3000'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construirCardFundamentacaoTeorica() {
    return GlassContainer(
      borderRadius: GlassTheme.radiusCard,
      fillOpacity: 0.10,
      borderOpacity: 0.18,
      withBlur: false,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_rounded, color: Colors.white.withValues(alpha: 0.70), size: 20),
              const SizedBox(width: 8),
              Text(
                'Fundamentação: Sistemas Distribuídos (APS)',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _topicoTeorico(
            numero: '1',
            titulo: 'Padrão API Gateway e Intermediador',
            descricao:
                'O cliente móvel não consome a API da SPTrans diretamente. O Middleware Node.js atua como Gateway centralizando credenciais, isolando falhas externas e convertendo formatos de rede.',
          ),
          const SizedBox(height: 12),
          _topicoTeorico(
            numero: '2',
            titulo: 'Paradigma Publish/Subscribe (Pub/Sub)',
            descricao:
                'Clientes não realizam polling pesado. O app assina o canal da linha (subscribe) e o middleware distribui mensagens via eventos WebSocket (push) de forma assíncrona.',
          ),
          const SizedBox(height: 12),
          _topicoTeorico(
            numero: '3',
            titulo: 'Mitigação de Gargalos e Polling Agregado',
            descricao:
                'Mesmo com milhares de passageiros simultâneos na linha 8000-10, o Poller do middleware faz apenas 1 requisição periódica à SPTrans e transmite a cópia a todos os clientes conectados (resolvendo o problema C10K).',
          ),
          const SizedBox(height: 12),
          _topicoTeorico(
            numero: '4',
            titulo: 'Reautenticação e Resiliência de Sessão',
            descricao:
                'A sessão com a SPTrans expira com frequência. O middleware intercepta erros 401 e renova os cookies automaticamente com retry exponencial, garantindo tolerância a falhas.',
          ),
        ],
      ),
    );
  }

  Widget _indicadorMetrica({
    required String titulo,
    required String valor,
    required Color corValor,
    required String subtitulo,
  }) {
    return Column(
      children: [
        Text(
          titulo,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: corValor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitulo,
          style: GoogleFonts.inter(fontSize: 10, color: Colors.white38),
        ),
      ],
    );
  }

  /// Dashboard item neutro — paleta monocromática uniforme (sem cores por métrica)
  Widget _itemDashboard(String titulo, String valor, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.50)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white60),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  valor,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topicoTeorico({
    required String numero,
    required String titulo,
    required String descricao,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
          ),
          child: Text(
            numero,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.70),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                descricao,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
