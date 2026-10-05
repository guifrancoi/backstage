import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Escala tipográfica (Plano 8), fonte Inter empacotada (`pubspec.yaml`).
/// Telas leem `Theme.of(context).textTheme`; os papéis usados:
///
/// - `displaySmall` (28/800): marca e números de destaque;
/// - `headlineSmall` (22/700): título de tela sem AppBar;
/// - `titleLarge` (20/700): título da AppBar;
/// - `titleMedium` (17/600): título de card;
/// - `titleSmall` (15/600): subtítulo, nome em lista;
/// - `bodyLarge`/`bodyMedium` (16/15, 400): texto corrido;
/// - `bodySmall` (13/400): apoio (cidade, data);
/// - `labelLarge` (15/600): botões;
/// - `labelMedium` (13/600): etiquetas e chips;
/// - `labelSmall` (11/700, maiúsculas pela tela): rótulo de seção/campo.
abstract final class AppTypography {
  static const familia = 'Inter';

  static TextTheme get textTheme => const TextTheme(
    displaySmall: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      height: 1.15,
      letterSpacing: -0.5,
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: -0.2,
    ),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16, height: 1.45),
    bodyMedium: TextStyle(fontSize: 15, height: 1.45),
    bodySmall: TextStyle(fontSize: 13, height: 1.35),
    labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
  ).apply(
    fontFamily: familia,
    bodyColor: AppColors.texto,
    displayColor: AppColors.texto,
  );
}
