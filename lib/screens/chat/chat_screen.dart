import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/interesse.dart';
import '../../providers/chat_provider.dart';
import '../../providers/contratacao_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../routes/app_routes.dart';
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

    // Logo após aceitar um interesse a conversa ainda pode estar chegando
    // pelo stream; a tela se atualiza sozinha quando ela aparecer.
    if (conversa == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Carregando conversa...')),
      );
    }

    final meuUid = provider.meuUid;
    // Tela aberta = conversa lida (também quando chega mensagem nova). O
    // provider só grava se houver não lidas.
    if (provider.naoLidas(conversa) > 0) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => provider.marcarComoLida(widget.conversaId),
      );
    }
    final interesseId = conversa.interesseId;
    final interesse = interesseId == null
        ? null
        : context.watch<InteresseProvider>().buscarPorId(interesseId);
    // O dono formaliza o show daqui, se ainda não há contratação em andamento.
    final podePropor =
        interesse != null &&
        interesse.status == StatusInteresse.aceito &&
        interesse.donoId == meuUid &&
        context.watch<ContratacaoProvider>().ativaParaInteresse(
              interesse.id,
            ) ==
            null;

    return Scaffold(
      appBar: AppBar(
        title: Text(conversa.nomeContato(meuUid)),
        actions: [
          if (podePropor)
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.proporContratacao,
                arguments: interesse.id,
              ),
              icon: const Icon(Icons.handshake_outlined),
              label: const Text('Propor show'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: conversa.mensagens.length,
              itemBuilder: (context, index) {
                final mensagem = conversa.mensagens[index];
                return MensagemBubble(
                  mensagem: mensagem,
                  enviadaPorMim: mensagem.remetenteId == meuUid,
                );
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
