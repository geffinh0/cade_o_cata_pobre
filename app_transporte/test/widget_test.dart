import 'package:flutter_test/flutter_test.dart';
import 'package:app_transporte/models/linha.dart';
import 'package:app_transporte/models/parada.dart';
import 'package:app_transporte/models/veiculo.dart';
import 'package:app_transporte/models/previsao.dart';
import 'package:app_transporte/models/trajeto.dart';
import 'package:app_transporte/models/metrica_sistema.dart';

void main() {
  group('Testes Unitários de Modelos (SPTrans JSON Serialization)', () {
    test('Linha deve deserializar JSON corretamente', () {
      final json = {
        'cl': 8000,
        'lc': false,
        'lt': '8000-10',
        'sl': 1,
        'tl': 10,
        'tp': 'TERM. LAPA',
        'ts': 'PÇA. RAMOS DE AZEVEDO'
      };

      final linha = Linha.fromJson(json);

      expect(linha.cl, equals(8000));
      expect(linha.lt, equals('8000-10'));
      expect(linha.tp, equals('TERM. LAPA'));
      expect(linha.ts, equals('PÇA. RAMOS DE AZEVEDO'));
      expect(linha.lc, isFalse);
      expect(linha.sentidoDescricao, contains('Ida'));
    });

    test('Parada deve deserializar coordenadas e dados', () {
      final json = {
        'cp': 340015339,
        'np': 'R. CONSOLAÇÃO, 222',
        'py': -23.5489,
        'px': -46.6482
      };

      final parada = Parada.fromJson(json);

      expect(parada.cp, equals(340015339));
      expect(parada.np, equals('R. CONSOLAÇÃO, 222'));
      expect(parada.py, equals(-23.5489));
      expect(parada.px, equals(-46.6482));
    });

    test('Veiculo e PosicaoLinha devem processar telemetria', () {
      final json = {
        'hr': '16:45',
        'vs': [
          {
            'p': '11042',
            'a': true,
            'ta': '2026-09-05T23:45:00Z',
            'py': -23.5505,
            'px': -46.6333
          }
        ]
      };

      final posLinha = PosicaoLinha.fromJson(json);

      expect(posLinha.hr, equals('16:45'));
      expect(posLinha.vs.length, equals(1));
      expect(posLinha.vs.first.p, equals('11042'));
      expect(posLinha.vs.first.a, isTrue);
      expect(posLinha.vs.first.py, equals(-23.5505));
    });

    test('Previsao deve processar estrutura aninhada de paradas e veículos', () {
      final json = {
        'cp': 340015339,
        'np': 'PARADA CONSOLAÇÃO',
        'py': -23.5489,
        'px': -46.6482,
        'l': [
          {
            'c': '8000-10',
            'cl': 8000,
            'sl': 1,
            'qv': 1,
            'vs': [
              {
                'p': '12034',
                't': '16:50',
                'py': -23.5512,
                'px': -46.6341
              }
            ]
          }
        ]
      };

      final previsao = Previsao.fromJson(json);

      expect(previsao.cp, equals(340015339));
      expect(previsao.l.length, equals(1));
      expect(previsao.l.first.vs.length, equals(1));
      expect(previsao.l.first.vs.first.t, equals('16:50'));
    });

    test('TrajetoLinha deve deserializar coordenadas LatLng', () {
      final json = {
        'codigoLinha': 8000,
        'letreiro': '8000-10',
        'nome': 'Lapa / Ramos',
        'cor': '#C00000',
        'pontos': [
          {'py': -23.5186, 'px': -46.7029},
          {'py': -23.5492, 'px': -46.6385}
        ]
      };

      final trajeto = TrajetoLinha.fromJson(json);
      expect(trajeto.codigoLinha, equals(8000));
      expect(trajeto.temPontos, isTrue);
      expect(trajeto.pontos.length, equals(2));
      expect(trajeto.pontos.first.latitude, equals(-23.5186));
    });

    test('MetricaSistema deve formatar tempo de atividade e ler campos', () {
      final json = {
        'status': 'ok',
        'modoSimulado': true,
        'autenticado': false,
        'tempoAtividadeSegundos': 3665,
        'totalConexoesSocket': 5,
        'clientesConectadosAgora': 2,
        'linhasAcompanhadasAgora': 1,
        'listaLinhasAssinadas': ['8000'],
        'totalRequisicoesHttp': 42,
        'totalPollsRealizados': 10,
        'totalPushesEmitidos': 20,
        'totalItensEmCache': 3,
        'intervaloPollingMs': 15000,
        'dataHoraServidor': '2026-09-07T14:00:00Z'
      };

      final metrica = MetricaSistema.fromJson(json);
      expect(metrica.status, equals('ok'));
      expect(metrica.modoSimulado, isTrue);
      expect(metrica.tempoAtividadeFormatado, equals('01:01:05'));
      expect(metrica.clientesConectadosAgora, equals(2));
    });
  });
}
