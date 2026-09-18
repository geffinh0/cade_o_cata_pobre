import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/linha.dart';
import '../providers/transporte_provider.dart';
import '../theme/glass_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/mapa_controles.dart';
import '../widgets/painel_veiculo_detalhe.dart';
import '../widgets/parada_marker.dart';
import '../widgets/previsao_modal.dart';
import '../widgets/user_location_marker.dart';
import '../widgets/veiculo_marker.dart';

/// Tela de Mapa Interativo de Alta Performance e Fluidez
///
/// Principais capacidades:
/// - Animações suaves de câmera (animated pan & zoom) com curvas elásticas.
/// - Tiles ultrarrápidos CartoDB Dark Matter, Voyager, Satélite e OSM com CDN balanceado.
/// - Mapa sempre ativo e navegável (nunca tela em branco), com busca flutuante e atalhos rápidos.
/// - Level-of-Detail (LOD) adaptativo para paradas e ônibus evitando quedas de FPS.
/// - Gestos inteligentes que desacoplam o modo seguir ao arrastar a tela.
/// - Layout totalmente responsivo com proteção de insets e carrossel retrátil.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  AnimationController? _animationController;

  double _currentZoom = 13.0;
  double _currentRotation = 0.0;
  bool _carrosselExpandido = true;
  bool _mapaPronto = false;

  // Centro padrão: Avenida Paulista / Sé - São Paulo
  static const LatLng _centroSaoPaulo = LatLng(-23.55052, -46.633308);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransporteProvider>().obterLocalizacaoAtual();
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  /// Executa movimento suave e interpolado de câmera
  void _animatedMapMove(LatLng destLocation, double destZoom, {double? destRotation}) {
    _animationController?.stop();
    _animationController?.dispose();

    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final startRotation = _mapController.camera.rotation;
    final targetRotation = destRotation ?? startRotation;
    final rotTween = Tween<double>(
      begin: startRotation,
      end: targetRotation,
    );

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 480),
      vsync: this,
    );

    final animation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.fastOutSlowIn,
    );

    _animationController!.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
      if (destRotation != null) {
        _mapController.rotate(rotTween.evaluate(animation));
      }
    });

    _animationController!.forward();
  }

  void _ajustarCameraParaLinha(TransporteProvider provider) {
    final trajeto = provider.trajetoLinhaAcompanhada;
    final veiculos = provider.veiculos;

    if (trajeto != null && trajeto.pontos.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(trajeto.pontos);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(40, 110, 40, 170),
        ),
      );
    } else if (veiculos.isNotEmpty) {
      final pontos = veiculos.map((v) => LatLng(v.py, v.px)).toList();
      final bounds = LatLngBounds.fromPoints(pontos);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(40, 110, 40, 170),
        ),
      );
    } else {
      _animatedMapMove(_centroSaoPaulo, 13.0);
    }
  }

  String _obterUrlTemplate(String estilo) {
    if (estilo == 'satelite') {
      // Satélite Real (100% gratuito e sem chave de API)
      return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
    // OpenStreetMap Standard (100% gratuito e sem chave de API)
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  List<String> _obterSubdominios(String estilo) {
    if (estilo == 'satelite') return const [];
    return const ['a', 'b', 'c'];
  }

  void _abrirModalBuscaRapida(BuildContext context, TransporteProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _ModalBuscaRapidaLinhas(
          provider: provider,
          onLinhaSelecionada: (linha) {
            Navigator.of(ctx).pop();
            provider.acompanharLinha(linha);
            Future.delayed(const Duration(milliseconds: 350), () {
              if (mounted) _ajustarCameraParaLinha(provider);
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransporteProvider>();
    final linha = provider.linhaAcompanhada;
    final veiculos = provider.veiculos;
    final trajeto = provider.trajetoLinhaAcompanhada;
    final paradas = provider.paradasLinhaAcompanhada;

    // Se o modo de seguir veículo estiver ativo, move a câmera suavemente ao receber sinal
    if (provider.modoSeguirVeiculo && provider.veiculoSelecionado != null && _mapaPronto) {
      final v = provider.veiculoSelecionado!;
      final destLatLng = LatLng(v.py, v.px);
      final dist = const Distance().as(LengthUnit.Meter, _mapController.camera.center, destLatLng);
      if (dist > 15) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && provider.modoSeguirVeiculo) {
            _animatedMapMove(destLatLng, math.max(_mapController.camera.zoom, 15.5));
          }
        });
      }
    }

    // Centro inicial do mapa
    LatLng centroMapa = _centroSaoPaulo;
    if (veiculos.isNotEmpty && veiculos.first.py != 0.0) {
      centroMapa = LatLng(veiculos.first.py, veiculos.first.px);
    } else if (trajeto != null && trajeto.pontos.isNotEmpty) {
      centroMapa = trajeto.pontos.first;
    }

    final df = DateFormat('HH:mm:ss');
    final horaAtualizacao = provider.ultimaAtualizacao != null
        ? df.format(provider.ultimaAtualizacao!)
        : 'Conectando telemetria...';

    // 1. Marcadores de veículos otimizados
    final marcadoresVeiculos = veiculos.map((v) {
      final isSel = provider.veiculoSelecionado?.p == v.p;
      return Marker(
        point: LatLng(v.py, v.px),
        width: 70,
        height: 70,
        child: VeiculoMarkerWidget(
          veiculo: v,
          isSelecionado: isSel,
          onTap: () {
            provider.selecionarVeiculo(v);
            _animatedMapMove(LatLng(v.py, v.px), 16.0);
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => PainelVeiculoDetalheWidget(
                veiculo: v,
                linha: linha ?? Linha(cl: 0, lc: false, lt: v.p, tl: 10, sl: 1, tp: 'Ônibus em Trânsito', ts: ''),
                isSeguindo: provider.modoSeguirVeiculo && provider.veiculoSelecionado?.p == v.p,
                onAlternarSeguir: () {
                  provider.alternarModoSeguir();
                  Navigator.of(context).pop();
                },
                onFechar: () => Navigator.of(context).pop(),
              ),
            );
          },
        ),
      );
    }).toList();

    // 2. Marcadores de paradas com Level of Detail (LOD)
    // Zoom < 12.0: não exibe paradas (evita travamento de CPU com 80+ paradas)
    // Zoom 12.0 até 13.8: micro-dots leves
    // Zoom >= 13.8: marcadores completos interativos
    final List<Marker> marcadoresParadas = [];
    if (_currentZoom >= 12.0) {
      final bool isCompact = _currentZoom < 13.8;
      for (final p in paradas) {
        final isSel = provider.paradaSelecionada?.cp == p.cp;
        marcadoresParadas.add(
          Marker(
            point: LatLng(p.py, p.px),
            width: isCompact && !isSel ? 20 : 90,
            height: isCompact && !isSel ? 20 : 45,
            child: ParadaMarkerWidget(
              parada: p,
              isSelecionada: isSel,
              isCompact: isCompact,
              onTap: () {
                provider.selecionarParadaECarregarPrevisao(p);
                _animatedMapMove(LatLng(p.py, p.px), 16.0);
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => PrevisaoModalWidget(
                    parada: p,
                    onFechar: () {
                      provider.fecharPrevisaoParada();
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
            ),
          ),
        );
      }
    }

    return Stack(
      children: [
        // ======================================================================
        // 1. MAPA INTERATIVO FLUIDO (SEMPRE CARREGADO)
        // ======================================================================
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: centroMapa,
            initialZoom: 13.0,
            minZoom: 4,
            maxZoom: 19.5,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            onPositionChanged: (camera, hasGesture) {
              setState(() {
                _currentZoom = camera.zoom;
                _currentRotation = camera.rotation;
              });
              // Se o usuário interagiu por gesto próprio, desliga suavemente o auto-follow
              if (hasGesture && provider.modoSeguirVeiculo) {
                provider.desativarModoSeguir();
              }
            },
            onMapReady: () {
              setState(() => _mapaPronto = true);
              if (linha != null) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) _ajustarCameraParaLinha(provider);
                });
              }
            },
          ),
          children: [
            // Camada de Mapa: OpenStreetMap Standard ou Satélite Real (ambos sem chave de API)
            TileLayer(
              key: ValueKey(provider.estiloMapa),
              urlTemplate: _obterUrlTemplate(provider.estiloMapa),
              subdomains: _obterSubdominios(provider.estiloMapa),
              userAgentPackageName: 'com.example.app_transporte',
              maxZoom: 19,
              minZoom: 4,
              keepBuffer: 3,
              panBuffer: 1,
            ),

            // Trajeto Vetorial em Alta Definição e Alto Contraste (Multi-pass glow)
            if (trajeto != null && trajeto.pontos.isNotEmpty)
              PolylineLayer(
                polylines: [
                  // Pass 1: Sombra suave de contraste sobre as vias
                  Polyline(
                    points: trajeto.pontos,
                    strokeWidth: 8.0,
                    color: Colors.black.withValues(alpha: 0.30),
                  ),
                  // Pass 2: Borda escura de contorno para máxima visibilidade
                  Polyline(
                    points: trajeto.pontos,
                    strokeWidth: 6.0,
                    color: const Color(0xFF0F3B20),
                  ),
                  // Pass 3: Linha principal em verde trânsito nítido
                  Polyline(
                    points: trajeto.pontos,
                    strokeWidth: 4.2,
                    color: const Color(0xFF1E824C),
                  ),
                  // Pass 4: Destaque interno
                  Polyline(
                    points: trajeto.pontos,
                    strokeWidth: 1.6,
                    color: const Color(0xFF86EFAC),
                  ),
                ],
              ),

            // Marcadores de Paradas (com LOD ativo)
            MarkerLayer(markers: marcadoresParadas),

            // Marcadores de Ônibus em Tempo Real
            MarkerLayer(markers: marcadoresVeiculos),

            // Marcador de Localização Atual do Usuário (GPS ao vivo)
            if (provider.localizacaoUsuario != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: provider.localizacaoUsuario!,
                    width: 50,
                    height: 50,
                    child: UserLocationMarkerWidget(
                      onTap: () {
                        _animatedMapMove(provider.localizacaoUsuario!, 16.5);
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),

        // ======================================================================
        // 2. HEADER SUPERIOR FLUTUANTE ADAPTATIVO
        // ======================================================================
        Positioned(
          top: 8,
          left: 14,
          right: 14,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: linha == null
                  // Estado A: Nenhuma linha selecionada -> Barra de busca flutuante moderna
                  ? _buildBarraBuscaFlutuante(context, provider)
                  // Estado B: Linha ativa acompanhada -> Header compacto com status ao vivo
                  : _buildHeaderLinhaAtiva(context, provider, linha, veiculos.length, horaAtualizacao),
            ),
          ),
        ),

        // ======================================================================
        // 3. CONTROLES FLUTUANTES À DIREITA (TOOLBAR EM VIDRO)
        // ======================================================================
        Positioned(
          top: linha == null ? 120 : 76,
          right: 14,
          child: MapaControlesWidget(
            modoSeguirAtivo: provider.modoSeguirVeiculo,
            rotacao: _currentRotation,
            isSatelite: provider.estiloMapa == 'satelite',
            temLocalizacaoUsuario: provider.localizacaoUsuario != null,
            onAlternarTipoMapa: () => provider.alternarTipoMapa(),
            onMinhaLocalizacao: () async {
              final loc = await provider.obterLocalizacaoAtual();
              if (loc != null) {
                _animatedMapMove(loc, 16.5);
              } else if (provider.localizacaoUsuario != null) {
                _animatedMapMove(provider.localizacaoUsuario!, 16.5);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.erroLocalizacao ?? 'Ative a permissão de GPS para ver sua localização.'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            onAlternarSeguir: () {
              if (provider.veiculoSelecionado == null && veiculos.isNotEmpty) {
                provider.selecionarVeiculo(veiculos.first, seguir: true);
                _animatedMapMove(LatLng(veiculos.first.py, veiculos.first.px), 16.0);
              } else {
                provider.alternarModoSeguir();
              }
            },
            onRecentralizar: () {
              if (linha != null) {
                _ajustarCameraParaLinha(provider);
              } else {
                _animatedMapMove(_centroSaoPaulo, 13.0);
              }
            },
            onResetarNorte: () {
              _animatedMapMove(_mapController.camera.center, _mapController.camera.zoom, destRotation: 0.0);
            },
            onZoomMais: () {
              final novoZoom = math.min(_mapController.camera.zoom + 1.2, 19.5);
              _animatedMapMove(_mapController.camera.center, novoZoom);
            },
            onZoomMenos: () {
              final novoZoom = math.max(_mapController.camera.zoom - 1.2, 4.0);
              _animatedMapMove(_mapController.camera.center, novoZoom);
            },
          ),
        ),

        // ======================================================================
        // 4. CARROSSEL INFERIOR DE VEÍCULOS (OU BADGE RECOLHIDO)
        // ======================================================================
        if (linha != null)
          Positioned(
            bottom: 84,
            left: 14,
            right: 14,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: _buildCarrosselInferior(context, provider, veiculos),
              ),
            ),
          ),
      ],
    );
  }

  /// Barra de busca flutuante para quando nenhuma linha estiver sendo monitorada
  Widget _buildBarraBuscaFlutuante(BuildContext context, TransporteProvider provider) {
    final favoritos = provider.favoritos;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassContainer(
          borderRadius: 20,
          blurSigma: 18,
          fillOpacity: 0.16,
          borderOpacity: 0.22,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          onTap: () => _abrirModalBuscaRapida(context, provider),
          child: Row(
            children: [
              Image.asset(
                'assets/images/cata_pobre_icon.png',
                width: 34,
                height: 34,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cadê o Cata Pobre?',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Toque para pesquisar e rastrear ao vivo no mapa',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: GlassTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.touch_app_rounded, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      'Explorar',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Atalhos rápidos em chips horizontais (Favoritos ou rotas populares)
        if (favoritos.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: math.min(favoritos.length, 6),
              separatorBuilder: (_, index) => const SizedBox(width: 6),
              itemBuilder: (ctx, index) {
                final fav = favoritos[index];
                final letreiro = fav['letreiro'] ?? fav['codigo_linha'] ?? '';
                final desc = fav['descricao'] ?? '';

                return InkWell(
                  onTap: () async {
                    final codigo = int.tryParse(fav['codigo_linha'] ?? '');
                    if (codigo != null) {
                      final linhaObj = Linha(
                        cl: codigo,
                        lc: false,
                        lt: letreiro,
                        tl: 10,
                        sl: 1,
                        tp: desc,
                        ts: '',
                      );
                      provider.acompanharLinha(linhaObj);
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) _ajustarCameraParaLinha(provider);
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xDD111915),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.star_fill, size: 11, color: Color(0xFFFF9F0A)),
                        const SizedBox(width: 6),
                        Text(
                          letreiro,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
      ],
    );
  }

  /// Header de linha ativa em vidro líquido
  Widget _buildHeaderLinhaAtiva(
    BuildContext context,
    TransporteProvider provider,
    Linha linha,
    int qtdVeiculos,
    String horaAtualizacao,
  ) {
    return GlassContainer(
      borderRadius: GlassTheme.radiusCard,
      blurSigma: GlassTheme.blurSurface,
      fillOpacity: GlassTheme.fillSurface,
      borderOpacity: GlassTheme.borderDefault,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF1B3B2B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Text(
              linha.lt,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  linha.tp,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    _PulsatingDot(
                      color: qtdVeiculos > 0
                          ? GlassTheme.systemGreen
                          : GlassTheme.systemOrange,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$qtdVeiculos ônibus ao vivo • $horaAtualizacao',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: GlassTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Trocar linha',
            icon: const Icon(CupertinoIcons.search, color: Colors.white70, size: 18),
            onPressed: () => _abrirModalBuscaRapida(context, provider),
          ),
          IconButton(
            tooltip: 'Fechar linha',
            icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
            onPressed: () => provider.pararAcompanhamento(),
          ),
        ],
      ),
    );
  }

  /// Carrossel inferior retrátil com os veículos ativos
  Widget _buildCarrosselInferior(
    BuildContext context,
    TransporteProvider provider,
    List<dynamic> veiculos,
  ) {
    if (veiculos.isEmpty) {
      return GlassContainer(
        borderRadius: GlassTheme.radiusInput,
        blurSigma: 14,
        fillOpacity: 0.12,
        borderOpacity: 0.16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Aguardando telemetria GPS da frota...',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: GlassTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Botão de expandir / recolher carrossel
        GestureDetector(
          onTap: () {
            setState(() => _carrosselExpandido = !_carrosselExpandido);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xDD121714),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.directions_bus_rounded,
                  size: 13,
                  color: GlassTheme.systemGreen,
                ),
                const SizedBox(width: 5),
                Text(
                  '${veiculos.length} ônibus',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _carrosselExpandido
                      ? CupertinoIcons.chevron_down
                      : CupertinoIcons.chevron_up,
                  size: 12,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ),

        // Lista horizontal de ônibus
        if (_carrosselExpandido)
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: veiculos.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final v = veiculos[index];
                final isSel = provider.veiculoSelecionado?.p == v.p;
                final hora = v.ta.isNotEmpty
                    ? v.ta.substring(v.ta.length >= 8 ? v.ta.length - 8 : 0)
                    : '';

                return GlassContainer(
                  borderRadius: GlassTheme.radiusCard,
                  blurSigma: 16,
                  fillOpacity: isSel ? 0.90 : 0.84,
                  borderOpacity: isSel ? 0.45 : 0.16,
                  tint: isSel ? const Color(0xFF1E3A2B) : const Color(0xFF121614),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  onTap: () {
                    provider.selecionarVeiculo(v, seguir: true);
                    _animatedMapMove(LatLng(v.py, v.px), 16.0);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSel
                              ? GlassTheme.systemGreen.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.10),
                          border: Border.all(
                            color: isSel
                                ? GlassTheme.systemGreen
                                : Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Icon(
                          Icons.directions_bus_rounded,
                          size: 14,
                          color: isSel ? GlassTheme.systemGreen : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.p,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (v.a)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Icon(
                                    Icons.accessible_rounded,
                                    size: 10,
                                    color: Colors.white.withValues(alpha: 0.70),
                                  ),
                                ),
                              if (hora.isNotEmpty)
                                Text(
                                  hora,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.white.withValues(alpha: 0.55),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Modal de Busca Rápida de Linhas diretamente a partir da tela do mapa
class _ModalBuscaRapidaLinhas extends StatefulWidget {
  final TransporteProvider provider;
  final Function(Linha linha) onLinhaSelecionada;

  const _ModalBuscaRapidaLinhas({
    required this.provider,
    required this.onLinhaSelecionada,
  });

  @override
  State<_ModalBuscaRapidaLinhas> createState() => _ModalBuscaRapidaLinhasState();
}

class _ModalBuscaRapidaLinhasState extends State<_ModalBuscaRapidaLinhas> {
  final TextEditingController _buscaCtrl = TextEditingController();

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final linhas = provider.linhas;
    final historico = provider.historicoBuscas;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xF2101713),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Selecionar Linha para o Mapa',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 12),

              // Campo de texto de busca
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _buscaCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    icon: const Icon(CupertinoIcons.search, color: Colors.white70, size: 18),
                    hintText: 'Digite o número ou destino da linha...',
                    hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                    border: InputBorder.none,
                    suffixIcon: _buscaCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white60, size: 18),
                            onPressed: () {
                              _buscaCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      provider.buscarLinhas(val.trim());
                    }
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Resultados ou histórico
              Expanded(
                child: provider.carregando
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                        ),
                      )
                    : linhas.isNotEmpty
                        ? ListView.separated(
                            controller: scrollController,
                            itemCount: linhas.length,
                            separatorBuilder: (_, index) => const Divider(color: Colors.white10, height: 1),
                            itemBuilder: (ctx, idx) {
                              final l = linhas[idx];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                leading: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B3B2B),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.16),
                                    ),
                                  ),
                                  child: Text(
                                    l.lt,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  l.tp,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: l.ts.isNotEmpty
                                    ? Text(
                                        'Sentido: ${l.ts}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: GlassTheme.textTertiary,
                                        ),
                                      )
                                    : null,
                                trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white30,
                                  size: 14,
                                ),
                                onTap: () => widget.onLinhaSelecionada(l),
                              );
                            },
                          )
                        : ListView(
                            controller: scrollController,
                            children: [
                              if (historico.isNotEmpty) ...[
                                Text(
                                  'Buscas Recentes',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: GlassTheme.textTertiary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: historico.map((h) {
                                    return ActionChip(
                                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                                      side: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.12),
                                      ),
                                      label: Text(
                                        h,
                                        style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                                      ),
                                      onPressed: () {
                                        _buscaCtrl.text = h;
                                        provider.buscarLinhas(h);
                                      },
                                    );
                                  }).toList(),
                                ),
                              ] else
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 40),
                                    child: Text(
                                      'Digite o número ou nome da linha para ver o trajeto e veículos ao vivo.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        color: GlassTheme.textTertiary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget de ponto pulsante para status ao vivo
class _PulsatingDot extends StatefulWidget {
  final Color color;
  const _PulsatingDot({required this.color});

  @override
  State<_PulsatingDot> createState() => _PulsatingDotState();
}

class _PulsatingDotState extends State<_PulsatingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1300),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.50, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: _animation.value),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _animation.value * 0.5),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
