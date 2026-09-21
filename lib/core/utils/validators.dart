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

  static String? validarCampoObrigatorio(String? value, String campo) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe $campo.';
    }
    return null;
  }
}
