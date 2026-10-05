import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import 'layout_auth.dart';

/// Recuperar senha (Plano 8): explica o que vai acontecer e, depois de
/// enviar, troca o formulário pela confirmação (sem diálogo).
class RecuperarSenhaScreen extends StatefulWidget {
  const RecuperarSenhaScreen({super.key});

  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  /// E-mail para o qual o link foi pedido (mostra a confirmação).
  String? _enviadoPara;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _recuperar() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final sucesso = await provider.recuperarSenha(email);

    if (!mounted) return;
    if (sucesso) {
      setState(() => _enviadoPara = email);
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erro'),
        content: Text(
          provider.errorMessage ?? 'Não foi possível enviar o e-mail.',
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProvider>();
    final texto = Theme.of(context).textTheme;
    final enviadoPara = _enviadoPara;

    return LayoutAuth(
      appBar: AppBar(backgroundColor: Colors.transparent),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: enviadoPara != null
            ? Column(
                key: const ValueKey('enviado'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _IconeTopo(
                    icone: Icons.mark_email_read_outlined,
                    cor: AppColors.sucesso,
                    fundo: AppColors.sucessoFundo,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Verifique seu e-mail',
                    textAlign: TextAlign.center,
                    style: texto.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Se $enviadoPara estiver cadastrado, as instruções para '
                    'criar uma nova senha chegam em alguns minutos. Confira '
                    'também a caixa de spam.',
                    textAlign: TextAlign.center,
                    style: texto.bodyMedium?.copyWith(
                      color: AppColors.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    text: 'Voltar ao login',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              )
            : Form(
                key: _formKey,
                child: Column(
                  key: const ValueKey('formulario'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _IconeTopo(
                      icone: Icons.lock_reset,
                      cor: AppColors.primariaTexto,
                      fundo: AppColors.primariaContainer,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Recuperar senha',
                      textAlign: TextAlign.center,
                      style: texto.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Informe o e-mail da sua conta e enviaremos um link '
                      'para criar uma nova senha.',
                      textAlign: TextAlign.center,
                      style: texto.bodyMedium?.copyWith(
                        color: AppColors.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CustomTextField(
                      controller: _emailController,
                      label: 'E-mail cadastrado',
                      icone: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.send,
                      autofillHints: const [AutofillHints.email],
                      validator: Validators.validarEmail,
                      onSubmitted: (_) {
                        if (!provider.isLoading) _recuperar();
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      text: 'Enviar link',
                      carregando: provider.isLoading,
                      onPressed: _recuperar,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _IconeTopo extends StatelessWidget {
  const _IconeTopo({
    required this.icone,
    required this.cor,
    required this.fundo,
  });

  final IconData icone;
  final Color cor;
  final Color fundo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(color: fundo, shape: BoxShape.circle),
        child: Icon(icone, size: 34, color: cor),
      ),
    );
  }
}
