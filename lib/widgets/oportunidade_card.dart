import 'package:flutter/material.dart';
import '../models/oportunidade.dart';

class OportunidadeCard extends StatelessWidget {
  final Oportunidade oportunidade;
  final VoidCallback onVerDetalhes;

  /// `null` esconde o botão (ex.: quem vê não é músico, ou a oportunidade
  /// não tem dono).
  final VoidCallback? onCandidatar;

  /// Rótulo da candidatura já enviada; quando presente o botão fica
  /// desabilitado.
  final String? statusCandidatura;

  const OportunidadeCard({
    super.key,
    required this.oportunidade,
    required this.onVerDetalhes,
    this.onCandidatar,
    this.statusCandidatura,
  });

  String get dataFormatada {
    final data = oportunidade.dataEvento;
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    final mostrarAcao = onCandidatar != null || statusCandidatura != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              oportunidade.titulo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Contratante: ${oportunidade.contratante}'),
            Text('Cidade: ${oportunidade.cidade}'),
            Text('Gênero: ${oportunidade.generoMusical}'),
            Text('Data: $dataFormatada'),
            Text(
              'Cachê: R\$ ${oportunidade.cacheOferecido.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            Text(
              oportunidade.descricao,
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
                      onPressed: statusCandidatura == null ? onCandidatar : null,
                      child: Text(statusCandidatura ?? 'Candidatar-se'),
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
