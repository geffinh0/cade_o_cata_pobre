import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/glass_theme.dart';
import 'glass_container.dart';

/// Barra de Pesquisa Padronizada em Estilo Pílula e Vidro Líquido Neutro
///
/// Características:
/// - Pílula 100% simétrica com curvatura contínua (radiusPill: 999px).
/// - Superfície em vidro líquido fosco (BackdropFilter sigma 16 + borda sutil 1px).
/// - Ícone contextual à esquerda (ônibus, parada, lupa).
/// - Botão limpar (x) dinâmico ao digitar.
/// - Spinner de carregamento integrado.
/// - Botão de ação "Buscar" / "Explorar" integrado dentro da própria pílula.
/// - Suporte a modo somente leitura para abertura de modais no mapa com o mesmo visual.
class GlassSearchBar extends StatefulWidget {
  const GlassSearchBar({
    super.key,
    this.controller,
    required this.hintText,
    this.prefixIcon = Icons.search_rounded,
    this.actionIcon,
    this.actionLabel = 'Buscar',
    this.onSubmitted,
    this.onChanged,
    this.onSearch,
    this.onClear,
    this.onTap,
    this.isLoading = false,
    this.autofocus = false,
    this.readOnly = false,
    this.height = 48.0,
  });

  final TextEditingController? controller;
  final String hintText;
  final IconData prefixIcon;
  final IconData? actionIcon;
  final String? actionLabel;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSearch;
  final VoidCallback? onClear;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool autofocus;
  final bool readOnly;
  final double height;

  @override
  State<GlassSearchBar> createState() => _GlassSearchBarState();
}

class _GlassSearchBarState extends State<GlassSearchBar> {
  TextEditingController? _internalController;
  TextEditingController get _effectiveController => widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = TextEditingController();
    }
    _effectiveController.addListener(_onControllerChange);
  }

  @override
  void didUpdateWidget(covariant GlassSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChange);
      if (widget.controller == null) {
        _internalController ??= TextEditingController();
      }
      _effectiveController.addListener(_onControllerChange);
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onControllerChange);
    _internalController?.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _effectiveController.text.isNotEmpty;
    final showActionButton = (widget.onSearch != null || widget.actionLabel != null);

    return GlassContainer(
      borderRadius: GlassTheme.radiusPill,
      blurSigma: 16,
      fillOpacity: 0.10,
      borderOpacity: 0.16,
      onTap: widget.readOnly ? widget.onTap : null,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      child: IgnorePointer(
        ignoring: widget.readOnly,
        child: SizedBox(
          height: widget.height,
          child: Row(
            children: [
              // Ícone contextual à esquerda
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 10),
                child: Icon(
                  widget.prefixIcon,
                  size: 19,
                  color: Colors.white60,
                ),
              ),

              // Campo de digitação ou rótulo somente-leitura
              Expanded(
                child: widget.readOnly
                    ? Container(
                        alignment: Alignment.centerLeft,
                        height: widget.height,
                        child: Text(
                          widget.hintText,
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : TextField(
                        controller: _effectiveController,
                      autofocus: widget.autofocus,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                      ),
                      cursorColor: Colors.white,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: widget.hintText,
                        hintStyle: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (val) {
                        widget.onSubmitted?.call(val);
                        widget.onSearch?.call();
                      },
                      onChanged: widget.onChanged,
                    ),
            ),

            // Botão de Limpar (x) quando há texto
            if (hasText && !widget.readOnly) ...[
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: Colors.white70,
                  ),
                ),
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Limpar texto',
                onPressed: () {
                  _effectiveController.clear();
                  widget.onClear?.call();
                  widget.onChanged?.call('');
                },
              ),
            ],

            // Indicador de Carregamento
            if (widget.isLoading) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                ),
              ),
            ],

            // Botão de ação integrado à direita na pílula
            if (showActionButton && !widget.isLoading) ...[
              Padding(
                padding: const EdgeInsets.only(left: 2, right: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(GlassTheme.radiusPill),
                    onTap: widget.isLoading ? null : (widget.onSearch ?? widget.onTap),
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(GlassTheme.radiusPill),
                        color: GlassTheme.accentDarkGreen.withValues(alpha: 0.55),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.actionIcon ?? Icons.search_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          if (widget.actionLabel != null && widget.actionLabel!.isNotEmpty) ...[
                            const SizedBox(width: 5),
                            Text(
                              widget.actionLabel!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
}
