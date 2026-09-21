import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

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

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_senhaController.text != _confirmarSenhaController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('As senhas não coincidem.')));
      return;
    }

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
            authProvider.errorMessage ?? 'Nao foi possivel criar a conta.',
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

    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _nomeController,
                label: 'Nome',
                validator: (value) =>
                    Validators.validarCampoObrigatorio(value, 'o nome'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                label: 'E-mail',
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validarEmail,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _telefoneController,
                label: 'Telefone',
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    Validators.validarCampoObrigatorio(value, 'o telefone'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _senhaController,
                label: 'Senha',
                obscureText: true,
                validator: Validators.validarSenha,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _confirmarSenhaController,
                label: 'Confirmar senha',
                obscureText: true,
                validator: Validators.validarSenha,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: authProvider.isLoading ? 'Cadastrando...' : 'Cadastrar',
                onPressed: authProvider.isLoading ? null : _cadastrar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
