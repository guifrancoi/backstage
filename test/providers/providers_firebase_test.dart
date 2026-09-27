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

    test('precisaCompletarPerfil é true sem tipoUsuario e false depois de completarCadastro', () async {
      final provider = AuthProvider(service: service);

      expect(await provider.precisaCompletarPerfil(), isTrue);

      final ok = await provider.completarCadastro(TipoUsuario.musico);

      expect(ok, isTrue);
      expect(await provider.precisaCompletarPerfil(), isFalse);
      final doc = await firestore.collection('usuarios').doc('u1').get();
      expect(doc.data()?['tipoUsuario'], 'musico');
    });
  });

  group('OportunidadeProvider', () {
    late OportunidadeProvider provider;

    tearDown(() => provider.dispose());

    test('faz seed, lê do Firestore e marca interesses salvos do usuário', () async {
      await firestore.collection('interesses_oportunidades').doc('u1_2').set({
        'oportunidadeId': '2',
        'usuarioId': 'u1',
        'dataHora': DateTime(2026, 3, 1),
      });

      provider = OportunidadeProvider(service: service);
      await _aguardar();

      expect(provider.jaDemonstrouInteresse('2'), isTrue);
      expect(provider.jaDemonstrouInteresse('1'), isFalse);
      final musicos = await firestore.collection('perfis_musicos').get();
      expect(musicos.docs, isNotEmpty);
    });

    test('interesse usa o uid logado (não o id fixo da tela) e persiste', () async {
      provider = OportunidadeProvider(service: service);
      await _aguardar();

      await provider.demonstrarInteresse(
        oportunidadeId: '1',
        usuarioId: 'casa_show_logada_1',
      );

      final doc = await firestore
          .collection('interesses_oportunidades')
          .doc('u1_1')
          .get();
      expect(doc.data()?['usuarioId'], 'u1');

      await provider.removerInteresse('1');
      final removido = await firestore
          .collection('interesses_oportunidades')
          .doc('u1_1')
          .get();
      expect(removido.exists, isFalse);
    });

    test('interesse em músico persiste em interesses_musicos', () async {
      provider = OportunidadeProvider(service: service);
      await _aguardar();

      await provider.demonstrarInteresseEmMusico(
        musicoId: '2',
        usuarioId: 'casa_show_logada_1',
      );

      final doc = await firestore.collection('interesses_musicos').doc('u1_2').get();
      expect(doc.data()?['musicoId'], '2');
      expect(provider.musicosComInteresse.map((m) => m.id), ['2']);
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

    test('cria e salva o perfil inicial quando não existe', () async {
      provider = PerfilProvider(service: service);
      await _aguardar();

      expect(provider.perfilMusico?.id, 'u1');
      final doc = await firestore.collection('perfis_musicos').doc('u1').get();
      expect(doc.exists, isTrue);
    });

    test('carrega perfil existente e salva atualizações', () async {
      await firestore.collection('perfis_musicos').doc('u1').set({
        'nomeArtistico': 'Perfil Salvo',
      });

      provider = PerfilProvider(service: service);
      await _aguardar();
      expect(provider.perfilMusico?.nomeArtistico, 'Perfil Salvo');

      await provider.atualizarPerfil(
        nomeArtistico: 'Atualizado',
        generoMusical: 'Rock',
        cidade: 'Franca',
        cacheMedio: 100,
        descricao: 'D',
        portfolioLinks: const [],
      );

      final doc = await firestore.collection('perfis_musicos').doc('u1').get();
      expect(doc.data()?['nomeArtistico'], 'Atualizado');
    });
  });

  group('ChatProvider', () {
    late ChatProvider provider;

    tearDown(() => provider.dispose());

    test('carrega conversas do Firestore e persiste mensagens enviadas', () async {
      provider = ChatProvider(service: service);
      await _aguardar();

      final conversa = provider.conversas.first;
      await provider.enviarMensagem(conversa.id, 'Mensagem nova');

      final doc = await firestore.collection('conversas').doc(conversa.id).get();
      final mensagens = doc.data()?['mensagens'] as List;
      expect((mensagens.last as Map)['texto'], 'Mensagem nova');
      expect((mensagens.last as Map)['remetenteId'], 'u1');
    });
  });
}
