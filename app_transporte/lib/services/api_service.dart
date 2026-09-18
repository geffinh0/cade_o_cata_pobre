import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/linha.dart';
import '../models/metrica_sistema.dart';
import '../models/parada.dart';
import '../models/previsao.dart';
import '../models/trajeto.dart';

/// Exceção personalizada para falhas de comunicação com o Middleware
///
/// [Conceito de SD: Detecção de Falhas e Tolerância a Partições de Rede]
class MiddlewareException implements Exception {
  final String mensagem;
  final int? statusCode;

  MiddlewareException(this.mensagem, {this.statusCode});

  @override
  String toString() => 'MiddlewareException: $mensagem (Status: $statusCode)';
}

/// Serviço de comunicação HTTP REST com o Middleware Node.js
///
/// [Conceito de SD: Padrão API Gateway / Intermediador de Chamadas]
/// O app não se comunica diretamente com a SPTrans para evitar sobrecarga na API
/// e necessidade de expor credenciais no cliente. O middleware atua como gateway REST.
class ApiService {
  String baseUrl;
  final http.Client _client;

  ApiService({
    this.baseUrl = 'http://localhost:3000',
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Helper: GET com retry automático para falhas transitórias de rede
  Future<http.Response> _getComRetry(Uri uri, {int maxTentativas = 2, Duration timeout = const Duration(seconds: 15)}) async {
    late http.Response response;
    for (int tentativa = 1; tentativa <= maxTentativas; tentativa++) {
      try {
        response = await _client.get(uri).timeout(timeout);
        return response;
      } on TimeoutException {
        if (tentativa == maxTentativas) rethrow;
      } on SocketException {
        if (tentativa == maxTentativas) rethrow;
      } catch (e) {
        if (tentativa == maxTentativas) rethrow;
      }
      await Future.delayed(Duration(milliseconds: 500 * tentativa));
    }
    return response;
  }

  /// Atualiza o endereço base do middleware
  void atualizarBaseUrl(String novaBaseUrl) {
    baseUrl = novaBaseUrl.trim();
  }

  /// Verifica se o middleware está operacional e acessível
  /// GET /saude
  Future<Map<String, dynamic>> checarSaude() async {
    final uri = Uri.parse('$baseUrl/saude');
    try {
      final response = await _getComRetry(uri, timeout: const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      }
      return {'status': 'erro', 'statusCode': response.statusCode};
    } catch (e) {
      return {'status': 'indisponivel', 'erro': e.toString()};
    }
  }

  /// Busca linhas por termo (código ou nome)
  /// GET /linhas?termo={termo}
  Future<List<Linha>> buscarLinhas(String termo) async {
    final uri = Uri.parse('$baseUrl/linhas?termo=${Uri.encodeComponent(termo)}');
    try {
      final response = await _getComRetry(uri);

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((json) => Linha.fromJson(json))
              .toList();
        }
        return [];
      } else {
        throw MiddlewareException(
          'Erro ao buscar linhas: status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is MiddlewareException) rethrow;
      throw MiddlewareException('Falha ao conectar com $baseUrl: $e');
    }
  }

  /// Busca as paradas atendidas por uma linha específica (itinerário da linha)
  /// GET /linhas/{codigoLinha}/paradas
  Future<List<Parada>> buscarParadasPorLinha(int codigoLinha, {String? routeId, String? letreiro}) async {
    final query = <String>[];
    if (routeId != null && routeId.isNotEmpty) query.add('routeId=${Uri.encodeComponent(routeId)}');
    if (letreiro != null && letreiro.isNotEmpty) query.add('letreiro=${Uri.encodeComponent(letreiro)}');
    final qStr = query.isNotEmpty ? '?${query.join('&')}' : '';
    final uri = Uri.parse('$baseUrl/linhas/$codigoLinha/paradas$qStr');
    try {
      final response = await _getComRetry(uri);

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((json) => Parada.fromJson(json))
              .toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Obtém o trajeto vetorial georreferenciado (Polyline) de uma linha
  /// O servidor prioriza shapes GTFS reais e faz fallback para paradas
  /// GET /linhas/{codigoLinha}/trajeto
  Future<TrajetoLinha?> buscarTrajetoLinha(int codigoLinha, {String? routeId, String? letreiro}) async {
    final query = <String>[];
    if (routeId != null && routeId.isNotEmpty) query.add('routeId=${Uri.encodeComponent(routeId)}');
    if (letreiro != null && letreiro.isNotEmpty) query.add('letreiro=${Uri.encodeComponent(letreiro)}');
    final qStr = query.isNotEmpty ? '?${query.join('&')}' : '';
    final uri = Uri.parse('$baseUrl/linhas/$codigoLinha/trajeto$qStr');
    try {
      final response = await _getComRetry(uri);

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic>) {
          return TrajetoLinha.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Busca rotas GTFS por termo (letreiro ou nome)
  /// GET /gtfs/linhas?termo=...
  /// Retorna linhas em formato compatível com a API Olho Vivo
  Future<List<Linha>> buscarLinhasGtfs(String termo) async {
    final uri = Uri.parse('$baseUrl/gtfs/linhas?termo=${Uri.encodeComponent(termo)}');
    try {
      final response = await _getComRetry(uri);

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((json) => Linha.fromJson(json))
              .toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Obtém o shape (trajeto real das vias) de uma rota GTFS
  /// GET /gtfs/linhas/{routeId}/shape
  Future<TrajetoLinha?> buscarShapeGtfs(String routeId, {int? direction}) async {
    final params = direction != null ? '?direction=$direction' : '';
    final uri = Uri.parse('$baseUrl/gtfs/linhas/$routeId/shape$params');
    try {
      final response = await _getComRetry(uri);

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic>) {
          // Converte o formato do GTFS shape para TrajetoLinha
          final rawPontos = data['pontos'] as List<dynamic>? ?? [];
          final pontos = rawPontos.map((p) {
            final py = (p['py'] as num?)?.toDouble() ?? 0.0;
            final px = (p['px'] as num?)?.toDouble() ?? 0.0;
            return {'py': py, 'px': px};
          }).toList();

          return TrajetoLinha.fromJson({
            'codigoLinha': 0,
            'letreiro': data['letreiro'] ?? routeId,
            'nome': data['nome'] ?? '',
            'cor': data['cor'] ?? '#C00000',
            'pontos': pontos,
          });
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Busca paradas/pontos por logradouro ou código
  /// GET /paradas?termo=...
  Future<List<Parada>> buscarParadas(String termo) async {
    final uri = Uri.parse('$baseUrl/paradas?termo=${Uri.encodeComponent(termo)}');
    try {
      final response = await _getComRetry(uri);

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((json) => Parada.fromJson(json))
              .toList();
        }
        return [];
      } else {
        throw MiddlewareException(
          'Erro ao consultar paradas no middleware.',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is MiddlewareException) rethrow;
      throw MiddlewareException('Falha de conexão com o middleware em $baseUrl: $e');
    }
  }

  /// Obtém a previsão de chegada de veículos em uma parada específica
  /// GET /previsao/parada/{codigoParada}
  Future<Previsao?> previsaoParada(int codigoParada) async {
    final uri = Uri.parse('$baseUrl/previsao/parada/$codigoParada');
    try {
      final response = await _getComRetry(uri);

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic>) {
          return Previsao.fromJson(data);
        }
        return null;
      } else {
        throw MiddlewareException(
          'Falha ao obter previsão para a parada $codigoParada.',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is MiddlewareException) rethrow;
      throw MiddlewareException('Falha ao conectar com o middleware em $baseUrl: $e');
    }
  }

  /// Obtém métricas em tempo real do middleware de sistemas distribuídos
  /// GET /metricas
  Future<MetricaSistema?> obterMetricas() async {
    final uri = Uri.parse('$baseUrl/metricas');
    try {
      final response = await _getComRetry(uri, maxTentativas: 1, timeout: const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic>) {
          return MetricaSistema.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void fechar() {
    _client.close();
  }
}
