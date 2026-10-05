import 'package:flutter/widgets.dart';

/// Espaçamentos em múltiplos de 4 (Plano 8). Usar estes valores em
/// `padding`/`SizedBox` em vez de números soltos.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Margem lateral padrão das telas.
  static const tela = EdgeInsets.all(md);

  /// Espaço interno padrão dos cards.
  static const card = EdgeInsets.all(md);
}

/// Raios de borda (Plano 8).
abstract final class AppRadius {
  /// Etiquetas pequenas.
  static const double sm = 8;

  /// Campos e botões.
  static const double md = 12;

  /// Cards.
  static const double lg = 16;

  /// Card de destaque e painéis inferiores.
  static const double xl = 24;

  static const pilula = 999.0;

  static BorderRadius circular(double raio) => BorderRadius.circular(raio);
}
