import 'package:flutter/services.dart';

/// Telefone brasileiro com DDD: 10 dígitos (fixo) ou 11 (celular).
const maximoDigitosTelefone = 11;

/// Só os dígitos de [texto].
String digitosDe(String texto) => texto.replaceAll(RegExp(r'\D'), '');

/// "(16) 99999-0000" (celular) ou "(16) 3333-0000" (fixo); com menos
/// dígitos, o que der para montar enquanto a pessoa digita ("(16) 999").
String formatarTelefone(String texto) {
  final d = digitosDe(texto);
  if (d.isEmpty) return '';
  if (d.length <= 2) return '($d';
  final ddd = d.substring(0, 2);
  final resto = d.substring(2);
  // Celular tem 5 dígitos antes do hífen; fixo e parcial, 4.
  final antes = d.length == maximoDigitosTelefone ? 5 : 4;
  if (resto.length <= antes) return '($ddd) $resto';
  return '($ddd) ${resto.substring(0, antes)}-${resto.substring(antes)}';
}

/// Máscara do campo de telefone: aceita só dígitos (até 11), formata a cada
/// tecla e deixa o cursor no fim (Plano 23).
class MascaraTelefone extends TextInputFormatter {
  const MascaraTelefone();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digitos = digitosDe(newValue.text);
    // Apagar o "-" ou o ")" sozinho não mudaria nada: apaga o dígito antes.
    if (newValue.text.length < oldValue.text.length &&
        digitos == digitosDe(oldValue.text) &&
        digitos.isNotEmpty) {
      digitos = digitos.substring(0, digitos.length - 1);
    }
    if (digitos.length > maximoDigitosTelefone) {
      digitos = digitos.substring(0, maximoDigitosTelefone);
    }
    final texto = formatarTelefone(digitos);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
