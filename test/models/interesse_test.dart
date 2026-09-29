import 'package:backstage/models/interesse.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Interesse _candidatura({StatusInteresse? status}) => Interesse(
  id: Interesse.idCandidatura('m1', 'o1'),
  tipo: TipoInteresse.candidatura,
  remetenteId: 'm1',
  remetenteNome: 'Guilherme',
  destinatarioId: 'e1',
  musicoId: 'm1',
  musicoNome: 'The VooDooS',
  oportunidadeId: 'o1',
  oportunidadeTitulo: 'Show de sexta',
  criadoEm: DateTime(2026, 9, 28, 10),
  status: status,
);

void main() {
  group('Interesse', () {
    test('toMap e fromMap preservam todos os campos (id fora do mapa)', () {
      final original = _candidatura().copyWith(
        status: StatusInteresse.aceito,
        respondidoEm: DateTime(2026, 9, 28, 11),
        conversaId: 'm1_op_o1',
      );

      final map = original.toMap();
      final copia = Interesse.fromMap(original.id, map);

      expect(map.containsKey('id'), isFalse);
      expect(map['tipo'], 'candidatura');
      expect(map['status'], 'aceito');
      expect(copia.tipo, TipoInteresse.candidatura);
      expect(copia.remetenteId, 'm1');
      expect(copia.destinatarioId, 'e1');
      expect(copia.musicoNome, 'The VooDooS');
      expect(copia.oportunidadeTitulo, 'Show de sexta');
      expect(copia.status, StatusInteresse.aceito);
      expect(copia.criadoEm, DateTime(2026, 9, 28, 10));
      expect(copia.respondidoEm, DateTime(2026, 9, 28, 11));
      expect(copia.conversaId, 'm1_op_o1');
    });

    test('status padrão é pendente e campos opcionais ficam fora do mapa', () {
      final convite = Interesse(
        id: Interesse.idConvite('e1', 'm1'),
        tipo: TipoInteresse.convite,
        remetenteId: 'e1',
        remetenteNome: 'Bar Central',
        destinatarioId: 'm1',
        musicoId: 'm1',
        musicoNome: 'The VooDooS',
        criadoEm: DateTime(2026, 9, 28),
      );

      final map = convite.toMap();

      expect(convite.pendente, isTrue);
      expect(map.containsKey('oportunidadeId'), isFalse);
      expect(map.containsKey('respondidoEm'), isFalse);
      expect(map.containsKey('conversaId'), isFalse);
    });

    test('ids determinísticos por tipo', () {
      expect(Interesse.idCandidatura('m1', 'o1'), 'm1_op_o1');
      expect(Interesse.idConvite('e1', 'm1'), 'e1_mu_m1');
      expect(Interesse.idConvite('e1', 'm1', oportunidadeId: 'o1'), 'e1_mu_m1_o1');
    });

    test('fromMap aceita Timestamp e cai para padrões em campos ausentes', () {
      final interesse = Interesse.fromMap('x', {
        'criadoEm': Timestamp.fromDate(DateTime(2026, 1, 2)),
        'status': 'inexistente',
      });

      expect(interesse.criadoEm, DateTime(2026, 1, 2));
      expect(interesse.status, StatusInteresse.pendente);
      expect(interesse.tipo, TipoInteresse.candidatura);
      expect(interesse.remetenteId, '');
      expect(interesse.respondidoEm, isNull);
    });

    test('rotuloStatus por tipo e status', () {
      expect(_candidatura().rotuloStatus, 'Candidatura enviada');
      expect(
        _candidatura(status: StatusInteresse.recusado).rotuloStatus,
        'Recusado',
      );
      final convite = Interesse(
        id: 'c',
        tipo: TipoInteresse.convite,
        remetenteId: 'e1',
        remetenteNome: '',
        destinatarioId: 'm1',
        musicoId: 'm1',
        musicoNome: '',
        criadoEm: DateTime(2026),
      );
      expect(convite.rotuloStatus, 'Convite enviado');
    });
  });
}
