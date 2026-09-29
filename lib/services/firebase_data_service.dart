import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/firebase/firebase_bootstrap.dart';
import '../data/mock_data.dart';
import '../models/casa_show.dart';
import '../models/conversa.dart';
import '../models/interesse.dart';
import '../models/mensagem.dart';
import '../models/musico.dart';
import '../models/oportunidade.dart';
import '../models/usuario.dart';

class FirebaseDataService {
  /// [enabled] sobrescreve `FirebaseBootstrap.isEnabled` — usado em testes
  /// com instâncias fake de [auth] e [firestore].
  FirebaseDataService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    bool? enabled,
  }) : _auth = auth,
       _firestore = firestore,
       _enabled = enabled;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final bool? _enabled;

  bool get isEnabled => _enabled ?? FirebaseBootstrap.isEnabled;

  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  String? get currentUserId => isEnabled ? auth.currentUser?.uid : null;
  String? get currentUserEmail => isEnabled ? auth.currentUser?.email : null;

  /// Uid atual primeiro, depois cada troca, sem repetição: todo provider que
  /// assinar — cedo ou tarde — recebe o estado atual.
  Stream<String?> get authUserIds => _authUserIds().distinct();

  Stream<String?> _authUserIds() async* {
    yield auth.currentUser?.uid;
    yield* auth.authStateChanges().map((user) => user?.uid);
  }

  Future<UserCredential> login({required String email, required String senha}) {
    return auth.signInWithEmailAndPassword(email: email, password: senha);
  }

  Future<UserCredential> cadastrar({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
  }) async {
    late final UserCredential credential;

    try {
      credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      ).timeout(const Duration(seconds: 15));
    } on FirebaseAuthException catch (error) {
      if (error.code != 'email-already-in-use') rethrow;

      // Retoma um cadastro interrompido somente após validar a senha.
      credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      ).timeout(const Duration(seconds: 15));
    }

    await credential.user?.updateDisplayName(nome).timeout(
      const Duration(seconds: 15),
    );
    await salvarUsuario(
      uid: credential.user!.uid,
      nome: nome,
      email: email,
      telefone: telefone,
    ).timeout(const Duration(seconds: 15));

    return credential;
  }

  Future<void> recuperarSenha(String email) {
    return auth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() {
    return auth.signOut();
  }

  Future<void> salvarUsuario({
    required String uid,
    required String nome,
    required String email,
    required String telefone,
    TipoUsuario? tipoUsuario,
    bool? assinante,
  }) {
    return firestore.collection('usuarios').doc(uid).set({
      'nome': nome,
      'email': email,
      'telefone': telefone,
      if (tipoUsuario != null) 'tipoUsuario': tipoUsuario.name,
      'assinante': ?assinante,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> definirTipoUsuario(String uid, TipoUsuario tipoUsuario) {
    return firestore.collection('usuarios').doc(uid).set({
      'tipoUsuario': tipoUsuario.name,
    }, SetOptions(merge: true));
  }

  Future<Usuario?> carregarUsuario(String uid) async {
    final doc = await firestore.collection('usuarios').doc(uid).get();
    final data = doc.data();
    if (data == null) return null;

    return Usuario.fromMap(doc.id, data);
  }

  Future<CasaShow?> carregarEstabelecimento(String usuarioId) async {
    final doc = await firestore
        .collection('estabelecimentos')
        .doc(usuarioId)
        .get();
    final data = doc.data();
    if (data == null) return null;

    return CasaShow.fromMap(doc.id, data);
  }

  Future<void> salvarEstabelecimento(String usuarioId, CasaShow perfil) {
    return firestore
        .collection('estabelecimentos')
        .doc(usuarioId)
        .set(perfil.toMap(), SetOptions(merge: true));
  }

  Future<void> seedDadosIniciais() async {
    await Future.wait([
      _seedCollection(
        collection: 'perfis_musicos',
        items: {
          for (final musico in MockData.musicos) musico.id: musico.toMap(),
        },
      ),
      _seedCollection(
        collection: 'oportunidades',
        items: {
          for (final oportunidade in MockData.oportunidades)
            oportunidade.id: oportunidade.toMap(),
        },
      ),
    ]);
  }

  Future<void> _seedCollection({
    required String collection,
    required Map<String, Map<String, dynamic>> items,
  }) async {
    final snapshot = await firestore.collection(collection).limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final batch = firestore.batch();
    for (final entry in items.entries) {
      batch.set(firestore.collection(collection).doc(entry.key), entry.value);
    }
    await batch.commit();
  }

  Future<List<Musico>> listarMusicos() async {
    final snapshot = await firestore.collection('perfis_musicos').get();

    return snapshot.docs
        .map((doc) => Musico.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<Oportunidade>> listarOportunidades() async {
    final snapshot = await firestore.collection('oportunidades').get();

    return snapshot.docs
        .map((doc) => Oportunidade.fromMap(doc.id, doc.data()))
        .toList();
  }

  Stream<List<Musico>> streamMusicos() {
    if (!isEnabled) return Stream.value([...MockData.musicos]);
    return firestore.collection('perfis_musicos').snapshots().map(
      (s) => s.docs.map((d) => Musico.fromMap(d.id, d.data())).toList(),
    );
  }

  Stream<List<Oportunidade>> streamOportunidades() {
    if (!isEnabled) return Stream.value([...MockData.oportunidades]);
    return firestore.collection('oportunidades').snapshots().map(
      (s) => s.docs.map((d) => Oportunidade.fromMap(d.id, d.data())).toList(),
    );
  }

  /// Admin é uma *custom claim* do Firebase Auth, aplicada só pelo script
  /// `definir-admin.js` (Admin SDK) — nunca um campo que o usuário grave.
  /// `true` força renovar o token para enxergar uma claim recém-aplicada.
  Future<bool> ehAdmin() async {
    final user = auth.currentUser;
    if (user == null) return false;
    final token = await user.getIdTokenResult(true);
    return token.claims?['admin'] == true;
  }

  Future<void> atualizarOportunidade(Oportunidade oportunidade) {
    return firestore
        .collection('oportunidades')
        .doc(oportunidade.id)
        .set(oportunidade.toMap());
  }

  Future<void> removerOportunidade(String oportunidadeId) {
    return firestore.collection('oportunidades').doc(oportunidadeId).delete();
  }

  /// Grava com id automático e devolve o id criado.
  Future<String> criarOportunidade(Oportunidade oportunidade) async {
    final ref = await firestore
        .collection('oportunidades')
        .add(oportunidade.toMap());
    return ref.id;
  }

  Stream<List<Interesse>> streamInteressesEnviados(String uid) =>
      _streamInteresses('remetenteId', uid);

  Stream<List<Interesse>> streamInteressesRecebidos(String uid) =>
      _streamInteresses('destinatarioId', uid);

  Stream<List<Interesse>> _streamInteresses(String campo, String uid) {
    return firestore
        .collection('interesses')
        .where(campo, isEqualTo: uid)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => Interesse.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> enviarInteresse(Interesse interesse) {
    return firestore
        .collection('interesses')
        .doc(interesse.id)
        .set(interesse.toMap());
  }

  Future<void> cancelarInteresse(String interesseId) {
    return firestore.collection('interesses').doc(interesseId).delete();
  }

  Future<void> recusarInteresse(String interesseId) {
    return firestore.collection('interesses').doc(interesseId).update({
      'status': StatusInteresse.recusado.name,
      'respondidoEm': DateTime.now(),
    });
  }

  /// Aceita o interesse e abre a conversa entre remetente e destinatário no
  /// mesmo batch (id da conversa = id do interesse). Devolve o id da conversa.
  Future<String> aceitarInteresse(
    Interesse interesse, {
    required String nomeDestinatario,
  }) async {
    final conversa = Conversa(
      id: interesse.id,
      participantes: [interesse.remetenteId, interesse.destinatarioId],
      nomes: {
        interesse.remetenteId: interesse.remetenteNome,
        interesse.destinatarioId: nomeDestinatario,
      },
      interesseId: interesse.id,
      mensagens: const [],
      atualizadoEm: DateTime.now(),
    );

    final batch = firestore.batch();
    batch.set(firestore.collection('conversas').doc(conversa.id), conversa.toMap());
    batch.update(firestore.collection('interesses').doc(interesse.id), {
      'status': StatusInteresse.aceito.name,
      'respondidoEm': DateTime.now(),
      'conversaId': conversa.id,
    });
    await batch.commit();
    return conversa.id;
  }

  Future<Musico?> carregarPerfilMusico(String usuarioId) async {
    final doc = await firestore
        .collection('perfis_musicos')
        .doc(usuarioId)
        .get();
    final data = doc.data();
    if (data == null) return null;

    return Musico.fromMap(doc.id, data);
  }

  Future<void> salvarPerfilMusico(String usuarioId, Musico perfil) {
    return firestore
        .collection('perfis_musicos')
        .doc(usuarioId)
        .set(perfil.toMap(), SetOptions(merge: true));
  }

  Future<List<DateTime>> listarDatasDisponiveis(String usuarioId) async {
    final snapshot = await firestore
        .collection('disponibilidades')
        .where('usuarioId', isEqualTo: usuarioId)
        .get();

    final datas =
        snapshot.docs
            .map((doc) => _dateTimeFromValue(doc.data()['data']))
            .toList()
          ..sort();

    return datas;
  }

  Future<void> adicionarDataDisponivel(String usuarioId, DateTime data) {
    return firestore
        .collection('disponibilidades')
        .doc(_disponibilidadeId(usuarioId, data))
        .set({
          'usuarioId': usuarioId,
          'data': DateTime(data.year, data.month, data.day),
          'disponivel': true,
        });
  }

  Future<void> removerDataDisponivel(String usuarioId, DateTime data) {
    return firestore
        .collection('disponibilidades')
        .doc(_disponibilidadeId(usuarioId, data))
        .delete();
  }

  Stream<List<Conversa>> streamConversas(String uid) {
    return firestore
        .collection('conversas')
        .where('participantes', arrayContains: uid)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => Conversa.fromMap(d.id, d.data())).toList(),
        );
  }

  /// `arrayUnion` em vez de regravar a lista: dois participantes escrevendo ao
  /// mesmo tempo não se sobrescrevem.
  Future<void> enviarMensagem(String conversaId, Mensagem mensagem) {
    return firestore.collection('conversas').doc(conversaId).update({
      'mensagens': FieldValue.arrayUnion([mensagem.toMap()]),
      'atualizadoEm': mensagem.dataHora,
    });
  }
}

String _disponibilidadeId(String usuarioId, DateTime data) {
  final dataNormalizada = DateTime(data.year, data.month, data.day);
  final dataIso = dataNormalizada.toIso8601String().substring(0, 10);
  return '${usuarioId}_$dataIso';
}

DateTime _dateTimeFromValue(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();

  try {
    return value.toDate() as DateTime;
  } catch (_) {
    return DateTime.now();
  }
}
