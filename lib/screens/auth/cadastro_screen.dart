import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import 'layout_auth.dart';

/// Cadastro (protótipo "Criar conta", Plano 8). O tipo de conta (músico ou
/// dono) é escolhido logo depois, no passo 1 do Completar perfil.
class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  /// Validação local (Plano 8): a diferença aparece no próprio campo.
  String? _validarConfirmacao(String? valor) {
    final erro = Validators.validarSenha(valor);
    if (erro != null) return erro;
    if (valor != _senhaController.text) return 'As senhas não coincidem.';
    return null;
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final sucesso = await authProvider.cadastrar(
      nome: _nomeController.text.trim(),
      email: _emailController.text.trim(),
      telefone: _telefoneController.text.trim(),
      senha: _senhaController.text.trim(),
    );

    if (!mounted) return;

    if (!sucesso) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Erro'),
          content: Text(
            authProvider.errorMessage ?? 'Não foi possível criar a conta.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cadastro realizado com sucesso!')),
    );

    final precisaCompletarPerfil = await authProvider.precisaCompletarPerfil();
    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      precisaCompletarPerfil ? AppRoutes.completarPerfil : AppRoutes.home,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final texto = Theme.of(context).textTheme;
    const espaco = SizedBox(height: AppSpacing.md);

    return LayoutAuth(
      appBar: AppBar(backgroundColor: Colors.transparent),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Criar conta', style: texto.displaySmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Bem-vindo ao Backstage',
                style: texto.bodyMedium?.copyWith(
                  color: AppColors.textoSecundario,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CustomTextField(
                controller: _nomeController,
                label: 'Nome',
                icone: Icons.person_outline,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (value) =>
                    Validators.validarCampoObrigatorio(value, 'o nome'),
              ),
              espaco,
              CustomTextField(
                controller: _emailController,
                label: 'E-mail',
                icone: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: Validators.validarEmail,
              ),
              espaco,
              CustomTextField(
                controller: _telefoneController,
                label: 'Telefone',
                icone: Icons.phone_outlined,
                dica: '(16) 99999-0000',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                validator: (value) =>
                    Validators.validarCampoObrigatorio(value, 'o telefone'),
              ),
              espaco,
              CustomTextField(
                controller: _senhaController,
                label: 'Senha',
                icone: Icons.lock_outline,
                obscureText: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.validarSenha,
              ),
              espaco,
              CustomTextField(
                controller: _confirmarSenhaController,
                label: 'Confirmar senha',
                icone: Icons.lock_outline,
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: _validarConfirmacao,
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: 'Criar conta',
                carregando: authProvider.isLoading,
                onPressed: _cadastrar,
              ),
              const SizedBox(height: AppSpacing.sm),
              // Wrap: em tela estreita (ou fonte grande) o link desce.
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Já tem conta?',
                    style: texto.bodyMedium?.copyWith(
                      color: AppColors.textoSecundario,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Entrar'),
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
