import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../widgets/primary_button.dart';

/// Rodapé dos formulários de perfil (Plano 8): "Cancelar" (só na edição) ao
/// lado do botão principal, que mostra o indicador enquanto salva.
class BotoesFormulario extends StatelessWidget {
  const BotoesFormulario({
    super.key,
    required this.textoSalvar,
    required this.salvando,
    required this.onSalvar,
    this.onCancelar,
  });

  final String textoSalvar;
  final bool salvando;
  final VoidCallback onSalvar;
  final VoidCallback? onCancelar;

  @override
  Widget build(BuildContext context) {
    final salvar = PrimaryButton(
      text: textoSalvar,
      carregando: salvando,
      icone: Icons.check,
      onPressed: onSalvar,
    );
    if (onCancelar == null) return salvar;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: salvando ? null : onCancelar,
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(flex: 2, child: salvar),
      ],
    );
  }
}
