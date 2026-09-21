import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/agenda_provider.dart';

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AgendaProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await provider.adicionarData(
            DateTime.now().add(const Duration(days: 7)),
          );
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nova data adicionada.')),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.datasDisponiveis.length,
        itemBuilder: (context, index) {
          final data = provider.datasDisponiveis[index];

          return Card(
            child: ListTile(
              title: Text(
                '${data.day.toString().padLeft(2, '0')}/'
                '${data.month.toString().padLeft(2, '0')}/'
                '${data.year}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  await provider.removerData(data);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
