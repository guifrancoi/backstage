import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/casa_show.dart';
import '../../models/musico.dart';
import '../../models/usuario.dart';
import '../../providers/auth_provider.dart';
import '../../providers/perfil_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/primary_button.dart';
import '../perfil/perfil_estabelecimento_form.dart';
import '../perfil/perfil_musico_form.dart';

/// Onboarding em 2 passos: (1) escolher o tipo de usuário, (2) preencher o
/// perfil desse tipo. Quem já tem tipo (fechou o app no meio, ou conta antiga
/// com perfil incompleto) abre direto no passo 2, pré-preenchido. Só vai para
/// a Home depois de salvar o passo 2.
class CompletarPerfilScreen extends StatefulWidget {
  const CompletarPerfilScreen({super.key});

  @override
  State<CompletarPerfilScreen> createState() => _CompletarPerfilScreenState();
}

class _CompletarPerfilScreenState extends State<CompletarPerfilScreen> {
  TipoUsuario? _tipoSelecionado;
  bool _carregandoPerfil = true;

  @override
  void initState() {
    super.initState();
    // Garante o perfil (parcial) já gravado antes de montar o formulário:
    // o carregamento disparado pelo login pode ainda não ter terminado.
    Future.microtask(() async {
      if (!mounted) return;
      await context.read<PerfilProvider>().carregarPerfil();
      if (mounted) setState(() => _carregandoPerfil = false);
    });
  }

  void _mostrarErro(String mensagem) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erro'),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _continuar() async {
    final tipo = _tipoSelecionado;
    if (tipo == null) return;

    final authProvider = context.read<AuthProvider>();
    final sucesso = await authProvider.completarCadastro(tipo);

    if (!mounted || sucesso) return;
    _mostrarErro(
      authProvider.errorMessage ?? 'Não foi possível salvar seu perfil.',
    );
  }

  Future<void> _salvarPerfil(Future<bool> Function(PerfilProvider) salvar) async {
    final provider = context.read<PerfilProvider>();
    final ok = await salvar(provider);
    if (!mounted) return;

    if (!ok) {
      _mostrarErro(provider.errorMessage ?? 'Não foi possível salvar seu perfil.');
      return;
    }
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final tipo = authProvider.tipoUsuario;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tipo == null ? 'Complete seu cadastro (1/2)' : 'Seu perfil (2/2)',
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: tipo == null
            ? _passoTipo(authProvider)
            : _carregandoPerfil
            ? const Center(child: CircularProgressIndicator())
            : _passoPerfil(tipo, authProvider),
      ),
    );
  }

  Widget _passoTipo(AuthProvider authProvider) {
    return Padding(
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
            style: TextStyle(color: AppColors.textoSecundario),
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
    );
  }

  Widget _passoPerfil(TipoUsuario tipo, AuthProvider authProvider) {
    final perfilProvider = context.read<PerfilProvider>();

    final Widget formulario = switch (tipo) {
      TipoUsuario.musico => PerfilMusicoForm(
        inicial: perfilProvider.perfilMusico,
        nomePadrao: authProvider.usuario?.nome ?? '',
        textoSalvar: 'Concluir',
        onSalvar: (Musico perfil) =>
            _salvarPerfil((p) => p.salvarPerfilMusico(perfil)),
      ),
      TipoUsuario.casaShow => PerfilEstabelecimentoForm(
        inicial: perfilProvider.perfilEstabelecimento,
        textoSalvar: 'Concluir',
        onSalvar: (CasaShow perfil) =>
            _salvarPerfil((p) => p.salvarPerfilEstabelecimento(perfil)),
      ),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tipo == TipoUsuario.musico
                ? 'Conte sobre seu trabalho artístico.'
                : 'Conte sobre seu estabelecimento.',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esses dados aparecem para os outros usuários na busca.',
            style: TextStyle(color: AppColors.textoSecundario),
          ),
          const SizedBox(height: 24),
          formulario,
        ],
      ),
    );
  }
}
