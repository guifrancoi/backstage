import 'package:flutter/material.dart';

/// Formatação de data e hora usada nas telas (PT-BR, sem depender de locale).

/// `20/11/2026`
String formatarData(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/'
    '${data.month.toString().padLeft(2, '0')}/${data.year}';

/// `TimeOfDay` → `HH:mm` (formato gravado no Firestore).
String formatarHora(TimeOfDay hora) =>
    '${hora.hour.toString().padLeft(2, '0')}:'
    '${hora.minute.toString().padLeft(2, '0')}';

/// `HH:mm` → `TimeOfDay`; `null` se vazio ou inválido.
TimeOfDay? horaDe(String? texto) {
  final partes = texto?.split(':');
  if (partes == null || partes.length != 2) return null;
  final hora = int.tryParse(partes[0]);
  final minuto = int.tryParse(partes[1]);
  if (hora == null || minuto == null || hora > 23 || minuto > 59) return null;
  return TimeOfDay(hour: hora, minute: minuto);
}
