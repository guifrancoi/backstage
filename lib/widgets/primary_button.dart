import 'package:flutter/material.dart';

/// Ação principal da tela: botão roxo de largura total (estilo vem do
/// `elevatedButtonTheme`). `onPressed: null` desabilita; [carregando] troca
/// o texto por um indicador e também desabilita.
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool carregando;
  final IconData? icone;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.carregando = false,
    this.icone,
  });

  @override
  Widget build(BuildContext context) {
    final rotulo = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: carregando
          ? SizedBox(
              key: const ValueKey('carregando'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Theme.of(context).colorScheme.onPrimary,
                semanticsLabel: 'Carregando',
              ),
            )
          : Row(
              key: const ValueKey('texto'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icone != null) ...[
                  Icon(icone, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(child: Text(text)),
              ],
            ),
    );

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: carregando ? null : onPressed,
        child: rotulo,
      ),
    );
  }
}
