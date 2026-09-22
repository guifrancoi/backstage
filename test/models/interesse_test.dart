import 'package:backstage/models/interesse.dart';
import 'package:backstage/models/interesse_musico.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final data = DateTime(2026, 3, 21, 10, 30);

  group('Interesse', () {
    test('toMap e fromMap preservam os campos', () {
      final original = Interesse(
        id: 'u1_o1',
        oportunidadeId: 'o1',
        usuarioId: 'u1',
        dataHora: data,
      );

      final copia = Interesse.fromMap('u1_o1', original.toMap());

      expect(copia.id, 'u1_o1');
      expect(copia.oportunidadeId, 'o1');
      expect(copia.usuarioId, 'u1');
      expect(copia.dataHora, data);
    });

    test('fromMap aceita Timestamp em dataHora', () {
      final interesse = Interesse.fromMap('x', {
        'dataHora': Timestamp.fromDate(data),
      });

      expect(interesse.dataHora, data);
    });
  });

  group('InteresseMusico', () {
    test('toMap e fromMap preservam os campos', () {
      final original = InteresseMusico(
        id: 'u1_m1',
        musicoId: 'm1',
        usuarioId: 'u1',
        dataHora: data,
      );

      final copia = InteresseMusico.fromMap('u1_m1', original.toMap());

      expect(copia.musicoId, 'm1');
      expect(copia.usuarioId, 'u1');
      expect(copia.dataHora, data);
    });

    test('fromMap aceita String em dataHora', () {
      final interesse = InteresseMusico.fromMap('x', {
        'dataHora': data.toIso8601String(),
      });

      expect(interesse.dataHora, data);
    });
  });
}
