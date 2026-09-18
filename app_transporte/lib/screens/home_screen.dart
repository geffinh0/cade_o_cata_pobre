import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/linha.dart';
import '../models/veiculo.dart';
import '../providers/transporte_provider.dart';
import '../theme/glass_theme.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_text_field.dart';

/// Tela Principal da Aplicação em Vidro Líquido Neutro
///
/// Apresenta busca de linhas, mapa interativo em tempo real via OpenStreetMap,
/// monitoramento de frota ativa via WebSocket e gerenciamento de linhas favoritas.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _buscaController = TextEditingController();
  final MapController _mapController = MapController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _buscaController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _abrirDialogoServidor(BuildContext context, TransporteProvider provider) {
    final controller = TextEditingController(text: provider.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GlassTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlassTheme.radiusModal),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        title: Row(
          children: [
            Icon(Icons.dns, color: Colors.white.withValues(alpha: 0.70)),
            const SizedBox(width: 8),
            Text(
              'Configurar Servidor',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alterne o endereço do Middleware conforme o ambiente de teste:',
              style: GoogleFonts.inter(fontSize: 13, color: GlassTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                labelText: 'Base URL do Middleware',
                labelStyle: GoogleFonts.inter(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(GlassTheme.radiusInput),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(GlassTheme.radiusInput),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(GlassTheme.radiusInput),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.30)),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                prefixIcon: Icon(Icons.link, color: Colors.white.withValues(alpha: 0.50)),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                GlassButton(
                  label: 'Emulador (10.0.2.2)',
                  onTap: () => controller.text = 'http://10.0.2.2:3000',
                ),
                GlassButton(
                  label: 'Web / Localhost',
                  onTap: () => controller.text = 'http://localhost:3000',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancelar', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          GlassButton(
            isPrimary: true,
            label: 'Salvar',
            onTap: () {
              provider.atualizarServidor(controller.text);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: GlassTheme.accentForest,
                  content: Text(
                    'Servidor atualizado para: ${controller.text}',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransporteProvider>();

    return Scaffold(
      backgroundColor: GlassTheme.bgDark,
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Glass Header
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
                            Text(
                              'Cadê o Cata Pobre',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              'Rastreamento de Ônibus em Tempo Real',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: GlassTheme.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge de status
                      GlassContainer(
                        borderRadius: GlassTheme.radiusPill,
                        fillOpacity: 0.08,
                        borderOpacity: 0.14,
                        blurSigma: 0,
                        withBlur: false,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6.5,
                              height: 6.5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: provider.conectado
                                    ? GlassTheme.systemGreen
                                    : GlassTheme.systemRed,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              provider.conectado ? 'Conectado' : 'Offline',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.90),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _abrirDialogoServidor(context, provider),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Icon(
                            Icons.settings_rounded,
                            color: Colors.white.withValues(alpha: 0.60),
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Glass Tab Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: GlassContainer(
                  borderRadius: GlassTheme.radiusPill,
                  fillOpacity: 0.06,
                  borderOpacity: 0.12,
                  blurSigma: 0,
                  withBlur: false,
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
                    labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.search_rounded, size: 16),
                        text: 'Linhas (${provider.linhas.length})',
                      ),
                      Tab(
                        icon: Badge(
                          isLabelVisible: provider.veiculos.isNotEmpty,
                          label: Text(
                            '${provider.veiculos.length}',
                            style: const TextStyle(fontSize: 9),
                          ),
                          child: const Icon(Icons.map_rounded, size: 16),
                        ),
                        text: 'Tempo Real',
                      ),
                      Tab(
                        icon: Badge(
                          isLabelVisible: provider.favoritos.isNotEmpty,
                          label: Text(
                            '${provider.favoritos.length}',
                            style: const TextStyle(fontSize: 9),
                          ),
                          child: const Icon(Icons.star_rounded, size: 16),
                        ),
                        text: 'Favoritos',
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
                    _construirAbaBusca(context, provider),
                    _construirAbaMapaETempoReal(context, provider),
                    _construirAbaFavoritos(context, provider),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirAbaBusca(BuildContext context, TransporteProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra de pesquisa em vidro
          Row(
            children: [
              Expanded(
                child: GlassTextField(
                  controller: _buscaController,
                  hintText: 'Buscar linha por número ou nome...',
                  prefixIcon: Icons.search_rounded,
                  suffixIcon: _buscaController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                          onPressed: () {
                            _buscaController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  onSubmitted: (val) => provider.buscarLinhas(val),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              GlassContainer(
                borderRadius: GlassTheme.radiusInput,
                fillOpacity: 0.12,
                borderOpacity: 0.18,
                blurSigma: 0,
                withBlur: false,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                onTap: provider.carregando ? null : () => provider.buscarLinhas(_buscaController.text),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (provider.carregando)
                      const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else ...[
                      const Icon(Icons.search_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Buscar',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Mensagem de erro
          if (provider.erro != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassContainer(
                borderRadius: GlassTheme.radiusInput,
                fillOpacity: 0.12,
                borderOpacity: 0.18,
                borderColor: GlassTheme.systemOrange.withValues(alpha: 0.4),
                blurSigma: 0,
                withBlur: false,
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

          // Lista de resultados
          Expanded(
            child: provider.linhas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_bus_filled_outlined,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          provider.carregando
                              ? 'Consultando linhas no middleware...'
                              : 'Digite um termo e clique em "Buscar"',
                          style: GoogleFonts.inter(
                            color: GlassTheme.textTertiary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: provider.linhas.length,
                    itemBuilder: (ctx, index) {
                      final linha = provider.linhas[index];
                      final isAcompanhada = provider.linhaAcompanhada?.cl == linha.cl;
                      final isFav = provider.isFavorito(linha.cl.toString());

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassContainer(
                          borderRadius: GlassTheme.radiusCard,
                          fillOpacity: isAcompanhada ? 0.16 : 0.08,
                          borderOpacity: isAcompanhada ? 0.28 : 0.12,
                          borderColor: isAcompanhada ? Colors.white.withValues(alpha: 0.35) : null,
                          withBlur: false,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cabeçalho
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: GlassTheme.accentDarkGreen,
                                      borderRadius: BorderRadius.circular(7),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.16),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      linha.lt.split('-').first,
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
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Linha ${linha.cl} • ${linha.sentidoDescricao}',
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
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                                        provider.desfavoritar(linha.cl.toString());
                                      } else {
                                        provider.favoritar(linha);
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
                              GlassButton(
                                isPrimary: !isAcompanhada,
                                label: isAcompanhada ? 'Acompanhando' : 'Acompanhar no Mapa',
                                icon: Icon(
                                  isAcompanhada ? Icons.check_rounded : Icons.map_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                onTap: () {
                                  provider.acompanharLinha(linha);
                                  _tabController.animateTo(1);
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
    );
  }

  Widget _construirAbaMapaETempoReal(BuildContext context, TransporteProvider provider) {
    final linha = provider.linhaAcompanhada;
    final veiculos = provider.veiculos;

    if (linha == null) {
      return Center(
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
                Icon(Icons.map_outlined, size: 48, color: Colors.white.withValues(alpha: 0.25)),
                const SizedBox(height: 12),
                Text(
                  'Nenhuma linha sendo acompanhada',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pesquise uma linha na aba "Linhas" ou selecione em "Favoritos" para receber atualizações por WebSocket.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: GlassTheme.textTertiary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                GlassButton(
                  isPrimary: true,
                  label: 'Buscar Linhas',
                  icon: const Icon(Icons.search_rounded, size: 14, color: Colors.white),
                  onTap: () => _tabController.animateTo(0),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Calcula o ponto central com base nos ônibus ou centro de SP
    LatLng centroMapa = const LatLng(-23.55052, -46.633308);
    if (veiculos.isNotEmpty && veiculos.first.py != 0.0 && veiculos.first.px != 0.0) {
      centroMapa = LatLng(veiculos.first.py, veiculos.first.px);
    }

    // Marcadores dos veículos
    final marcadores = veiculos.map((v) {
      return Marker(
        point: LatLng(v.py, v.px),
        width: 60,
        height: 60,
        child: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (ctx) => _detalheVeiculoBottomSheet(v, linha),
            );
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: GlassTheme.surfaceDark.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                ),
                child: Text(
                  v.p,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.directions_bus_rounded,
                color: GlassTheme.accentPine,
                size: 30,
              ),
            ],
          ),
        ),
      );
    }).toList();

    final df = DateFormat('HH:mm:ss');
    final horaAtualizacao = provider.ultimaAtualizacao != null
        ? df.format(provider.ultimaAtualizacao!)
        : 'Aguardando telemetria...';

    return Column(
      children: [
        // Painel de informações da linha em vidro
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: GlassContainer(
            borderRadius: GlassTheme.radiusCard,
            fillOpacity: 0.10,
            borderOpacity: 0.14,
            blurSigma: 0,
            withBlur: false,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: GlassTheme.accentDarkGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              linha.lt,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              linha.tp,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${veiculos.length} veículos ativos • Atualizado às $horaAtualizacao',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: GlassTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _mapController.move(centroMapa, 13.0),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Icon(Icons.my_location, color: Colors.white.withValues(alpha: 0.60), size: 16),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => provider.pararAcompanhamento(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: GlassTheme.systemRed.withValues(alpha: 0.15),
                      border: Border.all(color: GlassTheme.systemRed.withValues(alpha: 0.30)),
                    ),
                    child: const Icon(Icons.close_rounded, color: GlassTheme.systemRed, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Mapa Interativo
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(GlassTheme.radiusCard),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: centroMapa,
                  initialZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app_transporte',
                  ),
                  MarkerLayer(markers: marcadores),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Lista de veículos ativos
        Expanded(
          flex: 2,
          child: veiculos.isEmpty
              ? Center(
                  child: Text(
                    'Aguardando dados dos veículos pelo canal Socket.IO...',
                    style: GoogleFonts.inter(color: GlassTheme.textTertiary, fontSize: 13),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: veiculos.length,
                  itemBuilder: (ctx, index) {
                    final v = veiculos[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: GlassContainer(
                        borderRadius: GlassTheme.radiusInput,
                        fillOpacity: 0.06,
                        borderOpacity: 0.10,
                        blurSigma: 0,
                        withBlur: false,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: GlassTheme.accentDarkGreen.withValues(alpha: 0.30),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                              ),
                              child: const Icon(Icons.directions_bus, size: 14, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Prefixo: ${v.p}',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '(${v.py.toStringAsFixed(4)}, ${v.px.toStringAsFixed(4)})',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: GlassTheme.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (v.a)
                              Tooltip(
                                message: 'Veículo Acessível',
                                child: Icon(
                                  Icons.accessible,
                                  size: 16,
                                  color: Colors.white.withValues(alpha: 0.50),
                                ),
                              ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _mapController.move(LatLng(v.py, v.px), 15.0),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.08),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                                ),
                                child: Icon(
                                  Icons.center_focus_strong,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.60),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _detalheVeiculoBottomSheet(Veiculo v, Linha linha) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: GlassContainer(
          borderRadius: GlassTheme.radiusModal,
          blurSigma: GlassTheme.blurOverlay,
          fillOpacity: GlassTheme.fillOverlay,
          borderOpacity: GlassTheme.borderHighlight,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: GlassTheme.accentDarkGreen.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                    ),
                    child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ônibus Prefixo ${v.p}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${linha.lt} - ${linha.tp}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: GlassTheme.textTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
              const SizedBox(height: 14),
              _infoRow('Latitude', '${v.py}'),
              const SizedBox(height: 6),
              _infoRow('Longitude', '${v.px}'),
              const SizedBox(height: 6),
              _infoRow('Acessibilidade', v.a ? 'Sim (Elevador)' : 'Não'),
              if (v.ta.isNotEmpty) ...[
                const SizedBox(height: 6),
                _infoRow('Timestamp', v.ta),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirAbaFavoritos(BuildContext context, TransporteProvider provider) {
    final favoritos = provider.favoritos;

    if (favoritos.isEmpty) {
      return Center(
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
                Icon(Icons.star_outline_rounded, size: 46, color: Colors.white.withValues(alpha: 0.25)),
                const SizedBox(height: 12),
                Text(
                  'Nenhuma linha favoritada ainda',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Clique no ícone de estrela de uma linha para salvá-la aqui.',
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: favoritos.length,
      itemBuilder: (ctx, index) {
        final item = favoritos[index];
        final codigoLinha = item['codigo_linha'] ?? '';
        final descricao = item['descricao'] ?? '';
        final letreiro = item['letreiro'] ?? codigoLinha;
        final isAcompanhada = provider.linhaAcompanhada?.cl.toString() == codigoLinha;

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
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
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
                        descricao,
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
                      onTap: () => provider.desfavoritar(codigoLinha),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white54,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GlassButton(
                  isPrimary: !isAcompanhada,
                  label: isAcompanhada ? 'Ativa' : 'Acompanhar no Mapa',
                  icon: Icon(
                    isAcompanhada ? Icons.check_rounded : Icons.map_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  onTap: () {
                    final l = Linha(
                      cl: int.tryParse(codigoLinha) ?? 0,
                      lc: false,
                      lt: letreiro,
                      sl: 1,
                      tl: 10,
                      tp: descricao,
                      ts: '',
                    );
                    provider.acompanharLinha(l);
                    _tabController.animateTo(1);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
