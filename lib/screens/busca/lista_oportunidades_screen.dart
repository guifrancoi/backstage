import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/oportunidade.dart';
import '../../providers/oportunidade_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/oportunidade_card.dart';

class ListaOportunidadesScreen extends StatelessWidget {
  const ListaOportunidadesScreen({super.key});

  Future<void> _confirmarInteresse(
    BuildContext context, {
    required String oportunidadeId,
  }) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Demonstrar interesse'),
        content: const Text('Deseja demonstrar interesse nesta oportunidade?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;

    await context.read<OportunidadeProvider>().demonstrarInteresse(
      oportunidadeId: oportunidadeId,
      usuarioId: 'musico_logado_1',
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Interesse enviado com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OportunidadeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Lista de oportunidades')),
      body: StreamBuilder<List<Oportunidade>>(
        stream: provider.oportunidadesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              provider.oportunidades.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Erro ao carregar oportunidades. Verifique sua conexão.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }
          final oportunidades = provider.oportunidades;
          if (oportunidades.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhuma oportunidade encontrada.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: oportunidades.length,
            itemBuilder: (context, index) {
              final oportunidade = oportunidades[index];
              return OportunidadeCard(
                oportunidade: oportunidade,
                onDemonstrarInteresse: () => _confirmarInteresse(
                  context,
                  oportunidadeId: oportunidade.id,
                ),
                onVerDetalhes: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.detalheOportunidade,
                    arguments: oportunidade.id,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
