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
  fotoPath: '/fotos/banda.jpg',
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
      expect(copia.fotoPath, original.fotoPath);
      expect(map.containsKey('interesseEnviado'), isFalse);
    });

    test('fromMap aplica valores padrão para campos ausentes', () {
      final musico = Musico.fromMap('x', {});

      expect(musico.nomeArtistico, '');
      expect(musico.cacheMedio, 0);
      expect(musico.portfolioLinks, isEmpty);
      expect(musico.fotoPath, isNull);
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

    test('completo exige os campos obrigatórios e gênero da lista', () {
      expect(_musico().completo, isTrue);
      expect(_musico().copyWith(portfolioLinks: []).completo, isTrue);
      expect(_musico().copyWith(generoMusical: '').completo, isFalse);
      expect(_musico().copyWith(generoMusical: 'Inventado').completo, isFalse);
      expect(_musico().copyWith(cidade: ' ').completo, isFalse);
      expect(_musico().copyWith(descricao: '').completo, isFalse);
      expect(_musico().copyWith(cacheMedio: -1).completo, isFalse);
    });

    test('oculto faz ida e volta e é false por padrão', () {
      final oculto = Musico.fromMap('m1', _musico().copyWith(oculto: true).toMap());

      expect(oculto.oculto, isTrue);
      expect(Musico.fromMap('x', {}).oculto, isFalse);
    });
  });
}
