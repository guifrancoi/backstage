import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import 'avatar_iniciais.dart';

/// Cabeçalho em gradiente dos perfis públicos (protótipo "perfil do
/// artista", Plano 8): avatar circular, nome e uma linha de etiquetas
/// (gênero, cidade, assinante...).
class CabecalhoPerfil extends StatelessWidget {
  const CabecalhoPerfil({
    super.key,
    required this.nome,
    this.foto,
    this.etiquetas = const [],
  });

  final String nome;

  /// Miniatura em base64; sem ela, iniciais.
  final String? foto;
  final List<Widget> etiquetas;

  @override
  Widget build(BuildContext context) {
    final raio = AppRadius.circular(AppRadius.xl);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: context.cores.gradienteDestaque,
        borderRadius: raio,
        border: Border.all(color: AppColors.primaria.withValues(alpha: 0.35)),
      ),
      child: Stack(
        children: [
          // Círculo decorativo do protótipo.
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaria.withValues(alpha: 0.18),
              ),
            ),
          ),
          // Largura toda: sem isso a coluna encolhe e fica à esquerda.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              children: [
                AvatarIniciais(
                  nome: nome,
                  foto: foto,
                  tamanho: 88,
                  circular: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                Semantics(
                  header: true,
                  child: Text(
                    nome,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (etiquetas.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xxs,
                    children: etiquetas,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
