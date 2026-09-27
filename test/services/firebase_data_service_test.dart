import 'package:backstage/data/mock_data.dart';
import 'package:backstage/models/casa_show.dart';
import 'package:backstage/models/conversa.dart';
import 'package:backstage/models/interesse.dart';
import 'package:backstage/models/interesse_musico.dart';
import 'package:backstage/models/mensagem.dart';
import 'package:backstage/models/usuario.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

/// Auth fake que simula um cadastro já existente (retomada de cadastro).
class _AuthComEmailEmUso extends MockFirebaseAuth {
  _AuthComEmailEmUso() : super(mockUser: MockUser(uid: 'u1', email: 'a@b.com'));

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    throw FirebaseAuthException(code: 'email-already-in-use');
  }
}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late FirebaseDataService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'u1', email: 'musico@backstage.com'),
    );
    service = FirebaseDataService(auth: auth, firestore: firestore, enabled: true);
  });

  group('estado de autenticação', () {
    test('expõe uid e e-mail do usuário logado', () {
      expect(service.isEnabled, isTrue);
      expect(service.currentUserId, 'u1');
      expect(service.currentUserEmail, 'musico@backstage.com');
    });

    test('desabilitado não expõe usuário mesmo com sessão no Auth', () {
      final desabilitado = FirebaseDataService(
        auth: auth,
        firestore: firestore,
        enabled: false,
      );

      expect(desabilitado.currentUserId, isNull);
      expect(desabilitado.currentUserEmail, isNull);
    });

    test('authUserIds emite o uid e null após logout', () async {
      final eventos = <String?>[];
      final sub = service.authUserIds.listen(eventos.add);

      await Future<void>.delayed(Duration.zero);
      await service.logout();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(eventos.first, 'u1');
      expect(eventos.last, isNull);
    });
  });

  group('cadastrar', () {
    test('cria usuário no Auth e grava usuarios/{uid}', () async {
      final auth = MockFirebaseAuth();
      final service = FirebaseDataService(
        auth: auth,
        firestore: firestore,
        enabled: true,
      );

      final credential = await service.cadastrar(
        nome: 'Músico',
        email: 'novo@backstage.com',
        telefone: '16999999999',
        senha: '123456',
      );

      final uid = credential.user!.uid;
      final doc = await firestore.collection('usuarios').doc(uid).get();
      expect(doc.data()?['nome'], 'Músico');
      expect(doc.data()?['email'], 'novo@backstage.com');
      expect(doc.data()?['telefone'], '16999999999');
      expect(doc.data()?['updatedAt'], isNotNull);
    });

    test('e-mail já em uso retoma o cadastro fazendo login', () async {
      final service = FirebaseDataService(
        auth: _AuthComEmailEmUso(),
        firestore: firestore,
        enabled: true,
      );

      final credential = await service.cadastrar(
        nome: 'Músico',
        email: 'a@b.com',
        telefone: '1',
        senha: '123456',
      );

      expect(credential.user?.uid, 'u1');
      final doc = await firestore.collection('usuarios').doc('u1').get();
      expect(doc.exists, isTrue);
    });
  });

  group('seedDadosIniciais', () {
    test('popula musicos, oportunidades e conversas quando vazias', () async {
      await service.seedDadosIniciais();

      final musicos = await firestore.collection('perfis_musicos').get();
      final oportunidades = await firestore.collection('oportunidades').get();
      final conversas = await firestore.collection('conversas').get();

      expect(musicos.docs.map((d) => d.id), MockData.musicos.map((m) => m.id));
      expect(oportunidades.docs, hasLength(MockData.oportunidades.length));
      expect(conversas.docs, hasLength(MockData.conversas.length));
    });

    test('não sobrescreve coleção que já tem documentos', () async {
      await firestore.collection('perfis_musicos').doc('real').set({
        'nomeArtistico': 'Artista Real',
      });

      await service.seedDadosIniciais();

      final musicos = await firestore.collection('perfis_musicos').get();
      expect(musicos.docs.map((d) => d.id), ['real']);
      // As demais coleções, vazias, recebem o seed normalmente.
      final oportunidades = await firestore.collection('oportunidades').get();
      expect(oportunidades.docs, isNotEmpty);
    });
  });

  group('músicos e oportunidades', () {
    test('listar lê os documentos com Timestamp convertido', () async {
      await service.seedDadosIniciais();

      final musicos = await service.listarMusicos();
      final oportunidades = await service.listarOportunidades();

      expect(musicos.map((m) => m.nomeArtistico), contains('Banda Eclipse'));
      final primeira = oportunidades.firstWhere((o) => o.id == '1');
      expect(primeira.dataEvento, MockData.oportunidades.first.dataEvento);
    });

    test('streams refletem alterações no Firestore', () async {
      final stream = service.streamMusicos();
      final emissoes = <int>[];
      final sub = stream.listen((lista) => emissoes.add(lista.length));

      await Future<void>.delayed(Duration.zero);
      await firestore.collection('perfis_musicos').doc('m9').set({
        'nomeArtistico': 'Nova Banda',
      });
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(emissoes.first, 0);
      expect(emissoes.last, 1);
    });

    test('streams retornam MockData quando desabilitado', () async {
      final desabilitado = FirebaseDataService(
        auth: auth,
        firestore: firestore,
        enabled: false,
      );

      expect(
        await desabilitado.streamOportunidades().first,
        hasLength(MockData.oportunidades.length),
      );
    });
  });

  group('interesses', () {
    final data = DateTime(2026, 3, 21);

    test('salvar, listar só do usuário e remover (oportunidades)', () async {
      await service.salvarInteresse(Interesse(
        id: 'u1_1',
        oportunidadeId: '1',
        usuarioId: 'u1',
        dataHora: data,
      ));
      await service.salvarInteresse(Interesse(
        id: 'u2_1',
        oportunidadeId: '1',
        usuarioId: 'u2',
        dataHora: data,
      ));

      final doUsuario = await service.listarInteresses('u1');
      expect(doUsuario.map((i) => i.id), ['u1_1']);
      expect(doUsuario.single.dataHora, data);

      await service.removerInteresse('u1_1');
      expect(await service.listarInteresses('u1'), isEmpty);
    });

    test('salvar, listar só do usuário e remover (músicos)', () async {
      await service.salvarInteresseMusico(InteresseMusico(
        id: 'u1_2',
        musicoId: '2',
        usuarioId: 'u1',
        dataHora: data,
      ));

      final doUsuario = await service.listarInteressesMusicos('u1');
      expect(doUsuario.single.musicoId, '2');
      expect(await service.listarInteressesMusicos('u2'), isEmpty);

      await service.removerInteresseMusico('u1_2');
      expect(await service.listarInteressesMusicos('u1'), isEmpty);
    });
  });

  group('perfil do músico', () {
    test('carregar retorna null quando não existe', () async {
      expect(await service.carregarPerfilMusico('u1'), isNull);
    });

    test('salvar e carregar usam o uid como id do documento', () async {
      final perfil = MockData.musicos.first.copyWith(id: 'u1');

      await service.salvarPerfilMusico('u1', perfil);
      final carregado = await service.carregarPerfilMusico('u1');

      expect(carregado?.id, 'u1');
      expect(carregado?.nomeArtistico, perfil.nomeArtistico);
    });
  });

  group('usuário', () {
    test('carregar retorna null quando não existe', () async {
      expect(await service.carregarUsuario('u1'), isNull);
    });

    test('salvar com tipoUsuario e assinante, e carregar de volta', () async {
      await service.salvarUsuario(
        uid: 'u1',
        nome: 'Guilherme',
        email: 'g@backstage.com',
        telefone: '16999999999',
        tipoUsuario: TipoUsuario.musico,
        assinante: true,
      );

      final usuario = await service.carregarUsuario('u1');

      expect(usuario?.tipoUsuario, TipoUsuario.musico);
      expect(usuario?.assinante, isTrue);
    });

    test('definirTipoUsuario grava sem apagar outros campos', () async {
      await service.salvarUsuario(
        uid: 'u1',
        nome: 'Guilherme',
        email: 'g@backstage.com',
        telefone: '16999999999',
      );

      await service.definirTipoUsuario('u1', TipoUsuario.casaShow);

      final usuario = await service.carregarUsuario('u1');
      expect(usuario?.tipoUsuario, TipoUsuario.casaShow);
      expect(usuario?.nome, 'Guilherme');
      expect(usuario?.telefone, '16999999999');
    });

    test('salvar sem tipoUsuario não sobrescreve o já gravado (merge)', () async {
      await service.salvarUsuario(
        uid: 'u1',
        nome: 'Guilherme',
        email: 'g@backstage.com',
        telefone: '1',
        tipoUsuario: TipoUsuario.casaShow,
      );

      await service.salvarUsuario(
        uid: 'u1',
        nome: 'Guilherme',
        email: 'g@backstage.com',
        telefone: '2',
      );

      final usuario = await service.carregarUsuario('u1');
      expect(usuario?.tipoUsuario, TipoUsuario.casaShow);
      expect(usuario?.telefone, '2');
    });
  });

  group('estabelecimento', () {
    test('carregar retorna null quando não existe', () async {
      expect(await service.carregarEstabelecimento('u1'), isNull);
    });

    test('salvar e carregar usam o uid como id do documento', () async {
      final estabelecimento = CasaShow(
        id: 'u1',
        nome: 'Bar Central',
        cidade: 'Ribeirão Preto',
        capacidade: 120,
        estilosDesejados: const ['Rock'],
        descricao: 'Bar com música ao vivo.',
        contato: '16999999999',
        cnpj: '12.345.678/0001-90',
      );

      await service.salvarEstabelecimento('u1', estabelecimento);
      final carregado = await service.carregarEstabelecimento('u1');

      expect(carregado?.id, 'u1');
      expect(carregado?.nome, estabelecimento.nome);
    });
  });

  group('disponibilidades', () {
    test('usa id {uid}_{yyyy-MM-dd} e normaliza o horário', () async {
      await service.adicionarDataDisponivel('u1', DateTime(2026, 5, 10, 21, 45));

      final doc = await firestore
          .collection('disponibilidades')
          .doc('u1_2026-05-10')
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['usuarioId'], 'u1');
      expect(doc.data()?['disponivel'], isTrue);
    });

    test('listar retorna só as datas do usuário, ordenadas', () async {
      await service.adicionarDataDisponivel('u1', DateTime(2026, 6, 1));
      await service.adicionarDataDisponivel('u1', DateTime(2026, 5, 1));
      await service.adicionarDataDisponivel('u2', DateTime(2026, 4, 1));

      expect(await service.listarDatasDisponiveis('u1'), [
        DateTime(2026, 5, 1),
        DateTime(2026, 6, 1),
      ]);
    });

    test('remover apaga pelo dia, ignorando o horário', () async {
      await service.adicionarDataDisponivel('u1', DateTime(2026, 5, 10));

      await service.removerDataDisponivel('u1', DateTime(2026, 5, 10, 8));

      expect(await service.listarDatasDisponiveis('u1'), isEmpty);
    });
  });

  group('conversas', () {
    test('salvarConversa grava mensagens embutidas e listarConversas lê de volta', () async {
      final conversa = Conversa(
        id: 'c1',
        nomeContato: 'Pub Groove',
        mensagens: [
          Mensagem(
            id: '1',
            remetenteId: 'u1',
            texto: 'Olá',
            dataHora: DateTime(2026, 3, 21, 10),
            enviadaPorMim: true,
          ),
        ],
      );

      await service.salvarConversa(conversa);
      final conversas = await service.listarConversas();

      expect(conversas.single.nomeContato, 'Pub Groove');
      expect(conversas.single.mensagens.single.texto, 'Olá');
      expect(
        conversas.single.mensagens.single.dataHora,
        DateTime(2026, 3, 21, 10),
      );
    });

    test('salvarConversa faz merge preservando campos extras', () async {
      await firestore.collection('conversas').doc('c1').set({'extra': 1});

      await service.salvarConversa(
        Conversa(id: 'c1', nomeContato: 'Bar', mensagens: []),
      );

      final doc = await firestore.collection('conversas').doc('c1').get();
      expect(doc.data()?['extra'], 1);
      expect(doc.data()?['nomeContato'], 'Bar');
    });
  });

  test('Timestamp gravado é lido como DateTime pelos modelos', () async {
    await firestore.collection('interesses_oportunidades').doc('u1_9').set({
      'oportunidadeId': '9',
      'usuarioId': 'u1',
      'dataHora': Timestamp.fromDate(DateTime(2026, 1, 2, 3, 4)),
    });

    final interesses = await service.listarInteresses('u1');

    expect(interesses.single.dataHora, DateTime(2026, 1, 2, 3, 4));
  });
}
