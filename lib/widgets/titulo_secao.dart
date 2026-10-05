import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// Cabeçalho de seção dos protótipos ("Em destaque" ... "Ver mais").
class TituloSecao extends StatelessWidget {
  const TituloSecao(
    this.titulo, {
    super.key,
    this.rotuloAcao,
    this.onAcao,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.sm),
  });

  final String titulo;

  /// Texto do link à direita; aparece só com [onAcao].
  final String? rotuloAcao;
  final VoidCallback? onAcao;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                titulo,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          if (rotuloAcao != null && onAcao != null)
            TextButton(
              onPressed: onAcao,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 36),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              ),
              child: Text(rotuloAcao!),
            ),
        ],
      ),
    );
  }
}

/// Rótulo pequeno em maiúsculas dos protótipos ("DESCRIÇÃO", "E-MAIL").
class RotuloSecao extends StatelessWidget {
  const RotuloSecao(this.texto, {super.key, this.destaque = false});

  final String texto;

  /// Roxo (título de card de seção) em vez de cinza (rótulo de campo).
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Text(
      texto.toUpperCase(),
      style: tema.textTheme.labelSmall?.copyWith(
        color: destaque ? tema.colorScheme.secondary : null,
      ),
    );
  }
}

/// Card com rótulo em destaque e conteúdo (seções "Descrição", "Sobre" dos
/// detalhes nos protótipos).
class CardSecao extends StatelessWidget {
  const CardSecao({super.key, required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RotuloSecao(titulo, destaque: true),
            const SizedBox(height: AppSpacing.xs),
            child,
          ],
        ),
      ),
    );
  }
}
