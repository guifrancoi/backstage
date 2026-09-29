import 'package:flutter/material.dart';
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
    final alignment = enviadaPorMim
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    final color = enviadaPorMim
        ? Colors.deepPurple.shade100
        : Colors.grey.shade300;

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
