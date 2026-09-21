import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';
import '../../routes/app_routes.dart';

class ConversasScreen extends StatelessWidget {
  const ConversasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Conversas')),
      body: ListView.builder(
        itemCount: provider.conversas.length,
        itemBuilder: (context, index) {
          final conversa = provider.conversas[index];

          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(conversa.nomeContato),
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
