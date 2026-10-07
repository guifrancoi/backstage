import 'package:backstage/core/utils/telefone.dart';
import 'package:backstage/core/utils/validators.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Digita [texto] tecla a tecla no formatador, como o campo faria.
String digitar(String texto) {
  const mascara = MascaraTelefone();
  var valor = TextEditingValue.empty;
  for (final tecla in texto.split('')) {
    valor = mascara.formatEditUpdate(
      valor,
      TextEditingValue(text: valor.text + tecla),
    );
  }
  return valor.text;
}

/// Apaga o último caractere visível (backspace com o cursor no fim).
String apagar(String texto) => const MascaraTelefone()
    .formatEditUpdate(
      TextEditingValue(text: texto),
      TextEditingValue(text: texto.substring(0, texto.length - 1)),
    )
    .text;

void main() {
  group('formatarTelefone', () {
    test('celular, fixo e parcial', () {
      expect(formatarTelefone('16999990000'), '(16) 99999-0000');
      expect(formatarTelefone('1633330000'), '(16) 3333-0000');
      expect(formatarTelefone('16'), '(16');
      expect(formatarTelefone('16999'), '(16) 999');
      expect(formatarTelefone(''), '');
    });

    test('ignora o que não é dígito', () {
      expect(formatarTelefone('(16) 99999-0000'), '(16) 99999-0000');
    });
  });

  group('MascaraTelefone', () {
    test('formata enquanto digita', () {
      expect(digitar('16'), '(16');
      expect(digitar('169999'), '(16) 9999');
      expect(digitar('1699990'), '(16) 9999-0');
      expect(digitar('16999990000'), '(16) 99999-0000');
    });

    test('não passa de 11 dígitos nem aceita letras', () {
      expect(digitar('169999900001234'), '(16) 99999-0000');
      expect(digitar('16a9b9999c0000'), '(16) 99999-0000');
    });

    test('apagar logo depois do hífen apaga o dígito anterior', () {
      expect(apagar('(16) 9999-0'), '(16) 9999');
      // Sem a regra, apagar o "-" de "(16) 9999-" voltaria o mesmo texto.
      expect(apagar('(16) 99999-0000'), '(16) 9999-9000');
    });
  });

  group('Validators.validarTelefone', () {
    test('aceita celular e fixo com DDD (com ou sem máscara)', () {
      expect(Validators.validarTelefone('(16) 99999-0000'), isNull);
      expect(Validators.validarTelefone('1633330000'), isNull);
    });

    test('recusa vazio, sem DDD, DDD inválido e celular sem 9', () {
      expect(Validators.validarTelefone(''), 'Informe o telefone.');
      expect(
        Validators.validarTelefone('99999-0000'),
        'Informe o telefone com DDD.',
      );
      expect(
        Validators.validarTelefone('(06) 99999-0000'),
        'Informe um telefone válido.',
      );
      expect(
        Validators.validarTelefone('(16) 89999-0000'),
        'Informe um telefone válido.',
      );
    });
  });
}
