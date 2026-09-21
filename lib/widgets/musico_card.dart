import 'package:flutter/material.dart';
import '../models/musico.dart';

class MusicoCard extends StatelessWidget {
  final Musico musico;
  final VoidCallback onDemonstrarInteresse;
  final VoidCallback onVerDetalhes;

  const MusicoCard({
    super.key,
    required this.musico,
    required this.onDemonstrarInteresse,
    required this.onVerDetalhes,
  });

  @override
  Widget build(BuildContext context) {
    final interesseEnviado = musico.interesseEnviado == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.music_note)),
              title: Text(musico.nomeArtistico),
              subtitle: Text('${musico.generoMusical} • ${musico.cidade}'),
              trailing: Text('R\$ ${musico.cacheMedio.toStringAsFixed(0)}'),
            ),
            const SizedBox(height: 8),
            Text(
              musico.descricao,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onVerDetalhes,
                    child: const Text('Ver detalhes'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: interesseEnviado ? null : onDemonstrarInteresse,
                    child: Text(
                      interesseEnviado ? 'Interesse enviado' : 'Interessar-se',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
