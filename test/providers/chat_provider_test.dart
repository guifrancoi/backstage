import 'package:backstage/providers/chat_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/firebase_fake.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ChatProvider provider;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('conversas').doc('c1').set({
      'participantes': ['u1', 'e1'],
      'nomes': {'u1': 'Eu', 'e1': 'Bar Central'},
      'mensagens': [],
    });
    provider = ChatProvider(service: servicoFake(firestore: firestore));
    await aguardar();
  });
  tearDown(() => provider.dispose());

  test('meuUid é o usuário logado', () {
    expect(provider.meuUid, 'u1');
  });

  test('buscarConversaPorId encontra ou retorna null', () {
    final conversa = provider.buscarConversaPorId('c1');

    expect(conversa?.nomeContato(provider.meuUid), 'Bar Central');
    expect(provider.buscarConversaPorId('nao-existe'), isNull);
  });

  test('enviarMensagem grava e volta pelo stream no fim da conversa', () async {
    await provider.enviarMensagem('c1', 'Combinado!');
    await aguardar();

    final conversa = provider.buscarConversaPorId('c1')!;
    expect(conversa.mensagens, hasLength(1));
    expect(conversa.mensagens.last.texto, 'Combinado!');
    expect(conversa.mensagens.last.remetenteId, 'u1');
    expect(conversa.ultimaMensagem, 'Combinado!');
  });

  test('enviarMensagem para conversa inexistente é ignorado', () async {
    var notificacoes = 0;
    provider.addListener(() => notificacoes++);

    await provider.enviarMensagem('nao-existe', 'Oi');
    await aguardar();

    expect(notificacoes, 0);
  });

  test('sem ninguém logado não há conversas', () async {
    final deslogado = ChatProvider(
      service: servicoFake(firestore: firestore, uid: null),
    );
    await aguardar();

    expect(deslogado.conversas, isEmpty);
    expect(deslogado.meuUid, isNull);
    deslogado.dispose();
  });
}
