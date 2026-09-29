import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';
import '../../routes/app_routes.dart';

class ConversasScreen extends StatelessWidget {
  const ConversasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final conversas = provider.conversas;

    return Scaffold(
      appBar: AppBar(title: const Text('Conversas')),
      body: conversas.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhuma conversa ainda. Uma conversa começa quando um '
                  'interesse é aceito.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              itemCount: conversas.length,
              itemBuilder: (context, index) {
                final conversa = conversas[index];

                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(conversa.nomeContato(provider.meuUid)),
                  subtitle: Text(conversa.ultimaMensagem),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.chat,
                      arguments: conversa.id,
                    );
                  },
                );
              },
            ),
    );
  }
}
