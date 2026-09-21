import 'package:flutter/material.dart';
import '../models/mensagem.dart';

class MensagemBubble extends StatelessWidget {
  final Mensagem mensagem;

  const MensagemBubble({super.key, required this.mensagem});

  @override
  Widget build(BuildContext context) {
    final alignment = mensagem.enviadaPorMim
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    final color = mensagem.enviadaPorMim
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
