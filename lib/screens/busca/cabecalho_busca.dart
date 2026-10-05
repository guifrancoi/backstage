import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../widgets/campo_pesquisa.dart';
import '../../widgets/faixa_generos.dart';

/// Topo das listas de músicos e de oportunidades (Plano 8): pesquisa, faixa
/// de gêneros, contagem + "Filtrar (n)" e os critérios do painel como chips
/// removíveis (com "Limpar").
class CabecalhoBusca extends StatelessWidget {
  const CabecalhoBusca({
    super.key,
    required this.termo,
    required this.onTermo,
    required this.dica,
    required this.genero,
    required this.onGenero,
    required this.contagem,
    required this.ativosNoPainel,
    required this.onFiltrar,
    required this.chips,
    required this.onLimpar,
  });

  final String termo;
  final ValueChanged<String> onTermo;
  final String dica;
  final String? genero;
  final ValueChanged<String?> onGenero;

  /// "3 músicos"; `null` enquanto carrega.
  final String? contagem;
  final int ativosNoPainel;
  final VoidCallback onFiltrar;

  /// Um `InputChip` por critério do painel.
  final List<Widget> chips;
  final VoidCallback onLimpar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: CampoPesquisa(valor: termo, onChanged: onTermo, dica: dica),
        ),
        FaixaGeneros(selecionado: genero, onSelecionar: onGenero),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xxs,
            AppSpacing.xs,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  contagem ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextButton.icon(
                onPressed: onFiltrar,
                icon: const Icon(Icons.tune_rounded),
                label: Text(
                  ativosNoPainel == 0 ? 'Filtrar' : 'Filtrar ($ativosNoPainel)',
                ),
              ),
            ],
          ),
        ),
        if (chips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xxs,
            ),
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...chips,
                TextButton(onPressed: onLimpar, child: const Text('Limpar')),
              ],
            ),
          ),
      ],
    );
  }
}
