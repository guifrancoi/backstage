import 'package:flutter/material.dart';

import '../models/musico.dart';
import 'titulo_secao.dart';

/// Seção "Sobre o show" (Plano 14): formação, equipamento, duração e
/// repertório — só o que estiver preenchido. Nada preenchido = nada aparece.
/// Plano 8: é um `CardSecao` próprio.
class DadosShowMusico extends StatelessWidget {
  const DadosShowMusico({
    super.key,
    required this.musico,
    this.padding = EdgeInsets.zero,
  });

  final Musico musico;

  /// Espaço em volta do card (só existe quando há algo a mostrar).
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final linhas = [
      if (musico.formacaoDescrita case final formacao?) 'Formação: $formacao',
      if (musico.equipamentoProprio) 'Tem equipamento próprio (som/luz)',
      if (musico.duracaoShowMin case final minutos?)
        'Duração do show: ${_duracao(minutos)}',
      if (musico.repertorio case final repertorio?) 'Repertório: $repertorio',
    ];
    if (linhas.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: CardSecao(
        titulo: 'Sobre o show',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, linha) in linhas.indexed) ...[
              if (i > 0) const SizedBox(height: 6),
              Text(linha),
            ],
          ],
        ),
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
