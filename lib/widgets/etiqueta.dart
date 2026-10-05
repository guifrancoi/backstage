import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Cor da etiqueta: [destaque] para gênero/categoria (roxo), as demais para
/// status (Aceito, Pendente, Recusado...).
enum TipoEtiqueta { destaque, neutra, sucesso, aviso, erro }

/// Pílula pequena dos protótipos: gênero ("Rock") ou status ("Pendente").
/// Só exibição — para filtro clicável usar `FilterChip`/`InputChip`.
class Etiqueta extends StatelessWidget {
  const Etiqueta(
    this.texto, {
    super.key,
    this.tipo = TipoEtiqueta.destaque,
    this.icone,
  });

  final String texto;
  final TipoEtiqueta tipo;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final (fundo, frente) = switch (tipo) {
      TipoEtiqueta.destaque => (
        AppColors.primariaContainer,
        cores.primariaTexto,
      ),
      TipoEtiqueta.neutra => (cores.superficieAlta, cores.textoSecundario),
      TipoEtiqueta.sucesso => (cores.sucessoFundo, cores.sucesso),
      TipoEtiqueta.aviso => (cores.avisoFundo, cores.aviso),
      TipoEtiqueta.erro => (cores.erroFundo, cores.erro),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: AppRadius.circular(AppRadius.pilula),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 13, color: frente),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: frente, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
