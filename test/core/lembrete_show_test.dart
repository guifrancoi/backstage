import 'package:backstage/core/utils/lembrete_show.dart';
import 'package:backstage/models/contratacao.dart';
import 'package:flutter_test/flutter_test.dart';

final _agora = DateTime(2026, 11, 20, 15);

Contratacao _show({
  String id = 'c1',
  String dia = '2026-11-20',
  String inicio = '21:00',
  String fim = '23:00',
  StatusContratacao status = StatusContratacao.confirmada,
  String musicoId = 'm1',
  String donoId = 'e1',
}) => Contratacao(
  id: id,
  interesseId: 'i1',
  musicoId: musicoId,
  musicoNome: 'Banda Eclipse',
  donoId: donoId,
  donoNome: 'Bar Central',
  titulo: 'Sexta do Rock',
  dia: dia,
  horaInicio: inicio,
  horaFim: fim,
  cacheAcordado: 1500,
  logradouro: 'Rua A',
  numero: '10',
  cidade: 'Franca',
  estado: 'SP',
  criadoEm: DateTime(2026, 10, 1),
  status: status,
);

void main() {
  group('lembretesDeShow', () {
    test('só confirmados de hoje e amanhã, em ordem de dia e horário', () {
      final lembretes = lembretesDeShow(
        [
          _show(id: 'amanha', dia: '2026-11-21', inicio: '20:00'),
          _show(id: 'hoje-tarde', inicio: '22:00'),
          _show(id: 'hoje-cedo', inicio: '19:00'),
          _show(id: 'depois', dia: '2026-11-22'),
          _show(id: 'ontem', dia: '2026-11-19'),
          _show(id: 'proposta', status: StatusContratacao.proposta),
          _show(id: 'cancelada', status: StatusContratacao.cancelada),
          _show(id: 'de-outros', musicoId: 'm9', donoId: 'e9'),
        ],
        uid: 'm1',
        agora: _agora,
      );

      expect(lembretes.map((l) => l.contratacao.id), [
        'hoje-cedo',
        'hoje-tarde',
        'amanha',
      ]);
      expect(lembretes.map((l) => l.hoje), [true, true, false]);
    });

    test('virada de mês: amanhã de 31/10 é 01/11', () {
      final lembretes = lembretesDeShow(
        [_show(dia: '2026-11-01')],
        uid: 'm1',
        agora: DateTime(2026, 10, 31, 23),
      );

      expect(lembretes.single.hoje, isFalse);
    });

    test('texto conforme o lado: músico e dono', () {
      final paraMusico = lembretesDeShow([_show()], uid: 'm1', agora: _agora).single;
      final paraDono = lembretesDeShow(
        [_show(dia: '2026-11-21')],
        uid: 'e1',
        agora: _agora,
      ).single;

      expect(paraMusico.titulo, 'Seu show é hoje às 21:00 em Bar Central');
      expect(paraDono.titulo, 'Show de Banda Eclipse amanhã às 21:00');
      expect(paraMusico.detalhe, 'Sexta do Rock · Rua A, 10 — Franca/SP');
    });
  });

  group('linkGoogleAgenda', () {
    test('monta o evento com horário, fuso, local e detalhes codificados', () {
      final uri = linkGoogleAgenda(_show(), souMusico: true);

      expect(uri.host, 'calendar.google.com');
      expect(uri.path, '/calendar/render');
      expect(uri.queryParameters['action'], 'TEMPLATE');
      expect(uri.queryParameters['dates'], '20261120T210000/20261120T230000');
      expect(uri.queryParameters['ctz'], 'America/Sao_Paulo');
      expect(uri.queryParameters['text'], 'Show: Sexta do Rock (Bar Central)');
      expect(uri.queryParameters['location'], 'Rua A, 10 — Franca/SP');
      expect(uri.queryParameters['details'], contains('Cachê: R\$ 1.500'));
      // Espaços codificados (Uri.encodeComponent), não "+".
      expect(uri.toString(), contains('Sexta%20do%20Rock'));
    });

    test('show que passa da meia-noite termina no dia seguinte', () {
      final uri = linkGoogleAgenda(_show(inicio: '22:00', fim: '01:00'), souMusico: false);

      expect(uri.queryParameters['dates'], '20261120T220000/20261121T010000');
      expect(uri.queryParameters['text'], 'Show: Sexta do Rock (Banda Eclipse)');
    });
  });
}
