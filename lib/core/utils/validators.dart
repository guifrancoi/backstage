import 'telefone.dart';

class Validators {
  static String? validarEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe o e-mail.';
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Informe um e-mail válido.';
    }

    return null;
  }

  static String? validarSenha(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe a senha.';
    }

    if (value.length < 6) {
      return 'A senha deve ter ao menos 6 caracteres.';
    }

    return null;
  }

  /// Telefone com DDD: 10 dígitos (fixo) ou 11 (celular, começando com 9),
  /// com DDD de 11 a 99. Aceita o texto já mascarado.
  static String? validarTelefone(String? value) {
    final digitos = digitosDe(value ?? '');
    if (digitos.isEmpty) return 'Informe o telefone.';
    if (digitos.length < 10) return 'Informe o telefone com DDD.';
    if (digitos.length > maximoDigitosTelefone ||
        int.parse(digitos.substring(0, 2)) < 11 ||
        (digitos.length == maximoDigitosTelefone && digitos[2] != '9')) {
      return 'Informe um telefone válido.';
    }
    return null;
  }

  static String? validarCampoObrigatorio(String? value, String campo) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe $campo.';
    }
    return null;
  }
}
