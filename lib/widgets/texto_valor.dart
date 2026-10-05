import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/painel_numeros.dart';

/// Valor em reais no verde de dinheiro dos protótipos ("R$ 3.500").
/// Usa o estilo [estilo] (padrão `titleSmall`) só trocando a cor.
class TextoValor extends StatelessWidget {
  const TextoValor(this.valor, {super.key, this.estilo});

  final double valor;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    final base = estilo ?? Theme.of(context).textTheme.titleSmall;
    return Text(
      formatarReais(valor),
      style: base?.copyWith(
        color: context.cores.dinheiro,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
