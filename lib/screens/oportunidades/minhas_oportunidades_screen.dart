import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/oportunidade_card.dart';
import '../busca/acoes_interesse.dart';

/// Oportunidades publicadas pelo dono de estabelecimento logado, com editar
/// e remover.
class MinhasOportunidadesScreen extends StatelessWidget {
  const MinhasOportunidadesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final minhas = context.watch<OportunidadeProvider>().minhasOportunidades(
      auth.userId,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas oportunidades')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.novaOportunidade),
        icon: const Icon(Icons.add),
        label: const Text('Nova oportunidade'),
      ),
      body: minhas.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Você ainda não publicou nenhuma oportunidade.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: minhas.length,
              itemBuilder: (context, index) {
                final oportunidade = minhas[index];
                return Column(
                  children: [
                    OportunidadeCard(
                      oportunidade: oportunidade,
                      onVerDetalhes: () => Navigator.pushNamed(
                        context,
                        AppRoutes.detalheOportunidade,
                        arguments: oportunidade.id,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () =>
                              confirmarRemocao(context, oportunidade),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remover'),
                        ),
                        TextButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.editarOportunidade,
                            arguments: oportunidade.id,
                          ),
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
    );
  }
}
