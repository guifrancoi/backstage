import 'package:backstage/models/musico.dart';
import 'package:backstage/models/oportunidade.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

/// Serviço sobre Firebase fake. [uid] nulo = ninguém logado (o `MockUser`
/// ainda existe para um `signIn` posterior); [admin] liga a custom claim.
FirebaseDataService servicoFake({
  FakeFirebaseFirestore? firestore,
  String? uid = 'u1',
  String email = 'u1@backstage.com',
  bool admin = false,
}) {
  return FirebaseDataService(
    auth: MockFirebaseAuth(
      signedIn: uid != null,
      mockUser: MockUser(
        uid: uid ?? 'u1',
        email: email,
        customClaim: admin ? {'admin': true} : null,
      ),
    ),
    firestore: firestore ?? FakeFirebaseFirestore(),
  );
}

/// Deixa listeners e carregamentos assíncronos dos providers concluírem.
Future<void> aguardar() =>
    Future<void>.delayed(const Duration(milliseconds: 50));

Musico musicoTeste({
  String id = 'm1',
  String nomeArtistico = 'Banda Teste',
  String generoMusical = 'Rock',
  String cidade = 'Franca',
  String descricao = 'Banda de rock',
  double cacheMedio = 1000,
}) {
  return Musico(
    id: id,
    nomeArtistico: nomeArtistico,
    generoMusical: generoMusical,
    cidade: cidade,
    descricao: descricao,
    cacheMedio: cacheMedio,
    portfolioLinks: const [],
  );
}

Oportunidade oportunidadeTeste({
  String id = 'o1',
  String titulo = 'Show de sexta',
  String generoMusical = 'Rock',
  String cidade = 'Franca',
  String contratante = 'Bar Central',
  String donoId = 'e1',
}) {
  return Oportunidade(
    id: id,
    titulo: titulo,
    descricao: 'Show de 2 horas',
    cidade: cidade,
    generoMusical: generoMusical,
    dataEvento: DateTime(2026, 11, 20),
    cacheOferecido: 1200,
    contratante: contratante,
    donoId: donoId,
    logradouro: 'Rua A',
    numero: '10',
    estado: 'SP',
  );
}

/// Grava músicos e oportunidades no Firestore fake (id do modelo = doc id).
Future<void> gravarCatalogo(
  FakeFirebaseFirestore firestore, {
  List<Musico> musicos = const [],
  List<Oportunidade> oportunidades = const [],
}) async {
  for (final musico in musicos) {
    await firestore
        .collection('perfis_musicos')
        .doc(musico.id)
        .set(musico.toMap());
  }
  for (final oportunidade in oportunidades) {
    await firestore
        .collection('oportunidades')
        .doc(oportunidade.id)
        .set(oportunidade.toMap());
  }
}
