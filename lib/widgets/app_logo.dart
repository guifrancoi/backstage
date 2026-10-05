import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Marca do protótipo: ícone em quadrado roxo, "Back" + "stage" (em roxo) e
/// o slogan. [compacto] omite o slogan.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.compacto = false});

  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Semantics(
      label: 'Backstage',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primariaContainer,
              borderRadius: AppRadius.circular(AppRadius.xl - 4),
              border: Border.all(
                color: AppColors.primaria.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.music_note_rounded,
              size: 38,
              color: AppColors.primariaTexto,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text.rich(
            const TextSpan(
              children: [
                TextSpan(text: 'Back'),
                TextSpan(
                  text: 'stage',
                  style: TextStyle(color: AppColors.primariaTexto),
                ),
              ],
            ),
            style: texto.displaySmall?.copyWith(fontSize: 34),
          ),
          if (!compacto) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Conectando artistas ao palco',
              style: texto.bodyMedium?.copyWith(
                color: AppColors.textoSecundario,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
