import 'package:backstage/models/filtro_musicos.dart';
import 'package:backstage/models/filtro_oportunidades.dart';
import 'package:backstage/models/musico.dart';
import 'package:backstage/providers/oportunidade_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/firebase_fake.dart';

final _musicos = [
  musicoTeste(
    id: '1',
    nomeArtistico: 'Banda Eclipse',
    generoMusical: 'Rock',
    cidade: 'Ribeirão Preto',
    descricao: 'Rock autoral',
    cacheMedio: 1500,
  ),
  musicoTeste(
    id: '2',
    nomeArtistico: 'Duo Acústico Sol',
    generoMusical: 'MPB',
    cidade: 'Franca',
    descricao: 'Voz e violão para eventos intimistas',
    cacheMedio: 800,
  ),
  musicoTeste(
    id: '3',
    nomeArtistico: 'DJ Pulse',
    generoMusical: 'Eletrônica',
    cidade: 'Ribeirão Preto',
    descricao: 'Sets de música eletrônica',
    cacheMedio: 1200,
  ),
];

final _oportunidades = [
  oportunidadeTeste(
    id: '1',
    generoMusical: 'Rock',
    cidade: 'Ribeirão Preto',
    contratante: 'Bar Central',
    donoId: 'e2',
  ),
  oportunidadeTeste(
    id: '2',
    generoMusical: 'MPB',
    cidade: 'Franca',
    contratante: 'Café Cultural',
    donoId: '',
  ),
  oportunidadeTeste(
    id: '3',
    generoMusical: 'Rock',
    cidade: 'Sertãozinho',
    contratante: 'Pub 16',
    donoId: 'e3',
  ),
];

void main() {
  late FakeFirebaseFirestore firestore;
  late OportunidadeProvider provider;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await gravarCatalogo(
      firestore,
      musicos: _musicos,
      oportunidades: _oportunidades,
    );
    provider = OportunidadeProvider(service: servicoFake(firestore: firestore));
    await aguardar();
  });
  tearDown(() => provider.dispose());

  List<String> nomes(List<Musico> musicos) =>
      musicos.map((m) => m.nomeArtistico).toList();

  test('carrega músicos e oportunidades do Firestore', () {
    expect(provider.musicos, hasLength(_musicos.length));
    expect(provider.oportunidades, hasLength(_oportunidades.length));
    expect(provider.tipoOrdenacao, 'nome_asc');
    expect(provider.carregandoMusicos, isFalse);
    expect(provider.carregandoOportunidades, isFalse);
    expect(provider.erroMusicos, isFalse);
    expect(provider.erroOportunidades, isFalse);
  });

  test('sem ninguém logado as listas ficam vazias', () async {
    final deslogado = OportunidadeProvider(
      service: servicoFake(firestore: firestore, uid: null),
    );
    await aguardar();

    expect(deslogado.musicos, isEmpty);
    expect(deslogado.oportunidades, isEmpty);
    expect(deslogado.carregandoMusicos, isFalse);
    deslogado.dispose();
  });

  group('filtros de músicos', () {
    test('filtra por gênero exato', () {
      provider.filtrarMusicos(genero: 'Rock');

      expect(nomes(provider.musicos), ['Banda Eclipse']);
      expect(provider.generoSelecionadoMusicos, 'Rock');
    });

    test('filtra por trecho da cidade sem diferenciar maiúsculas', () {
      provider.filtrarMusicos(cidade: 'ribeirão');

      expect(nomes(provider.musicos), ['Banda Eclipse', 'DJ Pulse']);
    });

    test('gênero vazio não filtra', () {
      provider.filtrarMusicos(genero: '');

      expect(provider.musicos, hasLength(_musicos.length));
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

      expect(provider.musicos, hasLength(_musicos.length));
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

  group('Plano 7: assinantes primeiro', () {
    test('músico assinante sobe, mantendo a ordem escolhida entre os demais', () async {
      await firestore.collection('assinantes').doc('3').set({'desde': DateTime(2026)});
      await aguardar();

      expect(nomes(provider.musicos), ['DJ Pulse', 'Banda Eclipse', 'Duo Acústico Sol']);
      expect(provider.ehAssinante('3'), isTrue);

      // Filtro vem antes: assinante que não atende não aparece.
      provider.filtrarMusicos(genero: 'Rock');
      expect(nomes(provider.musicos), ['Banda Eclipse']);

      provider
        ..filtrarMusicos()
        ..ordenarMusicos('cache_maior');
      expect(nomes(provider.musicos), ['DJ Pulse', 'Banda Eclipse', 'Duo Acústico Sol']);
    });

    test('oportunidade de dono assinante sobe na lista pública', () async {
      await firestore.collection('assinantes').doc('e3').set({'desde': DateTime(2026)});
      await aguardar();

      expect(provider.oportunidades.first.donoId, 'e3');
    });
  });

  group('Plano 15: sugestões', () {
    test('músicos sugeridos: elimina indisponível e quem já tem interesse', () {
      final oportunidade = oportunidadeTeste(
        id: 'x',
        generoMusical: 'Rock',
        cidade: 'Ribeirão Preto',
        donoId: 'e9',
      ).copyWith(cacheOferecido: 2000);

      final todos = provider.musicosSugeridos(
        oportunidade,
        indisponiveis: {},
        comInteresse: {},
      );
      // Banda Eclipse: gênero + cidade + cachê + livre = 90; DJ Pulse:
      // cidade + cachê + livre = 55; Duo (Franca, MPB): 30 → fora.
      expect(todos.map((s) => s.item.nomeArtistico), ['Banda Eclipse', 'DJ Pulse']);
      expect(todos.first.compatibilidade.nota, 90);

      expect(
        provider
            .musicosSugeridos(oportunidade, indisponiveis: {'1'}, comInteresse: {'3'})
            .map((s) => s.item.nomeArtistico),
        isEmpty,
      );
    });

    test('oportunidades sugeridas usam a própria agenda e pulam as com interesse', () async {
      final eu = _musicos.first; // Banda Eclipse: Rock, Ribeirão Preto
      final antes = provider.oportunidadesSugeridas(eu, comInteresse: {});
      expect(antes.map((s) => s.item.id), contains('1'));

      expect(
        provider.oportunidadesSugeridas(eu, comInteresse: {'1'}).map((s) => s.item.id),
        isNot(contains('1')),
      );
    });
  });

  group('Plano 14: formação e equipamento próprio', () {
    setUp(() async {
      await firestore.collection('perfis_musicos').doc('1').update({
        'formacao': 'banda',
        'equipamentoProprio': true,
      });
      await firestore.collection('perfis_musicos').doc('2').update({
        'formacao': 'duo',
      });
      await aguardar();
    });

    test('filtra por formação e por equipamento, combinando com cidade', () {
      provider.filtrarMusicos(formacao: Formacao.duo);
      expect(nomes(provider.musicos), ['Duo Acústico Sol']);

      provider.filtrarMusicos(soEquipamentoProprio: true);
      expect(nomes(provider.musicos), ['Banda Eclipse']);

      provider.filtrarMusicos(cidade: 'franca', soEquipamentoProprio: true);
      expect(provider.musicos, isEmpty);
    });

    test('aplicarFiltroMusicos troca tudo de uma vez e filtroMusicos devolve', () async {
      await firestore.collection('bloqueios').doc('2_2099-03-10').set({
        'usuarioId': '2',
        'dia': '2099-03-10',
      });
      provider.aplicarFiltroMusicos(
        FiltroMusicos(
          cidade: 'ribeirão',
          soEquipamentoProprio: true,
          ordenacao: 'cache_menor',
          livresEm: DateTime(2099, 3, 10),
        ),
      );
      await aguardar();

      expect(nomes(provider.musicos), ['Banda Eclipse']);
      final atual = provider.filtroMusicos;
      expect(atual.cidade, 'ribeirão');
      expect(atual.soEquipamentoProprio, isTrue);
      expect(atual.ordenacao, 'cache_menor');
      expect(atual.livresEm, DateTime(2099, 3, 10));
      expect(atual.ativos, 3);

      provider.aplicarFiltroMusicos(const FiltroMusicos());
      expect(provider.livresEm, isNull);
      expect(provider.musicos, hasLength(_musicos.length));
    });

    test('resetar limpa formação e equipamento', () {
      provider
        ..filtrarMusicos(formacao: Formacao.banda, soEquipamentoProprio: true)
        ..resetarFiltroMusicos();

      expect(provider.formacaoFiltro, isNull);
      expect(provider.soEquipamentoProprio, isFalse);
      expect(provider.musicos, hasLength(_musicos.length));
    });
  });

  group('Plano 13: músicos livres em uma data', () {
    final dia = DateTime(2099, 3, 10);

    Future<void> bloquear(String uid, DateTime data) =>
        servicoFake(firestore: firestore, uid: uid).bloquearDia(uid, data);

    test('tira quem bloqueou o dia ou tem show confirmado nele', () async {
      await bloquear('1', dia);
      await bloquear('2', DateTime(2099, 3, 11)); // outro dia: continua livre
      await firestore.collection('ocupacoes').doc('3_2099-03-10').set({
        'musicoId': '3',
        'dia': '2099-03-10',
        'contratacaoId': 'c1',
      });

      provider.filtrarMusicosLivresEm(DateTime(2099, 3, 10, 21, 30));
      expect(provider.carregandoLivres, isTrue);
      await aguardar();

      expect(provider.carregandoLivres, isFalse);
      expect(provider.livresEm, dia);
      expect(nomes(provider.musicos), ['Duo Acústico Sol']);
    });

    test('combina com gênero e acompanha bloqueios novos em tempo real', () async {
      provider
        ..filtrarMusicos(cidade: 'ribeirão')
        ..filtrarMusicosLivresEm(dia);
      await aguardar();
      expect(nomes(provider.musicos), ['Banda Eclipse', 'DJ Pulse']);

      await bloquear('3', dia);
      await aguardar();
      expect(nomes(provider.musicos), ['Banda Eclipse']);
    });

    test('null tira o filtro; resetar também', () async {
      await bloquear('1', dia);
      provider.filtrarMusicosLivresEm(dia);
      await aguardar();
      expect(provider.musicos, hasLength(2));

      provider.filtrarMusicosLivresEm(null);
      expect(provider.livresEm, isNull);
      expect(provider.musicos, hasLength(_musicos.length));

      provider.filtrarMusicosLivresEm(dia);
      await aguardar();
      provider.resetarFiltroMusicos();
      expect(provider.livresEm, isNull);
      expect(provider.musicos, hasLength(_musicos.length));
    });
  });

  group('ordenação de músicos', () {
    test('nome_asc e nome_desc', () {
      const esperado = ['Banda Eclipse', 'DJ Pulse', 'Duo Acústico Sol'];

      provider.ordenarMusicos('nome_asc');
      expect(nomes(provider.musicos), esperado);

      provider.ordenarMusicos('nome_desc');
      expect(nomes(provider.musicos), esperado.reversed.toList());
    });

    test('cache_maior e cache_menor', () {
      provider.ordenarMusicos('cache_maior');
      expect(provider.musicos.map((m) => m.cacheMedio), [1500, 1200, 800]);

      provider.ordenarMusicos('cache_menor');
      expect(provider.musicos.map((m) => m.cacheMedio), [800, 1200, 1500]);
    });

    test('ordenação é mantida ao aplicar filtro', () {
      provider
        ..ordenarMusicos('cache_menor')
        ..filtrarMusicos(genero: '');

      expect(provider.musicos.map((m) => m.cacheMedio), [800, 1200, 1500]);
    });
  });

  group('filtros de oportunidades', () {
    test('filtra por gênero e cidade e reseta', () {
      provider.filtrarOportunidades(const FiltroOportunidades(genero: 'Rock'));
      expect(provider.oportunidades.map((o) => o.id), unorderedEquals(['1', '3']));

      provider.filtrarOportunidades(const FiltroOportunidades(cidade: 'SERTÃOZINHO'));
      expect(provider.oportunidades.map((o) => o.cidade), ['Sertãozinho']);

      provider.resetarFiltroOportunidades();
      expect(provider.oportunidades, hasLength(_oportunidades.length));
    });
  });

  group('filtro de oportunidades persiste', () {
    bool soRock(OportunidadeProvider p) =>
        p.oportunidades.isNotEmpty &&
        p.oportunidades.every((o) => o.generoMusical == 'Rock');

    test('ao filtrar, pesquisar ou ordenar músicos', () {
      provider.filtrarOportunidades(const FiltroOportunidades(genero: 'Rock'));

      provider
        ..filtrarMusicos(genero: 'MPB')
        ..pesquisarMusicos('Duo')
        ..ordenarMusicos('cache_maior')
        ..resetarFiltroMusicos();

      expect(soRock(provider), isTrue);
    });

    test('ao criar uma oportunidade (volta pelo stream)', () async {
      provider.filtrarOportunidades(const FiltroOportunidades(genero: 'Rock'));

      await provider.criarOportunidade(
        oportunidadeTeste(id: '', generoMusical: 'MPB'),
        'u1',
      );
      await aguardar();

      expect(soRock(provider), isTrue);
      expect(provider.minhasOportunidades('u1'), hasLength(1));
    });
  });

  group('oportunidades do dono', () {
    test('minhasOportunidades filtra pelo dono e ignora uid nulo', () {
      expect(provider.minhasOportunidades('e2').map((o) => o.id), ['1']);
      expect(provider.minhasOportunidades('u1'), isEmpty);
      expect(provider.minhasOportunidades(null), isEmpty);
    });
  });

  group('busca por id', () {
    test('encontra músico mesmo fora do filtro atual', () {
      provider.filtrarMusicos(genero: 'MPB');

      expect(provider.buscarMusicoPorId('1')?.nomeArtistico, 'Banda Eclipse');
      expect(provider.buscarMusicoPorId('nao-existe'), isNull);
    });

    test('encontra oportunidade mesmo fora do filtro atual', () {
      provider.filtrarOportunidades(const FiltroOportunidades(genero: 'MPB'));

      expect(provider.buscarOportunidadePorId('1')?.contratante, 'Bar Central');
      expect(provider.buscarOportunidadePorId('nao-existe'), isNull);
    });
  });

  group('Plano 12: vencidas e agenda do músico', () {
    test('vencida sai da lista pública, mas o dono e a busca por id a veem', () async {
      final ontem = DateTime.now().subtract(const Duration(days: 1));
      await gravarCatalogo(
        firestore,
        oportunidades: [
          oportunidadeTeste(id: 'velha', donoId: 'e2').copyWith(dataEvento: ontem),
        ],
      );
      await aguardar();

      expect(provider.oportunidades.map((o) => o.id), isNot(contains('velha')));
      expect(provider.buscarOportunidadePorId('velha'), isNotNull);
      expect(provider.minhasOportunidades('e2').map((o) => o.id), contains('velha'));
    });

    test('lista pública vem da mais próxima para a mais distante', () async {
      await gravarCatalogo(
        firestore,
        oportunidades: [
          oportunidadeTeste(id: 'antes').copyWith(dataEvento: DateTime(2099, 1, 1)),
        ],
      );
      await aguardar();

      expect(provider.oportunidades.first.id, 'antes');
    });

    test('"só dias livres" usa os bloqueios e as ocupações do próprio usuário', () async {
      await gravarCatalogo(
        firestore,
        oportunidades: [
          oportunidadeTeste(id: 'livre').copyWith(dataEvento: DateTime(2099, 3, 1)),
          oportunidadeTeste(id: 'ocupado').copyWith(dataEvento: DateTime(2099, 3, 2)),
          oportunidadeTeste(id: 'bloqueado').copyWith(dataEvento: DateTime(2099, 3, 3)),
        ],
      );
      final servico = servicoFake(firestore: firestore);
      await servico.bloquearDia('u1', DateTime(2099, 3, 3));
      await firestore.collection('ocupacoes').doc('u1_2099-03-02').set({
        'musicoId': 'u1',
        'dia': '2099-03-02',
        'contratacaoId': 'c1',
      });
      await aguardar();

      expect(provider.oportunidades.map((o) => o.id), containsAll(['livre', 'ocupado', 'bloqueado']));

      provider.filtrarOportunidades(
        const FiltroOportunidades(soDiasLivres: true),
      );
      expect(
        provider.oportunidades.map((o) => o.id),
        allOf(contains('livre'), isNot(contains('ocupado')), isNot(contains('bloqueado'))),
      );
      expect(provider.filtroOportunidades.ativos, 1);

      provider.resetarFiltroOportunidades();
      expect(provider.filtroOportunidades.vazio, isTrue);
    });
  });
}
