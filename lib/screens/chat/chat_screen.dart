import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';
import '../../widgets/mensagem_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String conversaId;

  const ChatScreen({super.key, required this.conversaId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _mensagemController = TextEditingController();

  @override
  void dispose() {
    _mensagemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final conversa = provider.buscarConversaPorId(widget.conversaId);

    if (conversa == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Conversa não encontrada.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(conversa.nomeContato)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: conversa.mensagens.length,
              itemBuilder: (context, index) {
                return MensagemBubble(mensagem: conversa.mensagens[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensagemController,
                    decoration: const InputDecoration(
                      hintText: 'Digite sua mensagem',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final texto = _mensagemController.text.trim();
                    if (texto.isEmpty) return;

                    await provider.enviarMensagem(widget.conversaId, texto);
                    _mensagemController.clear();

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mensagem enviada.')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
