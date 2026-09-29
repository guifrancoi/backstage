import 'package:backstage/data/mock_data.dart';
import 'package:backstage/models/casa_show.dart';
import 'package:backstage/models/conversa.dart';
import 'package:backstage/models/interesse.dart';
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

    test('authUserIds entrega o uid atual a quem assinar depois', () async {
      final primeiro = await service.authUserIds.first;
      await Future<void>.delayed(Duration.zero);
      final tardio = await service.authUserIds.first;

      expect(primeiro, 'u1');
      expect(tardio, 'u1');
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
    test('popula musicos e oportunidades quando vazias; não semeia conversas', () async {
      await service.seedDadosIniciais();

      final musicos = await firestore.collection('perfis_musicos').get();
      final oportunidades = await firestore.collection('oportunidades').get();
      final conversas = await firestore.collection('conversas').get();

      expect(musicos.docs.map((d) => d.id), MockData.musicos.map((m) => m.id));
      expect(oportunidades.docs, hasLength(MockData.oportunidades.length));
      expect(conversas.docs, isEmpty);
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

  group('oportunidades do dono', () {
    test('criarOportunidade grava com id automático e donoId', () async {
      final id = await service.criarOportunidade(
        MockData.oportunidades.first.copyWith(donoId: 'e1'),
      );

      final doc = await firestore.collection('oportunidades').doc(id).get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['donoId'], 'e1');
    });
  });

  group('interesses', () {
    Interesse candidatura() => Interesse(
      id: Interesse.idCandidatura('m1', 'o1'),
      tipo: TipoInteresse.candidatura,
      remetenteId: 'm1',
      remetenteNome: 'Músico',
      destinatarioId: 'e1',
      musicoId: 'm1',
      musicoNome: 'The VooDooS',
      oportunidadeId: 'o1',
      oportunidadeTitulo: 'Show',
      criadoEm: DateTime(2026, 9, 28),
    );

    test('enviados e recebidos são separados por remetente/destinatário', () async {
      await service.enviarInteresse(candidatura());

      final enviadosM1 = await service.streamInteressesEnviados('m1').first;
      final recebidosE1 = await service.streamInteressesRecebidos('e1').first;
      final recebidosM1 = await service.streamInteressesRecebidos('m1').first;

      expect(enviadosM1.single.id, 'm1_op_o1');
      expect(recebidosE1.single.status, StatusInteresse.pendente);
      expect(recebidosM1, isEmpty);
    });

    test('recusar muda o status e grava a data da resposta', () async {
      await service.enviarInteresse(candidatura());

      await service.recusarInteresse('m1_op_o1');

      final doc = await firestore.collection('interesses').doc('m1_op_o1').get();
      expect(doc.data()?['status'], 'recusado');
      expect(doc.data()?['respondidoEm'], isNotNull);
    });

    test('cancelar apaga o interesse', () async {
      await service.enviarInteresse(candidatura());

      await service.cancelarInteresse('m1_op_o1');

      final doc = await firestore.collection('interesses').doc('m1_op_o1').get();
      expect(doc.exists, isFalse);
    });

    test('aceitar abre a conversa com os dois participantes', () async {
      await service.enviarInteresse(candidatura());

      final conversaId = await service.aceitarInteresse(
        candidatura(),
        nomeDestinatario: 'Bar Central',
      );

      final interesse = await firestore
          .collection('interesses')
          .doc('m1_op_o1')
          .get();
      expect(interesse.data()?['status'], 'aceito');
      expect(interesse.data()?['conversaId'], conversaId);

      final conversa = await firestore.collection('conversas').doc(conversaId).get();
      expect(conversa.data()?['participantes'], ['m1', 'e1']);
      expect(conversa.data()?['nomes'], {'m1': 'Músico', 'e1': 'Bar Central'});
      expect(conversa.data()?['interesseId'], 'm1_op_o1');
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
    Future<void> criar(String id, List<String> participantes) {
      return firestore.collection('conversas').doc(id).set(
        Conversa(
          id: id,
          participantes: participantes,
          nomes: const {},
          mensagens: const [],
        ).toMap(),
      );
    }

    test('streamConversas traz só as conversas em que o uid participa', () async {
      await criar('c1', ['m1', 'e1']);
      await criar('c2', ['m2', 'e2']);

      final conversas = await service.streamConversas('m1').first;

      expect(conversas.map((c) => c.id), ['c1']);
    });

    test('enviarMensagem acrescenta sem regravar as anteriores', () async {
      await criar('c1', ['m1', 'e1']);
      final data = DateTime(2026, 3, 21, 10);

      await service.enviarMensagem(
        'c1',
        Mensagem(id: '1', remetenteId: 'm1', texto: 'Olá', dataHora: data),
      );
      await service.enviarMensagem(
        'c1',
        Mensagem(id: '2', remetenteId: 'e1', texto: 'Oi!', dataHora: data),
      );

      final conversa = (await service.streamConversas('e1').first).single;
      expect(conversa.mensagens.map((m) => m.texto), ['Olá', 'Oi!']);
      expect(conversa.mensagens.first.dataHora, data);
    });
  });

  test('Timestamp gravado é lido como DateTime pelos modelos', () async {
    await firestore.collection('interesses').doc('m1_op_9').set({
      'tipo': 'candidatura',
      'remetenteId': 'm1',
      'destinatarioId': 'e1',
      'status': 'pendente',
      'criadoEm': Timestamp.fromDate(DateTime(2026, 1, 2, 3, 4)),
    });

    final interesses = await service.streamInteressesEnviados('m1').first;

    expect(interesses.single.criadoEm, DateTime(2026, 1, 2, 3, 4));
  });
}
