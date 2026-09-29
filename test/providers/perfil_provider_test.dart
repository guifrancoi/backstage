import 'package:backstage/models/casa_show.dart';
import 'package:backstage/providers/perfil_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/firebase_fake.dart';

// Carregamento por papel, troca de conta e admin: providers_firebase_test.dart.
void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() => firestore = FakeFirebaseFirestore());

  CasaShow estabelecimento() => CasaShow(
    id: '',
    nome: 'Bar Central',
    cidade: 'Franca',
    logradouro: 'Rua A',
    numero: '10',
    estado: 'SP',
    capacidade: 0,
    estilosDesejados: const [],
    descricao: '',
    contato: '16 99999-9999',
    cnpj: '',
  );

  test('estado inicial sem perfis', () {
    final provider = PerfilProvider(service: servicoFake(firestore: firestore));

    expect(provider.perfilMusico, isNull);
    expect(provider.perfilEstabelecimento, isNull);
    provider.dispose();
  });

  test('salvarPerfilEstabelecimento grava em estabelecimentos/{uid}', () async {
    await firestore.collection('usuarios').doc('u1').set({'tipoUsuario': 'casaShow'});
    final provider = PerfilProvider(service: servicoFake(firestore: firestore));
    await aguardar();

    final ok = await provider.salvarPerfilEstabelecimento(estabelecimento());

    expect(ok, isTrue);
    expect(provider.perfilEstabelecimento?.id, 'u1');
    expect(provider.perfilEstabelecimento?.completo, isTrue);
    final doc = await firestore.collection('estabelecimentos').doc('u1').get();
    expect(doc.data()?['nome'], 'Bar Central');
    expect(doc.data()?['oculto'], isFalse);
    provider.dispose();
  });

  test('sem ninguém logado salvar não grava nada', () async {
    final provider = PerfilProvider(
      service: servicoFake(firestore: firestore, uid: null),
    );
    await aguardar();

    expect(await provider.salvarPerfilMusico(musicoTeste()), isFalse);
    expect((await firestore.collection('perfis_musicos').get()).docs, isEmpty);
    provider.dispose();
  });
}
