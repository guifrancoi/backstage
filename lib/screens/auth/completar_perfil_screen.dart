import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/usuario.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/primary_button.dart';

class CompletarPerfilScreen extends StatefulWidget {
  const CompletarPerfilScreen({super.key});

  @override
  State<CompletarPerfilScreen> createState() => _CompletarPerfilScreenState();
}

class _CompletarPerfilScreenState extends State<CompletarPerfilScreen> {
  TipoUsuario? _tipoSelecionado;

  Future<void> _continuar() async {
    final tipo = _tipoSelecionado;
    if (tipo == null) return;

    final authProvider = context.read<AuthProvider>();
    final sucesso = await authProvider.completarCadastro(tipo);

    if (!mounted) return;

    if (!sucesso) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Erro'),
          content: Text(
            authProvider.errorMessage ?? 'Não foi possível salvar seu perfil.',
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

    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Complete seu cadastro')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Você é músico ou dono de um estabelecimento?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Essa escolha não pode ser alterada depois.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              RadioGroup<TipoUsuario>(
                groupValue: _tipoSelecionado,
                onChanged: (valor) => setState(() => _tipoSelecionado = valor),
                child: const Column(
                  children: [
                    RadioListTile<TipoUsuario>(
                      title: Text('Músico'),
                      subtitle: Text(
                        'Quero divulgar meu trabalho e buscar oportunidades.',
                      ),
                      value: TipoUsuario.musico,
                    ),
                    RadioListTile<TipoUsuario>(
                      title: Text('Dono de estabelecimento'),
                      subtitle: Text(
                        'Quero contratar músicos para meu bar ou casa de show.',
                      ),
                      value: TipoUsuario.casaShow,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: authProvider.isLoading ? 'Salvando...' : 'Continuar',
                onPressed: (_tipoSelecionado == null || authProvider.isLoading)
                    ? null
                    : _continuar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
