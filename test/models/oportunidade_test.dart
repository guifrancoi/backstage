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
  donoId: 'estabelecimento1',
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
      expect(copia.donoId, original.donoId);
      expect(copia.logradouro, original.logradouro);
      expect(copia.numero, original.numero);
      expect(copia.estado, original.estado);
      expect(copia.cep, original.cep);
      expect(original.toMap().containsKey('interesseEnviado'), isFalse);
      expect(copia.temDono, isTrue);
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

    test('donoId cai para string vazia quando ausente (dado legado)', () {
      final o = Oportunidade.fromMap('o1', {});

      expect(o.donoId, '');
      expect(o.temDono, isFalse);
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

    test('oculto faz ida e volta e é false por padrão', () {
      final oculta = Oportunidade.fromMap(
        'o1',
        _oportunidade().copyWith(oculto: true).toMap(),
      );

      expect(oculta.oculto, isTrue);
      expect(Oportunidade.fromMap('x', {}).oculto, isFalse);
    });
  });
}
