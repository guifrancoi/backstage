import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/oportunidade_provider.dart';

class MeusArtistasInteresseScreen extends StatelessWidget {
  const MeusArtistasInteresseScreen({super.key});

  Future<void> _confirmarRemocao(
    BuildContext context, {
    required String musicoId,
    required String nomeArtistico,
  }) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover interesse'),
        content: Text(
          'Deseja remover seu interesse no artista "$nomeArtistico"?',
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

    await context.read<OportunidadeProvider>().removerInteresseEmMusico(
      musicoId,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Interesse no artista removido com sucesso.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OportunidadeProvider>();
    final artistas = provider.musicosComInteresse;

    return Scaffold(
      appBar: AppBar(title: const Text('Meus artistas de interesse')),
      body: artistas.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Você ainda não demonstrou interesse em nenhum artista.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: artistas.length,
              itemBuilder: (context, index) {
                final musico = artistas[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          musico.nomeArtistico,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Gênero: ${musico.generoMusical}'),
                        Text('Cidade: ${musico.cidade}'),
                        Text(
                          'Cachê médio: R\$ ${musico.cacheMedio.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 8),
                        Text(musico.descricao),
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
                                musicoId: musico.id,
                                nomeArtistico: musico.nomeArtistico,
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
