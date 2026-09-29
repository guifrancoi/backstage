import 'package:flutter/material.dart';

import '../core/utils/data_hora.dart';

/// Botão que abre o seletor de horário e mostra o valor escolhido (`HH:mm`).
class CampoHorario extends StatelessWidget {
  const CampoHorario({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.onChanged,
  });

  final String rotulo;

  /// `HH:mm` ou `null` (ainda não escolhido).
  final String? valor;
  final ValueChanged<String> onChanged;

  Future<void> _escolher(BuildContext context) async {
    final escolhido = await showTimePicker(
      context: context,
      initialTime: horaDe(valor) ?? const TimeOfDay(hour: 20, minute: 0),
    );
    if (escolhido != null) onChanged(formatarHora(escolhido));
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _escolher(context),
      icon: const Icon(Icons.schedule),
      label: Text(valor == null ? rotulo : '$rotulo: $valor'),
    );
  }
}
