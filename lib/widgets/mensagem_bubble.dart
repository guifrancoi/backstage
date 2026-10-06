import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../models/mensagem.dart';

/// Balão do chat (Plano 8): as minhas em roxo à direita, as do outro à
/// esquerda; o canto "da ponta" é menos arredondado e o horário vai embaixo.
/// Aviso do app (`sistema`) fica centralizado, sem lado.
class MensagemBubble extends StatelessWidget {
  final Mensagem mensagem;

  /// Calculado pela tela (`mensagem.remetenteId == uid logado`).
  final bool enviadaPorMim;

  const MensagemBubble({
    super.key,
    required this.mensagem,
    required this.enviadaPorMim,
  });

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    // Aviso do app (ex.: "Convite para X aceito"): centralizado, sem lado.
    if (mensagem.sistema) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.superficieAlta,
            borderRadius: AppRadius.circular(AppRadius.pilula),
            border: Border.all(color: AppColors.borda),
          ),
          child: Text(
            mensagem.texto,
            textAlign: TextAlign.center,
            style: texto.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    const raio = Radius.circular(AppRadius.lg);
    const ponta = Radius.circular(4);
    final hora =
        '${mensagem.dataHora.hour.toString().padLeft(2, '0')}:'
        '${mensagem.dataHora.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: enviadaPorMim
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          // O balão não ocupa a largura toda: fica claro de quem é.
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
              6,
            ),
            decoration: BoxDecoration(
              color: enviadaPorMim
                  ? AppColors.primaria
                  : AppColors.superficieAlta,
              borderRadius: BorderRadius.only(
                topLeft: raio,
                topRight: raio,
                bottomLeft: enviadaPorMim ? raio : ponta,
                bottomRight: enviadaPorMim ? ponta : raio,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mensagem.texto,
                  style: texto.bodyMedium?.copyWith(
                    color: enviadaPorMim ? Colors.white : AppColors.texto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hora,
                  style: texto.bodySmall?.copyWith(
                    fontSize: 11,
                    color: enviadaPorMim
                        ? Colors.white.withValues(alpha: 0.75)
                        : AppColors.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
