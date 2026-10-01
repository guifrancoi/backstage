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

  test('todo dia começa livre (nenhum bloqueio)', () {
    expect(provider.diasBloqueados, isEmpty);
    expect(provider.bloqueado(DateTime(2026, 12, 25)), isFalse);
  });

  test('bloquearDia normaliza o horário, ordena e grava', () async {
    await provider.bloquearDia(DateTime(2026, 9, 5, 18, 30));
    await provider.bloquearDia(DateTime(2026, 1, 5));

    expect(provider.diasBloqueados, [DateTime(2026, 1, 5), DateTime(2026, 9, 5)]);
    expect(provider.bloqueado(DateTime(2026, 9, 5, 23)), isTrue);
    final doc = await firestore.collection('bloqueios').doc('u1_2026-09-05').get();
    expect(doc.exists, isTrue);
  });

  test('bloquear o mesmo dia duas vezes não duplica', () async {
    await provider.bloquearDia(DateTime(2026, 3, 20));
    await provider.bloquearDia(DateTime(2026, 3, 20, 22));

    expect(provider.diasBloqueados, hasLength(1));
  });

  test('desbloquearDia remove pelo dia, ignorando o horário', () async {
    await provider.bloquearDia(DateTime(2026, 7, 10));

    await provider.desbloquearDia(DateTime(2026, 7, 10, 23, 59));

    expect(provider.diasBloqueados, isEmpty);
    final doc = await firestore.collection('bloqueios').doc('u1_2026-07-10').get();
    expect(doc.exists, isFalse);
  });

  test('sem ninguém logado não bloqueia nada', () async {
    final deslogado = AgendaProvider(
      service: servicoFake(firestore: firestore, uid: null),
    );
    await aguardar();

    await deslogado.bloquearDia(DateTime(2026, 1, 1));

    expect(deslogado.diasBloqueados, isEmpty);
    expect((await firestore.collection('bloqueios').get()).docs, isEmpty);
    deslogado.dispose();
  });

  test('diasBloqueados não pode ser alterada de fora', () {
    expect(
      () => provider.diasBloqueados.add(DateTime(2030)),
      throwsUnsupportedError,
    );
  });
}
