import 'package:flutter/material.dart';

import '../models/musico.dart';

/// Seção "Sobre o show" (Plano 14): formação, equipamento, duração e
/// repertório — só o que estiver preenchido. Nada preenchido = nada aparece.
class DadosShowMusico extends StatelessWidget {
  const DadosShowMusico({super.key, required this.musico});

  final Musico musico;

  @override
  Widget build(BuildContext context) {
    final linhas = [
      if (musico.formacaoDescrita case final formacao?)
        'Formação: $formacao',
      if (musico.equipamentoProprio) 'Tem equipamento próprio (som/luz)',
      if (musico.duracaoShowMin case final minutos?)
        'Duração do show: ${_duracao(minutos)}',
      if (musico.repertorio case final repertorio?) 'Repertório: $repertorio',
    ];
    if (linhas.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sobre o show',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          for (final linha in linhas) ...[
            const SizedBox(height: 8),
            Text(linha),
          ],
        ],
      ),
    );
  }

  /// `90` → "1h30"; `120` → "2h"; `45` → "45 min".
  static String _duracao(int minutos) {
    if (minutos < 60) return '$minutos min';
    final resto = minutos % 60;
    return '${minutos ~/ 60}h${resto == 0 ? '' : resto.toString().padLeft(2, '0')}';
  }
}
