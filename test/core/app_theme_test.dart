import 'dart:math';

import 'package:backstage/core/theme/app_colors.dart';
import 'package:backstage/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Razão de contraste WCAG 2.x entre duas cores opacas.
double _contraste(Color a, Color b) {
  double canal(double c) =>
      c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
  double luminancia(Color c) =>
      0.2126 * canal(c.r) + 0.7152 * canal(c.g) + 0.0722 * canal(c.b);
  final (claro, escuro) = (luminancia(a), luminancia(b));
  return (max(claro, escuro) + 0.05) / (min(claro, escuro) + 0.05);
}

void main() {
  test('tema escuro com Inter e as cores do Backstage', () {
    final tema = AppTheme.escuro;

    expect(tema.brightness, Brightness.dark);
    expect(tema.colorScheme.primary, AppColors.primaria);
    expect(tema.scaffoldBackgroundColor, AppColors.fundo);
    expect(tema.textTheme.bodyMedium?.fontFamily, 'Inter');
    expect(tema.extension<BackstageCores>(), BackstageCores.escuro);
  });

  group('contraste WCAG AA (texto pequeno ≥ 4,5:1)', () {
    final pares = {
      'texto no fundo': (AppColors.texto, AppColors.fundo),
      'texto no card': (AppColors.texto, AppColors.superficie),
      'texto secundário no fundo': (AppColors.textoSecundario, AppColors.fundo),
      'texto secundário no card': (
        AppColors.textoSecundario,
        AppColors.superficie,
      ),
      'texto secundário no campo': (
        AppColors.textoSecundario,
        AppColors.superficieAlta,
      ),
      'link roxo no fundo': (AppColors.primariaTexto, AppColors.fundo),
      'link roxo no card': (AppColors.primariaTexto, AppColors.superficie),
      'etiqueta roxa': (AppColors.primariaTexto, AppColors.primariaContainer),
      'botão primário': (Colors.white, AppColors.primaria),
      'dinheiro no card': (AppColors.sucesso, AppColors.superficie),
      'etiqueta sucesso': (AppColors.sucesso, AppColors.sucessoFundo),
      'etiqueta aviso': (AppColors.aviso, AppColors.avisoFundo),
      'etiqueta erro': (AppColors.erro, AppColors.erroFundo),
    };
    for (final MapEntry(key: nome, value: (frente, fundo)) in pares.entries) {
      test(nome, () {
        expect(_contraste(frente, fundo), greaterThanOrEqualTo(4.5));
      });
    }
  });

  test('roxo de marca sozinho não passa em texto pequeno', () {
    // Motivo de existir primariaTexto: documenta a decisão.
    expect(_contraste(AppColors.primaria, AppColors.fundo), lessThan(4.5));
  });
}
