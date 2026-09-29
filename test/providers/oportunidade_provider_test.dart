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

  test('no modo mock não fica carregando nem em erro', () {
    expect(provider.carregandoMusicos, isFalse);
    expect(provider.carregandoOportunidades, isFalse);
    expect(provider.erroMusicos, isFalse);
    expect(provider.erroOportunidades, isFalse);
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

    test('ao filtrar, pesquisar ou ordenar músicos', () {
      provider.filtrarOportunidades(genero: 'Rock');

      provider
        ..filtrarMusicos(genero: 'MPB')
        ..pesquisarMusicos('Duo')
        ..ordenarMusicos('cache_maior')
        ..resetarFiltroMusicos();

      expect(soRock(provider), isTrue);
    });

    test('ao criar uma oportunidade', () async {
      provider.filtrarOportunidades(genero: 'Rock');

      await provider.criarOportunidade(
        MockData.oportunidades.first.copyWith(generoMusical: 'MPB'),
        'e1',
      );

      expect(soRock(provider), isTrue);
    });
  });

  group('oportunidades do dono (modo mock)', () {
    test('criarOportunidade grava com o donoId e aparece em minhasOportunidades', () async {
      final ok = await provider.criarOportunidade(
        MockData.oportunidades.first.copyWith(titulo: 'Minha vaga'),
        'e1',
      );

      final minhas = provider.minhasOportunidades('e1');
      expect(ok, isTrue);
      expect(minhas.map((o) => o.titulo), ['Minha vaga']);
      expect(minhas.single.donoId, 'e1');
      expect(provider.oportunidades, hasLength(MockData.oportunidades.length + 1));
    });

    test('minhasOportunidades ignora as de outros donos e uid nulo', () {
      expect(provider.minhasOportunidades('e1'), isEmpty);
      expect(provider.minhasOportunidades(null), isEmpty);
      expect(provider.minhasOportunidades('mock-estabelecimento-1'), hasLength(1));
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
