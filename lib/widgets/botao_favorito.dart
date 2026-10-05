import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Coração de favorito (Plano 18): cheio e vermelho quando [favorito].
class BotaoFavorito extends StatelessWidget {
  const BotaoFavorito({
    super.key,
    required this.favorito,
    required this.onPressed,
  });

  final bool favorito;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: favorito ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
      onPressed: onPressed,
      icon: Icon(
        favorito ? Icons.favorite : Icons.favorite_border,
        color: favorito ? AppColors.erro : null,
      ),
    );
  }
}
