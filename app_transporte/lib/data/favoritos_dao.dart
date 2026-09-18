import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// DAO (Data Access Object) para persistência local completa (Offline First)
///
/// [Conceito de SD: Armazenamento Local e Tolerância a Desconexão]
/// Permite que rotas favoritas, paradas preferidas, preferências de tema e histórico
/// permaneçam salvos no dispositivo móvel de forma persistente, mesmo sem sinal de rede.
class FavoritosDao {
  static const String _keyLinhasFavoritas = 'aps_linhas_favoritas';
  static const String _keyParadasFavoritas = 'aps_paradas_favoritas';
  static const String _keyHistoricoBuscas = 'aps_historico_buscas';
  static const String _keyThemeMode = 'aps_theme_mode';
  static const String _keyMapStyle = 'aps_map_style';
  static const String _keyServidorUrl = 'aps_servidor_url';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ==========================================================================
  // LINHAS FAVORITAS
  // ==========================================================================

  Future<List<Map<String, String>>> listarFavoritos() async {
    try {
      final prefs = await _getPrefs();
      final rawList = prefs.getStringList(_keyLinhasFavoritas) ?? [];
      return rawList.map((itemStr) {
        try {
          final map = jsonDecode(itemStr) as Map<String, dynamic>;
          return {
            'codigo_linha': map['codigo_linha']?.toString() ?? '',
            'descricao': map['descricao']?.toString() ?? '',
            'letreiro': map['letreiro']?.toString() ?? '',
          };
        } catch (_) {
          return {
            'codigo_linha': itemStr,
            'descricao': 'Linha $itemStr',
            'letreiro': itemStr,
          };
        }
      }).toList();
    } catch (e) {
      debugPrint('[FavoritosDao] Erro ao listar linhas favoritas: $e');
      return [];
    }
  }

  Future<void> adicionar(String codigoLinha, String descricao, {String letreiro = ''}) async {
    final prefs = await _getPrefs();
    final list = List<Map<String, dynamic>>.from(await listarFavoritos());

    list.removeWhere((item) => item['codigo_linha'] == codigoLinha);
    list.insert(0, {
      'codigo_linha': codigoLinha,
      'descricao': descricao,
      'letreiro': letreiro.isNotEmpty ? letreiro : descricao,
    });

    final serialized = list.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList(_keyLinhasFavoritas, serialized);
  }

  Future<void> remover(String codigoLinha) async {
    final prefs = await _getPrefs();
    final list = List<Map<String, dynamic>>.from(await listarFavoritos());
    list.removeWhere((item) => item['codigo_linha'] == codigoLinha);

    final serialized = list.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList(_keyLinhasFavoritas, serialized);
  }

  Future<bool> isFavorito(String codigoLinha) async {
    final list = await listarFavoritos();
    return list.any((item) => item['codigo_linha'] == codigoLinha);
  }

  // ==========================================================================
  // PARADAS FAVORITAS
  // ==========================================================================

  Future<List<Map<String, dynamic>>> listarParadasFavoritas() async {
    try {
      final prefs = await _getPrefs();
      final rawList = prefs.getStringList(_keyParadasFavoritas) ?? [];
      return rawList.map((itemStr) {
        try {
          return jsonDecode(itemStr) as Map<String, dynamic>;
        } catch (_) {
          return <String, dynamic>{};
        }
      }).where((m) => m.isNotEmpty).toList();
    } catch (e) {
      debugPrint('[FavoritosDao] Erro ao listar paradas favoritas: $e');
      return [];
    }
  }

  Future<void> adicionarParada(int codigoParada, String nomeParada, double py, double px) async {
    final prefs = await _getPrefs();
    final list = List<Map<String, dynamic>>.from(await listarParadasFavoritas());

    list.removeWhere((item) => item['codigo_parada'] == codigoParada);
    list.insert(0, {
      'codigo_parada': codigoParada,
      'nome_parada': nomeParada,
      'py': py,
      'px': px,
    });

    final serialized = list.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList(_keyParadasFavoritas, serialized);
  }

  Future<void> removerParada(int codigoParada) async {
    final prefs = await _getPrefs();
    final list = List<Map<String, dynamic>>.from(await listarParadasFavoritas());
    list.removeWhere((item) => item['codigo_parada'] == codigoParada);

    final serialized = list.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList(_keyParadasFavoritas, serialized);
  }

  Future<bool> isParadaFavorita(int codigoParada) async {
    final list = await listarParadasFavoritas();
    return list.any((item) => item['codigo_parada'] == codigoParada);
  }

  // ==========================================================================
  // HISTÓRICO DE BUSCAS RECENTES
  // ==========================================================================

  Future<List<String>> listarHistoricoBuscas() async {
    final prefs = await _getPrefs();
    final raw = prefs.getStringList(_keyHistoricoBuscas) ?? <String>[];
    return List<String>.from(raw);
  }

  Future<void> adicionarHistoricoBusca(String termo) async {
    final t = termo.trim();
    if (t.isEmpty) return;

    final prefs = await _getPrefs();
    final list = List<String>.from(await listarHistoricoBuscas());
    list.removeWhere((item) => item.toLowerCase() == t.toLowerCase());
    list.insert(0, t);
    if (list.length > 10) list.removeLast();

    await prefs.setStringList(_keyHistoricoBuscas, list);
  }

  Future<void> limparHistoricoBuscas() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyHistoricoBuscas);
  }

  // ==========================================================================
  // PREFERÊNCIAS DE CONFIGURAÇÃO (Tema, Estilo do Mapa, Servidor)
  // ==========================================================================

  Future<String> obterTema() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyThemeMode) ?? 'dark'; // Padrão Dark Mode moderno
  }

  Future<void> salvarTema(String modo) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyThemeMode, modo);
  }

  Future<String> obterEstiloMapa() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyMapStyle) ?? 'padrao';
  }

  Future<void> salvarEstiloMapa(String estilo) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyMapStyle, estilo);
  }

  Future<String?> obterServidorUrl() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyServidorUrl);
  }

  Future<void> salvarServidorUrl(String url) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyServidorUrl, url);
  }
}
