import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Logo oficial do Backstage (`assets/images/logo_backstage.png`, com o
/// nome) e o slogan. [compacto]: menor e sem slogan (tela de erro, Sobre).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.compacto = false});

  final bool compacto;

  /// Logo com o nome escrito.
  static const imagem = 'assets/images/logo_backstage.png';

  /// Só o símbolo, para espaços pequenos.
  static const simbolo = 'assets/images/logo_simbolo.png';

  @override
  Widget build(BuildContext context) {
    final tamanho = compacto ? 96.0 : 152.0;
    return Semantics(
      label: 'Backstage',
      image: true,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            // Brilho roxo suave em volta, como o destaque dos protótipos.
            decoration: BoxDecoration(
              borderRadius: AppRadius.circular(tamanho * 0.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaria.withValues(alpha: 0.35),
                  blurRadius: 32,
                ),
              ],
            ),
            child: Image.asset(
              imagem,
              width: tamanho,
              height: tamanho,
              filterQuality: FilterQuality.medium,
            ),
          ),
          if (!compacto) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Conectando artistas ao palco',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textoSecundario),
            ),
          ],
        ],
      ),
    );
  }
}
