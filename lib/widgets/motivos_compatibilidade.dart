import 'package:flutter/material.dart';

import '../core/utils/compatibilidade.dart';

/// "Compatibilidade 85%" + os motivos ("Mesmo gênero · Livre no dia"),
/// usados nas sugestões do Plano 15.
class MotivosCompatibilidade extends StatelessWidget {
  const MotivosCompatibilidade({super.key, required this.compatibilidade});

  final Compatibilidade compatibilidade;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compatibilidade ${compatibilidade.nota}%',
          style: const TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          compatibilidade.motivos.join(' · '),
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}
