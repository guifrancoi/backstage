import 'package:backstage/data/mock_data.dart';
import 'package:backstage/models/musico.dart';
import 'package:backstage/models/usuario.dart';
import 'package:backstage/providers/agenda_provider.dart';
import 'package:backstage/providers/auth_provider.dart';
import 'package:backstage/providers/chat_provider.dart';
import 'package:backstage/providers/oportunidade_provider.dart';
import 'package:backstage/providers/perfil_provider.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

/// Providers com Firebase "ligado" (enabled: true) sobre instâncias fake.

/// Serviço cujo login falha com o erro informado.
class _ServicoComErroNoLogin extends FirebaseDataService {
  _ServicoComErroNoLogin(this.erro)
    : super(
        auth: MockFirebaseAuth(),
        firestore: FakeFirebaseFirestore(),
        enabled: true,
      );

  final Exception erro;

  @override
  Future<UserCredential> login({required String email, required String senha}) =>
      Future.error(erro);
}

final _musicoCompleto = Musico(
  id: '',
  nomeArtistico: 'Banda',
  generoMusical: 'Rock',
  cidade: 'Franca',
  descricao: 'Banda de rock',
  cacheMedio: 1000,
  portfolioLinks: const [],
  datasDisponiveis: const [],
);

const _estabelecimentoCompleto = {
  'nome': 'Bar Central',
  'cidade': 'Franca',
  'logradouro': 'Rua A',
  'numero': '10',
  'estado': 'SP',
  'contato': '16 99999-9999',
};

/// Deixa listeners, seed e carregamentos assíncronos concluírem.
Future<void> _aguardar() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  late FakeFirebaseFirestore firestore;
  late FirebaseDataService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = FirebaseDataService(
      auth: MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'u1', email: 'musico@backstage.com'),
      ),
      firestore: firestore,
      enabled: true,
    );
  });

  group('AuthProvider', () {
    test('inicia logado quando há sessão no Firebase', () {
      final provider = AuthProvider(service: service);

      expect(provider.isLoggedIn, isTrue);
      expect(provider.userId, 'u1');
      expect(provider.userEmail, 'musico@backstage.com');
    });

    test('login com sucesso preenche a sessão', () async {
      final provider = AuthProvider(
        service: FirebaseDataService(
          auth: MockFirebaseAuth(
            mockUser: MockUser(uid: 'u7', email: 'a@b.com'),
          ),
          firestore: firestore,
          enabled: true,
        ),
      );

      expect(await provider.login(email: 'a@b.com', senha: '123456'), isTrue);
      expect(provider.isLoggedIn, isTrue);
      expect(provider.userId, 'u7');
      expect(provider.isLoading, isFalse);
    });

    test('cadastrar cria o documento em usuarios', () async {
      final provider = AuthProvider(
        service: FirebaseDataService(
          auth: MockFirebaseAuth(),
          firestore: firestore,
          enabled: true,
        ),
      );

      final ok = await provider.cadastrar(
        nome: 'Músico',
        email: 'novo@backstage.com',
        telefone: '16999999999',
        senha: '123456',
      );

      expect(ok, isTrue);
      final doc = await firestore.collection('usuarios').doc(provider.userId).get();
      expect(doc.data()?['email'], 'novo@backstage.com');
    });

    final errosAuth = {
      'wrong-password': 'E-mail ou senha invalidos.',
      'invalid-credential': 'E-mail ou senha invalidos.',
      'invalid-email': 'E-mail invalido.',
      'user-disabled': 'Usuario desativado.',
      'codigo-desconhecido': 'Nao foi possivel concluir a autenticacao.',
    };
    for (final MapEntry(key: codigo, value: mensagem) in errosAuth.entries) {
      test('login mapeia FirebaseAuthException "$codigo" para PT-BR', () async {
        final provider = AuthProvider(
          service: _ServicoComErroNoLogin(FirebaseAuthException(code: codigo)),
        );

        expect(await provider.login(email: 'a@b.com', senha: 'x'), isFalse);
        expect(provider.errorMessage, mensagem);
        expect(provider.isLoggedIn, isFalse);
        expect(provider.isLoading, isFalse);
      });
    }

    test('login mapeia permission-denied do Firestore', () async {
      final provider = AuthProvider(
        service: _ServicoComErroNoLogin(
          FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
        ),
      );

      await provider.login(email: 'a@b.com', senha: 'x');

      expect(provider.errorMessage, 'Sem permissao para salvar os dados do cadastro.');
    });

    test('sessão restaurada carrega nome e tipoUsuario do Firestore', () async {
      await firestore.collection('usuarios').doc('u1').set({
        'nome': 'Guilherme',
        'tipoUsuario': 'casaShow',
      });

      final provider = AuthProvider(service: service);
      await _aguardar();

      expect(provider.tipoUsuario, TipoUsuario.casaShow);
      expect(provider.nomeExibicao, 'Guilherme');

      await provider.logout();
      expect(provider.tipoUsuario, isNull);
    });

    test('nomeExibicao cai para o e-mail sem nome cadastrado', () async {
      final provider = AuthProvider(service: service);
      await _aguardar();

      expect(provider.nomeExibicao, 'musico@backstage.com');
    });

    test('precisaCompletarPerfil exige tipo e perfil completo', () async {
      final provider = AuthProvider(service: service);

      expect(await provider.precisaCompletarPerfil(), isTrue);

      final ok = await provider.completarCadastro(TipoUsuario.musico);

      expect(ok, isTrue);
      expect(provider.tipoUsuario, TipoUsuario.musico);
      final doc = await firestore.collection('usuarios').doc('u1').get();
      expect(doc.data()?['tipoUsuario'], 'musico');

      // Tipo escolhido, mas sem perfil: continua no onboarding (passo 2).
      expect(await provider.precisaCompletarPerfil(), isTrue);

      // Perfil em branco (como o antigo perfil automático) também não basta.
      await firestore.collection('perfis_musicos').doc('u1').set({
        'nomeArtistico': 'Musico Teste',
        'generoMusical': '',
      });
      expect(await provider.precisaCompletarPerfil(), isTrue);

      await firestore.collection('perfis_musicos').doc('u1').set(_musicoCompleto.toMap());
      expect(await provider.precisaCompletarPerfil(), isFalse);
    });

    test('dono precisa de estabelecimento completo', () async {
      await firestore.collection('usuarios').doc('u1').set({'tipoUsuario': 'casaShow'});
      final provider = AuthProvider(service: service);

      expect(await provider.precisaCompletarPerfil(), isTrue);

      await firestore.collection('estabelecimentos').doc('u1').set(_estabelecimentoCompleto);
      expect(await provider.precisaCompletarPerfil(), isFalse);
    });

    test('admin (custom claim) atua nos dois papéis e pula o onboarding', () async {
      final provider = AuthProvider(
        service: FirebaseDataService(
          auth: MockFirebaseAuth(
            signedIn: true,
            mockUser: MockUser(uid: 'adm', customClaim: {'admin': true}),
          ),
          firestore: firestore,
          enabled: true,
        ),
      );

      expect(await provider.precisaCompletarPerfil(), isFalse);
      expect(provider.isAdmin, isTrue);
      expect(provider.atuaComoMusico, isTrue);
      expect(provider.atuaComoDono, isTrue);

      await provider.logout();
      expect(provider.isAdmin, isFalse);
    });

    test('campo admin gravado em usuarios não dá poder de admin', () async {
      await firestore.collection('usuarios').doc('u1').set({
        'tipoUsuario': 'musico',
        'admin': true,
      });
      final provider = AuthProvider(service: service);
      await _aguardar();

      expect(provider.isAdmin, isFalse);
      expect(provider.atuaComoDono, isFalse);
    });
  });

  group('OportunidadeProvider', () {
    late OportunidadeProvider provider;

    tearDown(() => provider.dispose());

    test('faz seed e lê músicos e oportunidades do Firestore', () async {
      provider = OportunidadeProvider(service: service);
      await _aguardar();

      expect(provider.musicos, isNotEmpty);
      expect(provider.oportunidades, isNotEmpty);
      final musicos = await firestore.collection('perfis_musicos').get();
      expect(musicos.docs, isNotEmpty);
    });

    test('criarOportunidade grava com o donoId e volta pelo stream', () async {
      provider = OportunidadeProvider(service: service);
      await _aguardar();

      final ok = await provider.criarOportunidade(
        MockData.oportunidades.first.copyWith(titulo: 'Minha vaga', donoId: ''),
        'u1',
      );
      await _aguardar();

      expect(ok, isTrue);
      expect(provider.minhasOportunidades('u1').map((o) => o.titulo), [
        'Minha vaga',
      ]);
    });

    test('filtro de oportunidades persiste quando chegam dados do Firestore', () async {
      provider = OportunidadeProvider(service: service);
      await _aguardar();
      provider.filtrarOportunidades(genero: 'Rock');

      await firestore.collection('oportunidades').doc('nova').set({
        'titulo': 'Vaga MPB nova',
        'generoMusical': 'MPB',
        'dataEvento': DateTime(2026, 5, 1),
      });
      await _aguardar();

      expect(provider.oportunidades, isNotEmpty);
      expect(provider.oportunidades.every((o) => o.generoMusical == 'Rock'), isTrue);
      expect(provider.buscarOportunidadePorId('nova')?.titulo, 'Vaga MPB nova');
    });

    test('reassina o catálogo ao sair e entrar de novo (não fica congelado)', () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'u1', email: 'a@b.com'),
      );
      provider = OportunidadeProvider(
        service: FirebaseDataService(auth: auth, firestore: firestore, enabled: true),
      );
      await _aguardar();
      expect(provider.musicos, isNotEmpty);

      await auth.signOut();
      await _aguardar();
      expect(provider.musicos, isEmpty);

      await firestore.collection('perfis_musicos').doc('recem-criado').set({
        'nomeArtistico': 'Criado com a sessão fechada',
      });
      await auth.signInWithEmailAndPassword(email: 'a@b.com', password: 'x');
      await _aguardar();

      expect(provider.buscarMusicoPorId('recem-criado'), isNotNull);
      expect(provider.carregandoMusicos, isFalse);
    });

    test('com Firebase nunca mostra o catálogo do MockData', () {
      provider = OportunidadeProvider(
        service: FirebaseDataService(
          auth: MockFirebaseAuth(),
          firestore: firestore,
          enabled: true,
        ),
      );

      expect(provider.musicos, isEmpty);
      expect(provider.oportunidades, isEmpty);
    });

    test('itens ocultos (da conta admin) não aparecem para os outros', () async {
      await firestore.collection('oportunidades').doc('oculta').set({
        'titulo': 'Teste do admin',
        'donoId': 'adm',
        'oculto': true,
        'dataEvento': DateTime(2026, 5, 1),
      });
      await firestore.collection('perfis_musicos').doc('adm').set({
        'nomeArtistico': 'Artista do admin',
        'oculto': true,
      });

      provider = OportunidadeProvider(service: service);
      await _aguardar();

      expect(provider.oportunidades.map((o) => o.id), isNot(contains('oculta')));
      expect(provider.musicos.map((m) => m.id), isNot(contains('adm')));
    });

    test('admin vê os ocultos e o que cria sai oculto', () async {
      await firestore.collection('oportunidades').doc('oculta').set({
        'titulo': 'Teste do admin',
        'donoId': 'adm',
        'oculto': true,
        'dataEvento': DateTime(2026, 5, 1),
      });
      provider = OportunidadeProvider(
        service: FirebaseDataService(
          auth: MockFirebaseAuth(
            signedIn: true,
            mockUser: MockUser(uid: 'adm', customClaim: {'admin': true}),
          ),
          firestore: firestore,
          enabled: true,
        ),
      );
      await _aguardar();

      expect(provider.oportunidades.map((o) => o.id), contains('oculta'));

      await provider.criarOportunidade(
        MockData.oportunidades.first.copyWith(titulo: 'Nova do admin'),
        'adm',
      );
      await _aguardar();

      final criada = provider.minhasOportunidades('adm').firstWhere(
        (o) => o.titulo == 'Nova do admin',
      );
      expect(criada.oculto, isTrue);
    });

    test('atualizarOportunidade mantém dono e remover apaga', () async {
      await firestore.collection('oportunidades').doc('minha').set({
        'titulo': 'Antiga',
        'donoId': 'u1',
        'dataEvento': DateTime(2026, 5, 1),
      });
      provider = OportunidadeProvider(service: service);
      await _aguardar();

      final original = provider.buscarOportunidadePorId('minha')!;
      final ok = await provider.atualizarOportunidade(
        original.copyWith(titulo: 'Nova', cacheOferecido: 900, donoId: 'outro'),
      );
      await _aguardar();

      expect(ok, isTrue);
      final doc = await firestore.collection('oportunidades').doc('minha').get();
      expect(doc.data()?['titulo'], 'Nova');
      expect(doc.data()?['cacheOferecido'], 900);
      expect(doc.data()?['donoId'], 'u1');

      expect(await provider.removerOportunidade('minha'), isTrue);
      await _aguardar();
      expect(provider.buscarOportunidadePorId('minha'), isNull);
    });

    test('novos músicos no Firestore aparecem na lista em tempo real', () async {
      provider = OportunidadeProvider(service: service);
      await _aguardar();
      final antes = provider.musicos.length;

      await firestore.collection('perfis_musicos').doc('novo').set({
        'nomeArtistico': 'Nova Banda',
        'generoMusical': 'Jazz',
      });
      await _aguardar();

      expect(provider.musicos, hasLength(antes + 1));
      expect(provider.buscarMusicoPorId('novo')?.nomeArtistico, 'Nova Banda');
    });
  });

  group('AgendaProvider', () {
    late AgendaProvider provider;

    tearDown(() => provider.dispose());

    test('carrega do Firestore substituindo as datas locais', () async {
      await service.adicionarDataDisponivel('u1', DateTime(2026, 8, 15));

      provider = AgendaProvider(service: service);
      await _aguardar();

      expect(provider.datasDisponiveis, [DateTime(2026, 8, 15)]);
    });

    test('adicionar e remover persistem com id {uid}_{data}', () async {
      provider = AgendaProvider(service: service);
      await _aguardar();

      await provider.adicionarData(DateTime(2026, 9, 1, 14));
      final doc = firestore.collection('disponibilidades').doc('u1_2026-09-01');
      expect((await doc.get()).exists, isTrue);

      await provider.removerData(DateTime(2026, 9, 1));
      expect((await doc.get()).exists, isFalse);
    });
  });

  group('PerfilProvider', () {
    late PerfilProvider provider;

    tearDown(() => provider.dispose());

    test('músico sem perfil não ganha perfil automático', () async {
      await firestore.collection('usuarios').doc('u1').set({
        'nome': 'Musico Teste',
        'tipoUsuario': 'musico',
      });

      provider = PerfilProvider(service: service);
      await _aguardar();

      expect(provider.perfilMusico, isNull);
      expect(provider.isLoading, isFalse);
      final doc = await firestore.collection('perfis_musicos').doc('u1').get();
      expect(doc.exists, isFalse);
    });

    test('ao trocar de conta descarta o perfil anterior', () async {
      await firestore.collection('usuarios').doc('u1').set({'tipoUsuario': 'musico'});
      await firestore.collection('perfis_musicos').doc('u1').set({
        'nomeArtistico': 'Banda da Conta Antiga',
      });
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'u1'),
      );
      provider = PerfilProvider(
        service: FirebaseDataService(auth: auth, firestore: firestore, enabled: true),
      );
      await _aguardar();
      expect(provider.perfilMusico?.nomeArtistico, 'Banda da Conta Antiga');

      await auth.signOut();
      await _aguardar();

      expect(provider.perfilMusico, isNull);
    });

    test('dono carrega só o estabelecimento', () async {
      await firestore.collection('usuarios').doc('u1').set({'tipoUsuario': 'casaShow'});
      await firestore.collection('perfis_musicos').doc('u1').set({'nomeArtistico': 'X'});
      await firestore.collection('estabelecimentos').doc('u1').set(_estabelecimentoCompleto);

      provider = PerfilProvider(service: service);
      await _aguardar();

      expect(provider.perfilMusico, isNull);
      expect(provider.perfilEstabelecimento?.nome, 'Bar Central');
    });

    test('salvarPerfilMusico grava em perfis_musicos/{uid}', () async {
      await firestore.collection('usuarios').doc('u1').set({'tipoUsuario': 'musico'});
      provider = PerfilProvider(service: service);
      await _aguardar();

      final ok = await provider.salvarPerfilMusico(_musicoCompleto);

      expect(ok, isTrue);
      final doc = await firestore.collection('perfis_musicos').doc('u1').get();
      expect(doc.data()?['nomeArtistico'], 'Banda');
      expect(doc.data()?['oculto'], isFalse);
      expect(provider.perfilMusico?.id, 'u1');
    });

    test('admin carrega os dois perfis e grava oculto', () async {
      await firestore.collection('estabelecimentos').doc('adm').set(_estabelecimentoCompleto);
      provider = PerfilProvider(
        service: FirebaseDataService(
          auth: MockFirebaseAuth(
            signedIn: true,
            mockUser: MockUser(uid: 'adm', customClaim: {'admin': true}),
          ),
          firestore: firestore,
          enabled: true,
        ),
      );
      await _aguardar();

      expect(provider.perfilEstabelecimento?.nome, 'Bar Central');

      await provider.salvarPerfilMusico(_musicoCompleto);

      final doc = await firestore.collection('perfis_musicos').doc('adm').get();
      expect(doc.data()?['oculto'], isTrue);
    });
  });

  group('ChatProvider', () {
    late ChatProvider provider;

    tearDown(() => provider.dispose());

    test('carrega só conversas do usuário e persiste mensagens enviadas', () async {
      await firestore.collection('conversas').doc('c1').set({
        'participantes': ['u1', 'e1'],
        'nomes': {'u1': 'Eu', 'e1': 'Bar Central'},
        'mensagens': [],
      });
      await firestore.collection('conversas').doc('c2').set({
        'participantes': ['x', 'y'],
        'mensagens': [],
      });

      provider = ChatProvider(service: service);
      await _aguardar();

      expect(provider.conversas.map((c) => c.id), ['c1']);
      expect(provider.conversas.single.nomeContato(provider.meuUid), 'Bar Central');

      await provider.enviarMensagem('c1', 'Mensagem nova');
      await _aguardar();

      final doc = await firestore.collection('conversas').doc('c1').get();
      final mensagens = doc.data()?['mensagens'] as List;
      expect((mensagens.last as Map)['texto'], 'Mensagem nova');
      expect((mensagens.last as Map)['remetenteId'], 'u1');
      expect(provider.buscarConversaPorId('c1')?.ultimaMensagem, 'Mensagem nova');
    });
  });
}
