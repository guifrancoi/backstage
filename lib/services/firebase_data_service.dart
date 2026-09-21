import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/firebase/firebase_bootstrap.dart';
import '../data/mock_data.dart';
import '../models/conversa.dart';
import '../models/interesse.dart';
import '../models/interesse_musico.dart';
import '../models/musico.dart';
import '../models/oportunidade.dart';

class FirebaseDataService {
  FirebaseDataService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth,
      _firestore = firestore;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  bool get isEnabled => FirebaseBootstrap.isEnabled;

  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  String? get currentUserId => isEnabled ? auth.currentUser?.uid : null;
  String? get currentUserEmail => isEnabled ? auth.currentUser?.email : null;

  Stream<String?> get authUserIds {
    return auth.authStateChanges().map((user) => user?.uid);
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
  }) {
    return firestore.collection('usuarios').doc(uid).set({
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> seedDadosIniciais() async {
    await Future.wait([
      _seedCollection(
        collection: 'musicos',
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
      _seedCollection(
        collection: 'conversas',
        items: {
          for (final conversa in MockData.conversas)
            conversa.id: conversa.toMap(),
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
    final snapshot = await firestore.collection('musicos').get();

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
    return firestore.collection('musicos').snapshots().map(
      (s) => s.docs.map((d) => Musico.fromMap(d.id, d.data())).toList(),
    );
  }

  Stream<List<Oportunidade>> streamOportunidades() {
    if (!isEnabled) return Stream.value([...MockData.oportunidades]);
    return firestore.collection('oportunidades').snapshots().map(
      (s) => s.docs.map((d) => Oportunidade.fromMap(d.id, d.data())).toList(),
    );
  }

  Future<List<Interesse>> listarInteresses(String usuarioId) async {
    final snapshot = await firestore
        .collection('interesses_oportunidades')
        .where('usuarioId', isEqualTo: usuarioId)
        .get();

    return snapshot.docs
        .map((doc) => Interesse.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<InteresseMusico>> listarInteressesMusicos(
    String usuarioId,
  ) async {
    final snapshot = await firestore
        .collection('interesses_musicos')
        .where('usuarioId', isEqualTo: usuarioId)
        .get();

    return snapshot.docs
        .map((doc) => InteresseMusico.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> salvarInteresse(Interesse interesse) {
    return firestore
        .collection('interesses_oportunidades')
        .doc(interesse.id)
        .set(interesse.toMap());
  }

  Future<void> removerInteresse(String interesseId) {
    return firestore
        .collection('interesses_oportunidades')
        .doc(interesseId)
        .delete();
  }

  Future<void> salvarInteresseMusico(InteresseMusico interesse) {
    return firestore
        .collection('interesses_musicos')
        .doc(interesse.id)
        .set(interesse.toMap());
  }

  Future<void> removerInteresseMusico(String interesseId) {
    return firestore.collection('interesses_musicos').doc(interesseId).delete();
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

  Future<List<Conversa>> listarConversas() async {
    final snapshot = await firestore.collection('conversas').get();

    return snapshot.docs
        .map((doc) => Conversa.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> salvarConversa(Conversa conversa) {
    return firestore
        .collection('conversas')
        .doc(conversa.id)
        .set(conversa.toMap(), SetOptions(merge: true));
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
