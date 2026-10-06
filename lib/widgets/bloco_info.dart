import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import 'titulo_secao.dart';

/// Bloco de número/informação dos protótipos ("CACHÊ MÉDIO / R$ 1.200"):
/// rótulo pequeno em maiúsculas e o valor em destaque.
class BlocoInfo extends StatelessWidget {
  const BlocoInfo({
    super.key,
    required this.rotulo,
    required this.valor,
    this.cor,
    this.icone,
  });

  final String rotulo;
  final String valor;

  /// Cor do valor (ex.: dinheiro, estrela); padrão = texto.
  final Color? cor;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cor);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RotuloSecao(rotulo),
            const SizedBox(height: AppSpacing.xxs),
            Row(
              children: [
                if (icone != null) ...[
                  Icon(icone, size: 18, color: cor),
                  const SizedBox(width: AppSpacing.xxs),
                ],
                Flexible(child: Text(valor, style: estilo)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Blocos em grade de 2 colunas (1 em telas muito estreitas). Os dois blocos
/// de uma linha ficam com a mesma altura, mesmo quando um rótulo quebra.
class GradeBlocos extends StatelessWidget {
  const GradeBlocos({super.key, required this.blocos});

  final List<Widget> blocos;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricoes) {
        final colunas = restricoes.maxWidth < 280 ? 1 : 2;
        final linhas = [
          for (var i = 0; i < blocos.length; i += colunas)
            blocos.sublist(i, (i + colunas).clamp(0, blocos.length)),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, linha) in linhas.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var j = 0; j < colunas; j++) ...[
                      if (j > 0) const SizedBox(width: AppSpacing.sm),
                      // Linha incompleta: o espaço vazio mantém a largura.
                      Expanded(
                        child: j < linha.length
                            ? linha[j]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
