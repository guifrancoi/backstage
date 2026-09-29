import 'package:backstage/data/mock_data.dart';
import 'package:backstage/providers/chat_provider.dart';
import 'package:flutter_test/flutter_test.dart';

// Modo mock: conversas do MockData, usuário = MockData.usuarioMockId.
void main() {
  late ChatProvider provider;

  setUp(() => provider = ChatProvider());
  tearDown(() => provider.dispose());

  test('inicia com as conversas do MockData', () {
    expect(provider.conversas, hasLength(MockData.conversas.length));
    expect(provider.meuUid, MockData.usuarioMockId);
  });

  test('buscarConversaPorId encontra ou retorna null', () {
    final conversa = provider.buscarConversaPorId('1');

    expect(conversa?.nomeContato(provider.meuUid), 'Bar Central');
    expect(provider.buscarConversaPorId('nao-existe'), isNull);
  });

  test('enviarMensagem adiciona mensagem do usuário ao fim da conversa', () async {
    final total = provider.buscarConversaPorId('1')!.mensagens.length;

    await provider.enviarMensagem('1', 'Combinado!');

    final conversa = provider.buscarConversaPorId('1')!;
    expect(conversa.mensagens, hasLength(total + 1));
    expect(conversa.mensagens.last.texto, 'Combinado!');
    expect(conversa.mensagens.last.remetenteId, MockData.usuarioMockId);
    expect(conversa.ultimaMensagem, 'Combinado!');
  });

  test('enviarMensagem não altera o MockData compartilhado', () async {
    final total = MockData.conversas.first.mensagens.length;

    await provider.enviarMensagem('1', 'Oi');

    expect(MockData.conversas.first.mensagens, hasLength(total));
  });

  test('enviarMensagem para conversa inexistente é ignorado', () async {
    var notificacoes = 0;
    provider.addListener(() => notificacoes++);

    await provider.enviarMensagem('nao-existe', 'Oi');

    expect(notificacoes, 0);
  });
}
