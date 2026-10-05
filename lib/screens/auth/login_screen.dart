import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import 'layout_auth.dart';

/// Login (protótipo, Plano 8): marca, e-mail e senha (com mostrar/ocultar),
/// "Esqueceu a senha?" sob o campo e "Novo por aqui? Criar conta".
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final sucesso = await authProvider.login(
      email: _emailController.text.trim(),
      senha: _senhaController.text.trim(),
    );

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login realizado com sucesso!')),
      );

      final precisaCompletarPerfil = await authProvider
          .precisaCompletarPerfil();
      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        precisaCompletarPerfil ? AppRoutes.completarPerfil : AppRoutes.home,
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Erro'),
          content: Text(
            authProvider.errorMessage ?? 'E-mail ou senha inválidos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final texto = Theme.of(context).textTheme;

    return LayoutAuth(
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppLogo(),
              const SizedBox(height: AppSpacing.xl),
              CustomTextField(
                controller: _emailController,
                label: 'E-mail',
                icone: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: Validators.validarEmail,
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _senhaController,
                label: 'Senha',
                icone: Icons.lock_outline,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: Validators.validarSenha,
                onSubmitted: (_) {
                  if (!authProvider.isLoading) _entrar();
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.recuperarSenha),
                  child: const Text('Esqueceu a senha?'),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              PrimaryButton(
                text: 'Entrar',
                carregando: authProvider.isLoading,
                onPressed: _entrar,
              ),
              const SizedBox(height: AppSpacing.md),
              // Wrap: em tela estreita (ou fonte grande) o link desce.
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Novo por aqui?',
                    style: texto.bodyMedium?.copyWith(
                      color: AppColors.textoSecundario,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.cadastro),
                    child: const Text('Criar conta'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
