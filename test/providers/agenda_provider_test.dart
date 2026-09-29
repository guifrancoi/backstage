import 'package:backstage/providers/agenda_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/firebase_fake.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late AgendaProvider provider;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    provider = AgendaProvider(service: servicoFake(firestore: firestore));
    await aguardar();
  });
  tearDown(() => provider.dispose());

  test('começa vazia para usuário sem datas', () {
    expect(provider.datasDisponiveis, isEmpty);
  });

  test('adicionarData normaliza o horário, ordena e grava', () async {
    await provider.adicionarData(DateTime(2026, 9, 5, 18, 30));
    await provider.adicionarData(DateTime(2026, 1, 5));

    expect(provider.datasDisponiveis, [DateTime(2026, 1, 5), DateTime(2026, 9, 5)]);
    final doc = await firestore
        .collection('disponibilidades')
        .doc('u1_2026-09-05')
        .get();
    expect(doc.exists, isTrue);
  });

  test('adicionarData ignora dia já existente, mesmo com outro horário', () async {
    await provider.adicionarData(DateTime(2026, 3, 20));
    await provider.adicionarData(DateTime(2026, 3, 20, 22));

    expect(provider.datasDisponiveis, hasLength(1));
  });

  test('removerData remove pelo dia, ignorando o horário', () async {
    await provider.adicionarData(DateTime(2026, 7, 10));

    await provider.removerData(DateTime(2026, 7, 10, 23, 59));

    expect(provider.datasDisponiveis, isEmpty);
    final doc = await firestore
        .collection('disponibilidades')
        .doc('u1_2026-07-10')
        .get();
    expect(doc.exists, isFalse);
  });

  test('sem ninguém logado não adiciona nada', () async {
    final deslogado = AgendaProvider(
      service: servicoFake(firestore: firestore, uid: null),
    );
    await aguardar();

    await deslogado.adicionarData(DateTime(2026, 1, 1));

    expect(deslogado.datasDisponiveis, isEmpty);
    expect((await firestore.collection('disponibilidades').get()).docs, isEmpty);
    deslogado.dispose();
  });

  test('datasDisponiveis não pode ser alterada de fora', () {
    expect(
      () => provider.datasDisponiveis.add(DateTime(2030)),
      throwsUnsupportedError,
    );
  });
}
