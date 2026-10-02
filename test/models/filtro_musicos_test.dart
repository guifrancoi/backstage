import 'package:backstage/models/filtro_musicos.dart';
import 'package:backstage/models/musico.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FiltroMusicos', () {
    test('vazio por padrão, ordem por nome', () {
      const filtro = FiltroMusicos();

      expect(filtro.vazio, isTrue);
      expect(filtro.ativos, 0);
      expect(filtro.ordenacao, 'nome_asc');
    });

    test('ativos conta cada critério ligado (ordem não conta)', () {
      final filtro = FiltroMusicos(
        termo: 'eclipse',
        genero: 'Rock',
        cidade: 'Franca',
        formacao: Formacao.trio,
        soEquipamentoProprio: true,
        livresEm: DateTime(2099, 3, 10),
        ordenacao: 'cache_maior',
      );

      expect(filtro.ativos, 6);
      expect(const FiltroMusicos(ordenacao: 'cache_maior').vazio, isTrue);
    });

    test('textos em branco e gênero vazio não contam', () {
      expect(const FiltroMusicos(termo: '  ', cidade: ' ', genero: '').vazio, isTrue);
    });

    test('copyWith troca e limpa critérios', () {
      final filtro = FiltroMusicos(
        genero: 'Rock',
        formacao: Formacao.duo,
        livresEm: DateTime(2099),
      );

      final semGenero = filtro.copyWith(limparGenero: true);
      expect(semGenero.genero, isNull);
      expect(semGenero.formacao, Formacao.duo);

      expect(filtro.copyWith(limparFormacao: true).formacao, isNull);
      expect(filtro.copyWith(limparLivresEm: true).livresEm, isNull);
      expect(filtro.copyWith(cidade: 'Franca').cidade, 'Franca');
      expect(filtro.copyWith(cidade: 'X', limparCidade: true).cidade, isNull);
    });
  });

  test('Plano 18: soFavoritos conta como critério', () {
    expect(const FiltroMusicos(soFavoritos: true).ativos, 1);
    expect(
      const FiltroMusicos(soFavoritos: true).copyWith(soFavoritos: false).vazio,
      isTrue,
    );
  });
}
