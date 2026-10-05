import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Estados de lista/tela do Plano 8: carregando, vazio e erro, com o mesmo
/// visual em todas as telas.

class EstadoCarregando extends StatelessWidget {
  const EstadoCarregando({super.key, this.mensagem});

  final String? mensagem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (mensagem != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(mensagem!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Lista vazia: ícone em círculo, título, explicação e ação opcional.
class EstadoVazio extends StatelessWidget {
  const EstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    this.mensagem,
    this.rotuloAcao,
    this.onAcao,
  });

  final IconData icone;
  final String titulo;
  final String? mensagem;
  final String? rotuloAcao;
  final VoidCallback? onAcao;

  @override
  Widget build(BuildContext context) {
    return _EstadoBase(
      icone: icone,
      corIcone: context.cores.primariaTexto,
      fundoIcone: AppColors.primariaContainer,
      titulo: titulo,
      mensagem: mensagem,
      acao: rotuloAcao != null && onAcao != null
          ? OutlinedButton(onPressed: onAcao, child: Text(rotuloAcao!))
          : null,
    );
  }
}

/// Falha ao carregar, com "Tentar novamente" opcional.
class EstadoErro extends StatelessWidget {
  const EstadoErro({
    super.key,
    this.titulo = 'Algo deu errado',
    required this.mensagem,
    this.onTentarNovamente,
  });

  final String titulo;
  final String mensagem;
  final VoidCallback? onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return _EstadoBase(
      icone: Icons.cloud_off_outlined,
      corIcone: cores.erro,
      fundoIcone: cores.erroFundo,
      titulo: titulo,
      mensagem: mensagem,
      acao: onTentarNovamente == null
          ? null
          : OutlinedButton.icon(
              onPressed: onTentarNovamente,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
    );
  }
}

class _EstadoBase extends StatelessWidget {
  const _EstadoBase({
    required this.icone,
    required this.corIcone,
    required this.fundoIcone,
    required this.titulo,
    this.mensagem,
    this.acao,
  });

  final IconData icone;
  final Color corIcone;
  final Color fundoIcone;
  final String titulo;
  final String? mensagem;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: fundoIcone,
                shape: BoxShape.circle,
              ),
              child: Icon(icone, size: 30, color: corIcone),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(titulo, style: texto.titleMedium, textAlign: TextAlign.center),
            if (mensagem != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                mensagem!,
                style: texto.bodyMedium?.copyWith(
                  color: context.cores.textoSecundario,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (acao != null) ...[
              const SizedBox(height: AppSpacing.lg),
              acao!,
            ],
          ],
        ),
      ),
    );
  }
}
