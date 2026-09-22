import 'package:backstage/data/mock_data.dart';
import 'package:backstage/providers/chat_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ChatProvider provider;

  setUp(() => provider = ChatProvider());
  tearDown(() => provider.dispose());

  test('inicia com as conversas do MockData', () {
    expect(provider.conversas, hasLength(MockData.conversas.length));
  });

  test('buscarConversaPorId encontra ou retorna null', () {
    expect(provider.buscarConversaPorId('1')?.nomeContato, 'Bar Central');
    expect(provider.buscarConversaPorId('nao-existe'), isNull);
  });

  test('enviarMensagem adiciona mensagem própria ao fim da conversa', () async {
    final conversa = provider.buscarConversaPorId('1')!;
    final total = conversa.mensagens.length;

    await provider.enviarMensagem('1', 'Combinado!');

    expect(conversa.mensagens, hasLength(total + 1));
    final enviada = conversa.mensagens.last;
    expect(enviada.texto, 'Combinado!');
    expect(enviada.enviadaPorMim, isTrue);
    expect(enviada.remetenteId, 'me');
    expect(conversa.ultimaMensagem, 'Combinado!');
  });

  test('enviarMensagem para conversa inexistente é ignorado', () async {
    var notificacoes = 0;
    provider.addListener(() => notificacoes++);

    await provider.enviarMensagem('nao-existe', 'Oi');

    expect(notificacoes, 0);
  });
}
