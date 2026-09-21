import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/oportunidade_provider.dart';

class MeusInteressesScreen extends StatelessWidget {
  const MeusInteressesScreen({super.key});

  Future<void> _confirmarRemocao(
    BuildContext context, {
    required String oportunidadeId,
    required String titulo,
  }) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover interesse'),
        content: Text(
          'Deseja remover seu interesse na oportunidade "$titulo"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;

    await context.read<OportunidadeProvider>().removerInteresse(oportunidadeId);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Interesse removido com sucesso.')),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OportunidadeProvider>();
    final interesses = provider.oportunidadesComInteresse;

    return Scaffold(
      appBar: AppBar(title: const Text('Meus interesses')),
      body: interesses.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Você ainda não demonstrou interesse em nenhuma oportunidade.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: interesses.length,
              itemBuilder: (context, index) {
                final oportunidade = interesses[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          oportunidade.titulo,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Contratante: ${oportunidade.contratante}'),
                        Text('Cidade: ${oportunidade.cidade}'),
                        Text('Gênero: ${oportunidade.generoMusical}'),
                        Text('Data: ${_formatarData(oportunidade.dataEvento)}'),
                        Text(
                          'Cachê: R\$ ${oportunidade.cacheOferecido.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 8),
                        Text(oportunidade.descricao),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            const Text('Interesse enviado'),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _confirmarRemocao(
                                context,
                                oportunidadeId: oportunidade.id,
                                titulo: oportunidade.titulo,
                              ),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Remover'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
