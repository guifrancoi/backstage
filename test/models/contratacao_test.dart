import 'package:backstage/models/agenda_publica.dart';
import 'package:backstage/models/contratacao.dart';
import 'package:backstage/models/interesse.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Contratacao _contratacao({
  String dia = '2026-11-20',
  StatusContratacao status = StatusContratacao.proposta,
}) => Contratacao(
  id: 'c1',
  interesseId: 'i1',
  musicoId: 'm1',
  musicoNome: 'Banda',
  donoId: 'e1',
  donoNome: 'Bar Central',
  oportunidadeId: 'o1',
  titulo: 'Show de sexta',
  dia: dia,
  horaInicio: '20:00',
  horaFim: '23:00',
  cacheAcordado: 1500,
  logradouro: 'Rua A',
  numero: '10',
  cidade: 'Franca',
  estado: 'SP',
  criadoEm: DateTime(2026, 9, 29),
  status: status,
);

void main() {
  group('Contratacao', () {
    test('toMap e fromMap preservam os campos (id e status como texto)', () {
      final original = _contratacao(status: StatusContratacao.confirmada);

      final map = original.toMap();
      final copia = Contratacao.fromMap('c1', map);

      expect(map.containsKey('id'), isFalse);
      expect(map['status'], 'confirmada');
      expect(map.containsKey('motivoCancelamento'), isFalse);
      expect(copia.status, StatusContratacao.confirmada);
      expect(copia.dia, '2026-11-20');
      expect(copia.horaInicio, '20:00');
      expect(copia.cacheAcordado, 1500);
      expect(copia.oportunidadeId, 'o1');
      expect(copia.endereco, 'Rua A, 10 — Franca/SP');
    });

    test('fromMap converte Timestamp e cai em proposta sem status', () {
      final c = Contratacao.fromMap('x', {
        'criadoEm': Timestamp.fromDate(DateTime(2026, 9, 1)),
        'cacheAcordado': 800,
      });

      expect(c.criadoEm, DateTime(2026, 9, 1));
      expect(c.status, StatusContratacao.proposta);
      expect(c.cacheAcordado, 800.0);
    });

    test('diaDe e idOcupacao', () {
      expect(Contratacao.diaDe(DateTime(2026, 3, 5, 22, 30)), '2026-03-05');
      expect(Contratacao.idOcupacao('m1', '2026-03-05'), 'm1_2026-03-05');
      expect(_contratacao().data, DateTime(2026, 11, 20));
    });

    test('ativa: proposta ou confirmada', () {
      expect(_contratacao().ativa, isTrue);
      expect(_contratacao(status: StatusContratacao.confirmada).ativa, isTrue);
      expect(_contratacao(status: StatusContratacao.recusada).ativa, isFalse);
      expect(_contratacao(status: StatusContratacao.cancelada).ativa, isFalse);
    });

    test('realizada é derivada: confirmada com dia passado', () {
      final passado = _contratacao(
        dia: '2020-01-10',
        status: StatusContratacao.confirmada,
      );
      final futura = _contratacao(
        dia: '2099-01-10',
        status: StatusContratacao.confirmada,
      );

      expect(passado.realizada, isTrue);
      expect(passado.rotuloStatus, 'Realizada');
      expect(futura.realizada, isFalse);
      expect(futura.rotuloStatus, 'Confirmada');
      expect(_contratacao(dia: '2020-01-10').realizada, isFalse);
    });

    test('copyWith troca só o status e dados de resposta', () {
      final cancelada = _contratacao().copyWith(
        status: StatusContratacao.cancelada,
        canceladoPor: 'e1',
        motivoCancelamento: 'Chuva',
      );

      expect(cancelada.status, StatusContratacao.cancelada);
      expect(cancelada.canceladoPor, 'e1');
      expect(cancelada.dia, '2026-11-20');
    });
  });

  test('Interesse.donoId: quem convidou ou quem recebeu a candidatura', () {
    Interesse interesse(TipoInteresse tipo, String remetente, String destino) =>
        Interesse(
          id: 'i',
          tipo: tipo,
          remetenteId: remetente,
          remetenteNome: '',
          destinatarioId: destino,
          musicoId: 'm1',
          musicoNome: '',
          criadoEm: DateTime(2026),
        );

    expect(interesse(TipoInteresse.convite, 'e1', 'm1').donoId, 'e1');
    expect(interesse(TipoInteresse.candidatura, 'm1', 'e1').donoId, 'e1');
  });

  test('AgendaPublica: livre por padrão; show ou bloqueio tiram o dia', () {
    const agenda = AgendaPublica(
      bloqueados: {'2026-11-21'},
      ocupados: {'2026-11-20'},
    );

    expect(agenda.ocupado('2026-11-20'), isTrue);
    expect(agenda.livre('2026-11-20'), isFalse);
    expect(agenda.bloqueado('2026-11-21'), isTrue);
    expect(agenda.livre('2026-11-21'), isFalse);
    expect(agenda.livre('2026-11-22'), isTrue);
  });
}
