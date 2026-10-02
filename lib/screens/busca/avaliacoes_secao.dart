import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/data_hora.dart';
import '../../providers/avaliacao_provider.dart';

/// Avaliações recebidas por [uid] (Plano 17): média e os 5 comentários mais
/// recentes. Usada no detalhe do músico e no perfil do estabelecimento.
class AvaliacoesSecao extends StatelessWidget {
  const AvaliacoesSecao({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AvaliacaoProvider>();
    final resumo = provider.resumoDe(uid);
    final recentes = provider.recebidasPor(uid, limite: 5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Avaliações', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        if (!resumo.temAvaliacao)
          const Text(
            'Ainda sem avaliações.',
            style: TextStyle(color: Colors.grey),
          )
        else ...[
          Text(
            resumo.rotulo,
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
          for (final a in recentes)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'★' * a.nota}${'☆' * (5 - a.nota)}  ${a.autorNome} · '
                    '${formatarData(a.criadaEm)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (a.comentario.isNotEmpty) Text(a.comentario),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
