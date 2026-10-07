import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

/// Plano 23: separador "ou" + "Continuar com Google", no login e no cadastro.
/// Depois de entrar segue o mesmo caminho do login com senha: completar o
/// perfil (1º acesso: tipo de conta e telefone) ou a Home.
class EntrarComGoogle extends StatelessWidget {
  const EntrarComGoogle({super.key});

  Future<void> _entrar(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final ok = await auth.entrarComGoogle();
    if (!context.mounted) return;

    if (!ok) {
      // Sem mensagem = a pessoa só fechou a escolha de conta.
      final mensagem = auth.errorMessage;
      if (mensagem != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensagem)));
      }
      return;
    }

    final completar = await auth.precisaCompletarPerfil();
    navigator.pushReplacementNamed(
      completar ? AppRoutes.completarPerfil : AppRoutes.home,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ocupado = auth.isLoading || auth.entrandoComGoogle;
    final texto = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                'ou',
                style: texto.bodySmall?.copyWith(
                  color: AppColors.textoSecundario,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: ocupado ? null : () => _entrar(context),
          icon: auth.entrandoComGoogle
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    semanticsLabel: 'Entrando com Google',
                  ),
                )
              : const _LetraGoogle(),
          label: const Text('Continuar com Google'),
        ),
      ],
    );
  }
}

/// "G" do Google num círculo branco (sem pacote de ícones de marca).
class _LetraGoogle extends StatelessWidget {
  const _LetraGoogle();

  /// Azul da marca Google.
  static const _azul = Color(0xFF4285F4);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        shape: BoxShape.circle,
      ),
      child: Text(
        'G',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: _azul,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
