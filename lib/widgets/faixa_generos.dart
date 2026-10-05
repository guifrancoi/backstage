import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_spacing.dart';

/// Faixa horizontal de gêneros dos protótipos ("Todos", Rock, MPB...):
/// escolhe um gênero ou nenhum (`null` = Todos).
class FaixaGeneros extends StatelessWidget {
  const FaixaGeneros({
    super.key,
    required this.selecionado,
    required this.onSelecionar,
    this.generos = AppStrings.generosMusicais,
  });

  final String? selecionado;
  final ValueChanged<String?> onSelecionar;
  final List<String> generos;

  @override
  Widget build(BuildContext context) {
    final todos = selecionado == null || selecionado!.isEmpty;

    Widget chip(String rotulo, {required bool marcado, String? genero}) =>
        ChoiceChip(
          label: Text(rotulo),
          selected: marcado,
          showCheckmark: false,
          onSelected: (_) => onSelecionar(genero),
        );

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          chip('Todos', marcado: todos),
          for (final genero in generos) ...[
            const SizedBox(width: AppSpacing.xs),
            chip(genero, marcado: genero == selecionado, genero: genero),
          ],
        ],
      ),
    );
  }
}
