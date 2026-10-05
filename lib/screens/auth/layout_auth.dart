import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Moldura das telas de entrada (Plano 8): fundo escuro com o brilho roxo do
/// protótipo, conteúdo centralizado e rolável (o teclado não cobre os
/// campos) e largura máxima de 440 px em telas grandes.
class LayoutAuth extends StatelessWidget {
  const LayoutAuth({super.key, required this.child, this.appBar});

  final Widget child;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      // O brilho passa por trás do AppBar (transparente): sem isso ele
      // termina numa linha reta na altura da barra.
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Brilhos decorativos (protótipo de login).
          const Positioned(
            top: -120,
            right: -100,
            child: _Brilho(tamanho: 320),
          ),
          const Positioned(
            bottom: -140,
            left: -120,
            child: _Brilho(tamanho: 280),
          ),
          // Com extendBodyBehindAppBar o Scaffold já inclui a altura do
          // AppBar no padding de cima: o SafeArea começa o conteúdo abaixo
          // dela.
          SafeArea(
            child: LayoutBuilder(
              builder: (context, restricoes) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: restricoes.maxHeight - AppSpacing.xl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Brilho extends StatelessWidget {
  const _Brilho({required this.tamanho});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: tamanho,
        height: tamanho,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.primaria.withValues(alpha: 0.22),
              AppColors.primaria.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
