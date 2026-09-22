import 'package:backstage/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.validarEmail', () {
    test('rejeita vazio ou nulo', () {
      expect(Validators.validarEmail(null), 'Informe o e-mail.');
      expect(Validators.validarEmail(''), 'Informe o e-mail.');
    });

    test('rejeita formato inválido', () {
      for (final email in ['usuario', 'usuario@', 'usuario@dominio', '@dominio.com']) {
        expect(
          Validators.validarEmail(email),
          'Informe um e-mail válido.',
          reason: email,
        );
      }
    });

    test('aceita e-mail válido', () {
      expect(Validators.validarEmail('musico@backstage.com'), isNull);
    });
  });

  group('Validators.validarSenha', () {
    test('rejeita vazia ou nula', () {
      expect(Validators.validarSenha(null), 'Informe a senha.');
      expect(Validators.validarSenha(''), 'Informe a senha.');
    });

    test('exige ao menos 6 caracteres (mínimo do Firebase)', () {
      expect(
        Validators.validarSenha('12345'),
        'A senha deve ter ao menos 6 caracteres.',
      );
      expect(Validators.validarSenha('123456'), isNull);
    });
  });

  group('Validators.validarCampoObrigatorio', () {
    test('rejeita nulo, vazio ou só espaços usando o nome do campo', () {
      for (final valor in [null, '', '   ']) {
        expect(
          Validators.validarCampoObrigatorio(valor, 'o nome'),
          'Informe o nome.',
        );
      }
    });

    test('aceita valor preenchido', () {
      expect(Validators.validarCampoObrigatorio('Banda', 'o nome'), isNull);
    });
  });
}
