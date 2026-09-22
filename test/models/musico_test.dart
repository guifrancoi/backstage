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
  datasDisponiveis: ['2026-03-20'],
  fotoPath: '/fotos/banda.jpg',
  interesseEnviado: true,
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
      expect(copia.datasDisponiveis, original.datasDisponiveis);
      expect(copia.fotoPath, original.fotoPath);
      expect(copia.interesseEnviado, isTrue);
    });

    test('fromMap aplica valores padrão para campos ausentes', () {
      final musico = Musico.fromMap('x', {});

      expect(musico.nomeArtistico, '');
      expect(musico.cacheMedio, 0);
      expect(musico.portfolioLinks, isEmpty);
      expect(musico.datasDisponiveis, isEmpty);
      expect(musico.fotoPath, isNull);
      expect(musico.interesseEnviado, isFalse);
    });

    test('fromMap converte cacheMedio inteiro para double', () {
      final musico = Musico.fromMap('x', {'cacheMedio': 900});

      expect(musico.cacheMedio, 900.0);
    });

    test('interesseEnviado é false por padrão no construtor', () {
      final musico = Musico(
        id: '1',
        nomeArtistico: 'A',
        generoMusical: 'MPB',
        cidade: 'B',
        descricao: 'C',
        cacheMedio: 1,
        portfolioLinks: const [],
        datasDisponiveis: const [],
      );

      expect(musico.interesseEnviado, isFalse);
    });

    test('copyWith altera só os campos informados', () {
      final original = _musico();

      final alterado = original.copyWith(cidade: 'Ribeirão Preto', cacheMedio: 2000);

      expect(alterado.cidade, 'Ribeirão Preto');
      expect(alterado.cacheMedio, 2000);
      expect(alterado.nomeArtistico, original.nomeArtistico);
      expect(alterado.fotoPath, original.fotoPath);
      expect(original.cidade, 'Franca');
    });

    test('copyWith sem fotoPath mantém a foto atual', () {
      expect(_musico().copyWith(cidade: 'X').fotoPath, '/fotos/banda.jpg');
    });

    test('copyWith troca a foto quando informada', () {
      expect(_musico().copyWith(fotoPath: '/nova.jpg').fotoPath, '/nova.jpg');
    });

    test('clearFotoPath remove a foto', () {
      final semFoto = _musico().copyWith(clearFotoPath: true);

      expect(semFoto.fotoPath, isNull);
      expect(semFoto.toMap()['fotoPath'], isNull);
    });

    test('clearFotoPath tem prioridade sobre uma foto informada', () {
      final semFoto = _musico().copyWith(fotoPath: '/nova.jpg', clearFotoPath: true);

      expect(semFoto.fotoPath, isNull);
    });
  });
}
