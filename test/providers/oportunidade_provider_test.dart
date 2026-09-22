import 'package:backstage/data/mock_data.dart';
import 'package:backstage/models/musico.dart';
import 'package:backstage/providers/oportunidade_provider.dart';
import 'package:flutter_test/flutter_test.dart';

// Sem Firebase inicializado, FirebaseDataService.isEnabled == false e o
// provider opera com MockData.
void main() {
  late OportunidadeProvider provider;

  setUp(() => provider = OportunidadeProvider());
  tearDown(() => provider.dispose());

  List<String> nomes(List<Musico> musicos) =>
      musicos.map((m) => m.nomeArtistico).toList();

  test('inicia com músicos e oportunidades do MockData', () {
    expect(provider.musicos, hasLength(MockData.musicos.length));
    expect(provider.oportunidades, hasLength(MockData.oportunidades.length));
    expect(provider.tipoOrdenacao, 'nome_asc');
  });

  test('streams entregam os dados mock', () async {
    expect(await provider.musicosStream.first, hasLength(MockData.musicos.length));
    expect(
      await provider.oportunidadesStream.first,
      hasLength(MockData.oportunidades.length),
    );
  });

  group('filtros de músicos', () {
    test('filtra por gênero exato', () {
      provider.filtrarMusicos(genero: 'Rock');

      expect(provider.musicos, isNotEmpty);
      expect(provider.musicos.every((m) => m.generoMusical == 'Rock'), isTrue);
      expect(provider.generoSelecionadoMusicos, 'Rock');
    });

    test('filtra por trecho da cidade sem diferenciar maiúsculas', () {
      provider.filtrarMusicos(cidade: 'ribeirão');

      expect(provider.musicos, isNotEmpty);
      expect(
        provider.musicos.every((m) => m.cidade.toLowerCase().contains('ribeirão')),
        isTrue,
      );
    });

    test('gênero vazio não filtra', () {
      provider.filtrarMusicos(genero: '');

      expect(provider.musicos, hasLength(MockData.musicos.length));
    });

    test('pesquisa por nome artístico ou descrição', () {
      provider.pesquisarMusicos('ECLIPSE');
      expect(nomes(provider.musicos), ['Banda Eclipse']);

      provider.pesquisarMusicos('intimistas');
      expect(nomes(provider.musicos), ['Duo Acústico Sol']);
    });

    test('pesquisa sem correspondência retorna lista vazia', () {
      provider.pesquisarMusicos('inexistente');

      expect(provider.musicos, isEmpty);
    });

    test('resetarFiltroMusicos limpa filtros, pesquisa e ordenação', () {
      provider
        ..filtrarMusicos(genero: 'Rock', cidade: 'Franca')
        ..pesquisarMusicos('x')
        ..ordenarMusicos('cache_menor')
        ..resetarFiltroMusicos();

      expect(provider.musicos, hasLength(MockData.musicos.length));
      expect(provider.generoSelecionadoMusicos, isNull);
      expect(provider.cidadeFiltroMusicos, isNull);
      expect(provider.termoPesquisa, '');
      expect(provider.tipoOrdenacao, 'nome_asc');
    });

    test('notifica ouvintes ao filtrar', () {
      var notificacoes = 0;
      provider.addListener(() => notificacoes++);

      provider.filtrarMusicos(genero: 'MPB');

      expect(notificacoes, 1);
    });
  });

  group('ordenação de músicos', () {
    test('nome_asc e nome_desc', () {
      final esperado = nomes(MockData.musicos)
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      provider.ordenarMusicos('nome_asc');
      expect(nomes(provider.musicos), esperado);

      provider.ordenarMusicos('nome_desc');
      expect(nomes(provider.musicos), esperado.reversed.toList());
    });

    test('cache_maior e cache_menor', () {
      provider.ordenarMusicos('cache_maior');
      final maior = provider.musicos.map((m) => m.cacheMedio).toList();
      expect(maior, [...maior]..sort((a, b) => b.compareTo(a)));

      provider.ordenarMusicos('cache_menor');
      final menor = provider.musicos.map((m) => m.cacheMedio).toList();
      expect(menor, [...menor]..sort());
    });

    test('ordenação é mantida ao aplicar filtro', () {
      provider
        ..ordenarMusicos('cache_menor')
        ..filtrarMusicos(genero: '');

      final caches = provider.musicos.map((m) => m.cacheMedio).toList();
      expect(caches, [...caches]..sort());
    });
  });

  group('filtros de oportunidades', () {
    test('filtra por gênero e cidade e reseta', () {
      provider.filtrarOportunidades(genero: 'Rock');
      expect(provider.oportunidades.every((o) => o.generoMusical == 'Rock'), isTrue);

      provider.filtrarOportunidades(cidade: 'SERTÃOZINHO');
      expect(provider.oportunidades.map((o) => o.cidade), ['Sertãozinho']);

      provider.resetarFiltroOportunidades();
      expect(provider.oportunidades, hasLength(MockData.oportunidades.length));
    });
  });

  group('filtro de oportunidades persiste', () {
    bool soRock(OportunidadeProvider p) =>
        p.oportunidades.isNotEmpty &&
        p.oportunidades.every((o) => o.generoMusical == 'Rock');

    test('ao demonstrar interesse em uma oportunidade', () async {
      provider.filtrarOportunidades(genero: 'Rock');

      await provider.demonstrarInteresse(oportunidadeId: '2', usuarioId: 'u1');

      expect(soRock(provider), isTrue);
      expect(provider.jaDemonstrouInteresse('2'), isTrue);
    });

    test('ao remover interesse em uma oportunidade', () async {
      await provider.demonstrarInteresse(oportunidadeId: '2', usuarioId: 'u1');
      provider.filtrarOportunidades(genero: 'Rock');

      await provider.removerInteresse('2');

      expect(soRock(provider), isTrue);
    });

    test('ao filtrar, pesquisar ou ordenar músicos', () {
      provider.filtrarOportunidades(genero: 'Rock');

      provider
        ..filtrarMusicos(genero: 'MPB')
        ..pesquisarMusicos('Duo')
        ..ordenarMusicos('cache_maior')
        ..resetarFiltroMusicos();

      expect(soRock(provider), isTrue);
    });

    test('ao demonstrar interesse em um músico', () async {
      provider.filtrarOportunidades(cidade: 'Sertãozinho');

      await provider.demonstrarInteresseEmMusico(musicoId: '1', usuarioId: 'u1');

      expect(provider.oportunidades.map((o) => o.cidade), ['Sertãozinho']);
    });

    test('resetarFiltroOportunidades limpa o filtro salvo', () async {
      provider
        ..filtrarOportunidades(genero: 'Rock')
        ..resetarFiltroOportunidades();

      await provider.demonstrarInteresse(oportunidadeId: '1', usuarioId: 'u1');

      expect(provider.oportunidades, hasLength(MockData.oportunidades.length));
    });
  });

  group('listas de interesse ignoram filtros ativos', () {
    test('oportunidadesComInteresse e jaDemonstrouInteresse', () async {
      await provider.demonstrarInteresse(oportunidadeId: '1', usuarioId: 'u1');

      // Oportunidade '1' é MPB; o filtro Rock a esconde da lista filtrada.
      provider.filtrarOportunidades(genero: 'Rock');

      expect(provider.oportunidadesComInteresse.map((o) => o.id), ['1']);
      expect(provider.jaDemonstrouInteresse('1'), isTrue);
    });

    test('musicosComInteresse', () async {
      await provider.demonstrarInteresseEmMusico(musicoId: '1', usuarioId: 'u1');

      // Músico '1' é Rock; o filtro MPB o esconde da lista filtrada.
      provider.filtrarMusicos(genero: 'MPB');

      expect(provider.musicosComInteresse.map((m) => m.id), ['1']);
    });
  });

  group('interesse em oportunidades', () {
    test('demonstrar marca a oportunidade e cria interesse com id usuario_oportunidade', () async {
      await provider.demonstrarInteresse(oportunidadeId: '1', usuarioId: 'u1');

      expect(provider.jaDemonstrouInteresse('1'), isTrue);
      expect(provider.oportunidadesComInteresse.map((o) => o.id), ['1']);
      expect(provider.interesses.single.id, 'u1_1');
      expect(provider.interesses.single.usuarioId, 'u1');
    });

    test('demonstrar duas vezes não duplica o interesse', () async {
      await provider.demonstrarInteresse(oportunidadeId: '1', usuarioId: 'u1');
      await provider.demonstrarInteresse(oportunidadeId: '1', usuarioId: 'u1');

      expect(provider.interesses, hasLength(1));
    });

    test('oportunidade inexistente é ignorada', () async {
      await provider.demonstrarInteresse(oportunidadeId: 'nao-existe', usuarioId: 'u1');

      expect(provider.interesses, isEmpty);
    });

    test('remover desmarca a oportunidade', () async {
      await provider.demonstrarInteresse(oportunidadeId: '1', usuarioId: 'u1');
      await provider.removerInteresse('1');

      expect(provider.jaDemonstrouInteresse('1'), isFalse);
      expect(provider.interesses, isEmpty);
      expect(provider.oportunidadesComInteresse, isEmpty);
    });
  });

  group('interesse em músicos', () {
    test('demonstrar marca o músico e mantém filtros ativos', () async {
      provider.filtrarMusicos(genero: 'Rock');

      await provider.demonstrarInteresseEmMusico(musicoId: '1', usuarioId: 'u1');

      expect(provider.musicos.every((m) => m.generoMusical == 'Rock'), isTrue);
      expect(provider.musicosComInteresse.map((m) => m.id), ['1']);
      expect(provider.interessesMusicos.single.id, 'u1_1');
    });

    test('remover desmarca o músico', () async {
      await provider.demonstrarInteresseEmMusico(musicoId: '1', usuarioId: 'u1');
      await provider.removerInteresseEmMusico('1');

      expect(provider.musicosComInteresse, isEmpty);
      expect(provider.interessesMusicos, isEmpty);
    });
  });

  group('busca por id', () {
    test('encontra músico mesmo fora do filtro atual', () {
      provider.filtrarMusicos(genero: 'MPB');

      expect(provider.buscarMusicoPorId('1')?.nomeArtistico, 'Banda Eclipse');
      expect(provider.buscarMusicoPorId('nao-existe'), isNull);
    });

    test('encontra oportunidade mesmo fora do filtro atual', () {
      provider.filtrarOportunidades(genero: 'Rock');

      expect(provider.buscarOportunidadePorId('1')?.contratante, 'Bar Central');
      expect(provider.buscarOportunidadePorId('nao-existe'), isNull);
    });
  });
}
