import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import 'etiqueta.dart';

/// Uma informação do rodapé do card de destaque ("Data" / "28 jun").
class InfoDestaque {
  const InfoDestaque(this.rotulo, this.valor, {this.dinheiro = false});

  final String rotulo;
  final String valor;

  /// Valor no verde de dinheiro (cachê).
  final bool dinheiro;
}

/// Card roxo em gradiente dos protótipos ("Em destaque" na Home, cabeçalho
/// dos detalhes): etiqueta, título, subtítulo e até 4 informações. Com 2
/// informações, a segunda fica à direita; com mais, viram grade de 2
/// colunas.
class CardDestaque extends StatelessWidget {
  const CardDestaque({
    super.key,
    required this.titulo,
    this.etiqueta,
    this.subtitulo,
    this.selo,
    this.infos = const [],
    this.onTap,
  });

  final String titulo;
  final String? etiqueta;
  final String? subtitulo;

  /// Ao lado da etiqueta (ex.: `SeloAssinante`).
  final Widget? selo;
  final List<InfoDestaque> infos;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final cores = context.cores;
    final raio = AppRadius.circular(AppRadius.xl);

    Widget info(InfoDestaque i, {bool direita = false}) => Column(
      crossAxisAlignment: direita
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          i.rotulo,
          style: texto.bodySmall?.copyWith(color: AppColors.primariaTexto),
        ),
        const SizedBox(height: 2),
        Text(
          i.valor,
          style: texto.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: i.dinheiro ? cores.dinheiro : null,
          ),
        ),
      ],
    );

    final Widget rodape = switch (infos.length) {
      0 => const SizedBox.shrink(),
      1 => info(infos.first),
      2 => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(child: info(infos[0])),
          info(infos[1], direita: true),
        ],
      ),
      _ => LayoutBuilder(
        builder: (context, restricoes) {
          final largura = (restricoes.maxWidth - AppSpacing.md) / 2;
          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              for (final i in infos) SizedBox(width: largura, child: info(i)),
            ],
          );
        },
      ),
    };

    return Semantics(
      container: true,
      button: onTap != null,
      child: Material(
        color: Colors.transparent,
        // Recorta o círculo decorativo nos cantos do card.
        borderRadius: raio,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: cores.gradienteDestaque,
            borderRadius: raio,
            border: Border.all(
              color: AppColors.primaria.withValues(alpha: 0.35),
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: raio,
            child: Stack(
              children: [
                // Círculo decorativo do protótipo, no canto superior direito.
                Positioned(
                  right: -40,
                  top: -40,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaria.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md + 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (etiqueta != null || selo != null) ...[
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            if (etiqueta != null)
                              Etiqueta(etiqueta!, icone: Icons.music_note),
                            ?selo,
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      Text(
                        titulo,
                        style: texto.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitulo != null) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          subtitulo!,
                          style: texto.bodyMedium?.copyWith(
                            color: AppColors.primariaTexto,
                          ),
                        ),
                      ],
                      if (infos.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        rodape,
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
