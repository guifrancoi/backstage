import 'package:backstage/models/musico.dart';
import 'package:flutter_test/flutter_test.dart';

Musico _musico() => Musico(
  id: 'm1',
  nomeArtistico: 'Banda Teste',
  generoMusical: 'Rock',
  cidade: 'Franca',
  descricao: 'Descrição',
  cacheMedio: 1500,
  portfolioLinks: ['instagram.com/banda'],
  foto: 'aGVsbG8=',
  formacao: Formacao.banda,
  integrantes: 5,
  equipamentoProprio: true,
  duracaoShowMin: 90,
  repertorio: 'Autoral e covers',
);

void main() {
  group('Musico', () {
    test('toMap e fromMap preservam todos os campos (id fora do mapa)', () {
      final original = _musico();

      final map = original.toMap();
      final copia = Musico.fromMap('m1', map);

      expect(map.containsKey('id'), isFalse);
      expect(copia.id, 'm1');
      expect(copia.nomeArtistico, original.nomeArtistico);
      expect(copia.generoMusical, original.generoMusical);
      expect(copia.cidade, original.cidade);
      expect(copia.descricao, original.descricao);
      expect(copia.cacheMedio, original.cacheMedio);
      expect(copia.portfolioLinks, original.portfolioLinks);
      expect(copia.foto, original.foto);
      expect(copia.formacao, Formacao.banda);
      expect(map['formacao'], 'banda');
      expect(copia.integrantes, 5);
      expect(copia.equipamentoProprio, isTrue);
      expect(copia.duracaoShowMin, 90);
      expect(copia.repertorio, 'Autoral e covers');
      expect(map.containsKey('interesseEnviado'), isFalse);
    });

    test('fromMap aplica valores padrão para campos ausentes', () {
      final musico = Musico.fromMap('x', {});

      expect(musico.nomeArtistico, '');
      expect(musico.cacheMedio, 0);
      expect(musico.portfolioLinks, isEmpty);
      expect(musico.foto, isNull);
      expect(musico.formacao, isNull);
      expect(musico.integrantes, isNull);
      expect(musico.equipamentoProprio, isFalse);
      expect(musico.duracaoShowMin, isNull);
      expect(musico.repertorio, isNull);
    });

    test('fromMap ignora o fotoPath antigo, formação desconhecida e texto vazio', () {
      final musico = Musico.fromMap('x', {
        'fotoPath': '/data/user/0/foto.jpg',
        'formacao': 'orquestra',
        'repertorio': '  ',
        'foto': '',
      });

      expect(musico.foto, isNull);
      expect(musico.formacao, isNull);
      expect(musico.repertorio, isNull);
    });

    test('toMap grava os campos opcionais vazios como null (merge apaga)', () {
      final map = Musico.fromMap('x', {}).toMap();

      for (final chave in ['foto', 'formacao', 'integrantes', 'duracaoShowMin', 'repertorio']) {
        expect(map.containsKey(chave), isTrue, reason: chave);
        expect(map[chave], isNull, reason: chave);
      }
    });

    test('fromMap converte cacheMedio inteiro para double', () {
      final musico = Musico.fromMap('x', {'cacheMedio': 900});

      expect(musico.cacheMedio, 900.0);
    });

    test('copyWith altera só os campos informados', () {
      final original = _musico();

      final alterado = original.copyWith(cidade: 'Ribeirão Preto', cacheMedio: 2000);

      expect(alterado.cidade, 'Ribeirão Preto');
      expect(alterado.cacheMedio, 2000);
      expect(alterado.nomeArtistico, original.nomeArtistico);
      expect(alterado.foto, original.foto);
      expect(alterado.formacao, original.formacao);
      expect(original.cidade, 'Franca');
    });

    test('copyWith troca a foto quando informada', () {
      expect(_musico().copyWith(foto: 'bm92YQ==').foto, 'bm92YQ==');
    });

    test('clearFoto remove a foto, com prioridade sobre uma informada', () {
      expect(_musico().copyWith(clearFoto: true).foto, isNull);
      expect(_musico().copyWith(foto: 'bm92YQ==', clearFoto: true).foto, isNull);
    });

    test('formacaoDescrita e resumoShow', () {
      expect(_musico().formacaoDescrita, 'Banda (5 integrantes)');
      expect(_musico().resumoShow, 'Banda · Equipamento próprio');

      final trio = Musico.fromMap('x', {'formacao': 'trio'});
      expect(trio.formacaoDescrita, 'Trio');
      expect(trio.resumoShow, 'Trio');

      final soEquipamento = Musico.fromMap('x', {'equipamentoProprio': true});
      expect(soEquipamento.formacaoDescrita, isNull);
      expect(soEquipamento.resumoShow, 'Equipamento próprio');

      expect(Musico.fromMap('x', {}).resumoShow, isNull);
    });

    test('completo exige os campos obrigatórios e gênero da lista', () {
      expect(_musico().completo, isTrue);
      expect(_musico().copyWith(portfolioLinks: []).completo, isTrue);
      expect(_musico().copyWith(generoMusical: '').completo, isFalse);
      expect(_musico().copyWith(generoMusical: 'Inventado').completo, isFalse);
      expect(_musico().copyWith(cidade: ' ').completo, isFalse);
      expect(_musico().copyWith(descricao: '').completo, isFalse);
      expect(_musico().copyWith(cacheMedio: -1).completo, isFalse);
    });

    test('dados do show são opcionais: não afetam completo', () {
      final semShow = Musico.fromMap('x', {
        'nomeArtistico': 'Banda',
        'generoMusical': 'Rock',
        'cidade': 'Franca',
        'descricao': 'Rock',
        'cacheMedio': 1000,
      });

      expect(semShow.completo, isTrue);
    });

    test('oculto faz ida e volta e é false por padrão', () {
      final oculto = Musico.fromMap('m1', _musico().copyWith(oculto: true).toMap());

      expect(oculto.oculto, isTrue);
      expect(Musico.fromMap('x', {}).oculto, isFalse);
    });
  });
}
