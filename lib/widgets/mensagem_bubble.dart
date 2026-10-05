import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/mensagem.dart';

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
    // Aviso do app (ex.: "Convite para X aceito"): centralizado, sem lado.
    if (mensagem.sistema) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.superficieAlta,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            mensagem.texto,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.textoSecundario,
            ),
          ),
        ),
      );
    }

    final alignment = enviadaPorMim
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    final color = enviadaPorMim
        ? AppColors.primariaContainer
        : AppColors.superficieAlta;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(mensagem.texto),
        ),
      ],
    );
  }
}
