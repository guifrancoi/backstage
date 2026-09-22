import 'package:backstage/models/oportunidade.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Oportunidade _oportunidade({String? cep = '14010-120'}) => Oportunidade(
  id: 'o1',
  titulo: 'Show de sexta',
  descricao: 'Descrição',
  cidade: 'Ribeirão Preto',
  generoMusical: 'MPB',
  dataEvento: DateTime(2026, 3, 21, 20),
  cacheOferecido: 900,
  contratante: 'Bar Central',
  logradouro: 'Rua Barão do Amazonas',
  numero: '520',
  estado: 'SP',
  cep: cep,
);

void main() {
  group('Oportunidade', () {
    test('toMap e fromMap preservam todos os campos', () {
      final original = _oportunidade();

      final copia = Oportunidade.fromMap('o1', original.toMap());

      expect(copia.id, 'o1');
      expect(copia.titulo, original.titulo);
      expect(copia.dataEvento, original.dataEvento);
      expect(copia.cacheOferecido, original.cacheOferecido);
      expect(copia.contratante, original.contratante);
      expect(copia.logradouro, original.logradouro);
      expect(copia.numero, original.numero);
      expect(copia.estado, original.estado);
      expect(copia.cep, original.cep);
      expect(copia.interesseEnviado, isFalse);
    });

    test('toMap omite cep quando nulo', () {
      final map = _oportunidade(cep: null).toMap();

      expect(map.containsKey('cep'), isFalse);
    });

    group('dataEvento no fromMap', () {
      final data = DateTime(2026, 3, 21, 20);

      test('aceita Timestamp do Firestore', () {
        final o = Oportunidade.fromMap('o1', {
          'dataEvento': Timestamp.fromDate(data),
        });

        expect(o.dataEvento, data);
      });

      test('aceita String ISO-8601', () {
        final o = Oportunidade.fromMap('o1', {
          'dataEvento': data.toIso8601String(),
        });

        expect(o.dataEvento, data);
      });

      test('aceita DateTime', () {
        final o = Oportunidade.fromMap('o1', {'dataEvento': data});

        expect(o.dataEvento, data);
      });

      test('valor inválido cai para a data atual', () {
        final antes = DateTime.now();
        final o = Oportunidade.fromMap('o1', {'dataEvento': 'nao-e-data'});

        expect(o.dataEvento.isBefore(antes), isFalse);
      });
    });

    group('copyWith', () {
      test('mantém o cep quando não informado', () {
        final alterada = _oportunidade().copyWith(titulo: 'Novo título');

        expect(alterada.titulo, 'Novo título');
        expect(alterada.cep, '14010-120');
      });

      test('clearCep remove o cep', () {
        final alterada = _oportunidade().copyWith(clearCep: true);

        expect(alterada.cep, isNull);
      });

      test('clearCep tem prioridade sobre um cep informado', () {
        final alterada = _oportunidade().copyWith(cep: '00000-000', clearCep: true);

        expect(alterada.cep, isNull);
      });
    });
  });
}
