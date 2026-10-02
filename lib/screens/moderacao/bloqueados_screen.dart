import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/data_hora.dart';
import '../../providers/oportunidade_provider.dart';
import 'acoes_moderacao.dart';

/// Usuários que o logado bloqueou (Plano 22), com "Desbloquear".
class BloqueadosScreen extends StatelessWidget {
  const BloqueadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloqueados = context.watch<OportunidadeProvider>().bloqueados;

    return Scaffold(
      appBar: AppBar(title: const Text('Usuários bloqueados')),
      body: bloqueados.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Você não bloqueou ninguém.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              itemCount: bloqueados.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final b = bloqueados[index];
                return ListTile(
                  leading: const Icon(Icons.block),
                  title: Text(b.nome.isEmpty ? 'Usuário' : b.nome),
                  subtitle: Text('Bloqueado em ${formatarData(b.criadoEm)}'),
                  trailing: TextButton(
                    onPressed: () => desbloquear(context, uid: b.uid, nome: b.nome),
                    child: const Text('Desbloquear'),
                  ),
                );
              },
            ),
    );
  }
}
