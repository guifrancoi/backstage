import 'package:backstage/models/filtro_oportunidades.dart';
import 'package:backstage/models/oportunidade.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/firebase_fake.dart';

void main() {
  final hoje = DateTime(2026, 10, 1, 15, 30);

  Oportunidade o(
    String id,
    DateTime data, {
    String genero = 'Rock',
    String cidade = 'Franca',
    double cache = 1000,
  }) => oportunidadeTeste(
    id: id,
    generoMusical: genero,
    cidade: cidade,
  ).copyWith(dataEvento: data, cacheOferecido: cache);

  final lista = [
    o('ontem', DateTime(2026, 9, 30)),
    o('hoje', DateTime(2026, 10, 1, 21)),
    o('mpb', DateTime(2026, 10, 10), genero: 'MPB', cidade: 'Ribeirão Preto', cache: 800),
    o('caro', DateTime(2026, 10, 5), cache: 2500),
    o('longe', DateTime(2026, 12, 25)),
  ];

  List<String> ids(List<Oportunidade> l) => l.map((x) => x.id).toList();

  test('sem critérios: tira as vencidas e ordena por data (o dia de hoje vale)', () {
    final resultado = const FiltroOportunidades().aplicar(lista, hoje: hoje);

    expect(ids(resultado), ['hoje', 'caro', 'mpb', 'longe']);
  });

  test('gênero exato e cidade por trecho, sem diferenciar maiúsculas', () {
    expect(
      ids(const FiltroOportunidades(genero: 'MPB').aplicar(lista, hoje: hoje)),
      ['mpb'],
    );
    expect(
      ids(const FiltroOportunidades(cidade: ' ribeirão ').aplicar(lista, hoje: hoje)),
      ['mpb'],
    );
  });

  test('cachê mínimo é inclusivo', () {
    expect(
      ids(const FiltroOportunidades(cacheMinimo: 1000).aplicar(lista, hoje: hoje)),
      ['hoje', 'caro', 'longe'],
    );
  });

  test('período de/até inclusivo, ignorando o horário', () {
    final filtro = FiltroOportunidades(
      de: DateTime(2026, 10, 1),
      ate: DateTime(2026, 10, 10),
    );

    expect(ids(filtro.aplicar(lista, hoje: hoje)), ['hoje', 'caro', 'mpb']);
  });

  test('só dias livres: tira dias com show e dias bloqueados', () {
    const ocupados = {'2026-10-05'};
    const bloqueados = {'2026-10-10'};

    // Sem o filtro, a agenda não interfere.
    expect(
      const FiltroOportunidades().aplicar(
        lista,
        hoje: hoje,
        bloqueados: bloqueados,
        ocupados: ocupados,
      ),
      hasLength(4),
    );
    expect(
      ids(
        const FiltroOportunidades(soDiasLivres: true).aplicar(
          lista,
          hoje: hoje,
          bloqueados: bloqueados,
          ocupados: ocupados,
        ),
      ),
      ['hoje', 'longe'],
    );
  });

  test('ativos conta os critérios ligados; copyWith limpa um por vez', () {
    final filtro = FiltroOportunidades(
      genero: 'Rock',
      cidade: 'Franca',
      cacheMinimo: 500,
      de: DateTime(2026, 10, 1),
      soDiasLivres: true,
    );

    expect(filtro.ativos, 5);
    expect(const FiltroOportunidades().vazio, isTrue);
    expect(const FiltroOportunidades(genero: '', cidade: '  ').vazio, isTrue);

    final semGenero = filtro.copyWith(limparGenero: true);
    expect(semGenero.genero, isNull);
    expect(semGenero.cidade, 'Franca');
    expect(semGenero.ativos, 4);
    expect(filtro.copyWith(limparDe: true, limparCacheMinimo: true).ativos, 3);
  });

  test('Oportunidade.vencidaEm compara só o dia', () {
    expect(o('x', DateTime(2026, 9, 30, 23, 59)).vencidaEm(hoje), isTrue);
    expect(o('x', DateTime(2026, 10, 1)).vencidaEm(hoje), isFalse);
  });
}
