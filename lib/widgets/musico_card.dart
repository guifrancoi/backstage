import 'package:flutter/material.dart';

import '../core/utils/foto_perfil.dart';
import '../models/musico.dart';

class MusicoCard extends StatelessWidget {
  final Musico musico;
  final VoidCallback onVerDetalhes;

  /// `null` esconde o botão (ex.: quem vê não é dono de estabelecimento).
  final VoidCallback? onConvidar;

  /// Texto do botão de convite (ex.: "Convidar (1 pendente)"). O botão nunca
  /// fica desabilitado: o estado é por oportunidade, no painel de convite.
  final String rotuloConvidar;

  const MusicoCard({
    super.key,
    required this.musico,
    required this.onVerDetalhes,
    this.onConvidar,
    this.rotuloConvidar = 'Convidar',
  });

  @override
  Widget build(BuildContext context) {
    final mostrarAcao = onConvidar != null;
    final foto = imagemDaFoto(musico.foto);
    final resumoShow = musico.resumoShow;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage: foto,
                child: foto == null ? const Icon(Icons.music_note) : null,
              ),
              title: Text(musico.nomeArtistico),
              subtitle: Text('${musico.generoMusical} • ${musico.cidade}'),
              trailing: Text('R\$ ${musico.cacheMedio.toStringAsFixed(0)}'),
            ),
            if (resumoShow != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  resumoShow,
                  style: const TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
                      onPressed: onConvidar,
                      child: Text(rotuloConvidar),
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
