import 'package:flutter/material.dart';
import '../models/musico.dart';

class MusicoCard extends StatelessWidget {
  final Musico musico;
  final VoidCallback onVerDetalhes;

  /// `null` esconde o botão (ex.: quem vê não é dono de estabelecimento).
  final VoidCallback? onConvidar;

  /// Rótulo do convite já enviado; quando presente o botão fica desabilitado.
  final String? statusConvite;

  const MusicoCard({
    super.key,
    required this.musico,
    required this.onVerDetalhes,
    this.onConvidar,
    this.statusConvite,
  });

  @override
  Widget build(BuildContext context) {
    final mostrarAcao = onConvidar != null || statusConvite != null;

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
                if (mostrarAcao) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: statusConvite == null ? onConvidar : null,
                      child: Text(statusConvite ?? 'Convidar'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
