import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/telefone.dart';
import '../../core/utils/validators.dart';
import '../../models/casa_show.dart';
import '../../models/musico.dart';
import '../../models/usuario.dart';
import '../../providers/auth_provider.dart';
import '../../providers/perfil_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../perfil/perfil_estabelecimento_form.dart';
import '../perfil/perfil_musico_form.dart';

/// Onboarding em 2 passos: (1) escolher o tipo de usuário, (2) preencher o
/// perfil desse tipo. Quem já tem tipo (fechou o app no meio, ou conta antiga
/// com perfil incompleto) abre direto no passo 2, pré-preenchido. Só vai para
/// a Home depois de salvar o passo 2. Conta sem telefone (criada pelo Google,
/// Plano 23) informa o telefone no passo 1, junto com o tipo.
class CompletarPerfilScreen extends StatefulWidget {
  const CompletarPerfilScreen({super.key});

  @override
  State<CompletarPerfilScreen> createState() => _CompletarPerfilScreenState();
}

class _CompletarPerfilScreenState extends State<CompletarPerfilScreen> {
  TipoUsuario? _tipoSelecionado;
  bool _carregandoPerfil = true;
  final _formTelefone = GlobalKey<FormState>();
  final _telefoneController = TextEditingController();

  @override
  void dispose() {
    _telefoneController.dispose();
    super.dispose();
  }

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
    final pedeTelefone = authProvider.precisaTelefone;
    if (pedeTelefone && !_formTelefone.currentState!.validate()) return;

    final sucesso = await authProvider.completarCadastro(
      tipo,
      telefone: pedeTelefone ? _telefoneController.text.trim() : null,
    );

    if (!mounted || sucesso) return;
    _mostrarErro(
      authProvider.errorMessage ?? 'Não foi possível salvar seu perfil.',
    );
  }

  Future<void> _salvarPerfil(
    Future<bool> Function(PerfilProvider) salvar,
  ) async {
    final provider = context.read<PerfilProvider>();
    final ok = await salvar(provider);
    if (!mounted) return;

    if (!ok) {
      _mostrarErro(
        provider.errorMessage ?? 'Não foi possível salvar seu perfil.',
      );
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
    final texto = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _IndicadorPasso(passo: 1),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Você é músico ou dono de um estabelecimento?',
            style: texto.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Essa escolha não pode ser alterada depois.',
            style: texto.bodyMedium?.copyWith(color: AppColors.textoSecundario),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Cartões de "Tipo de conta" do protótipo de cadastro; mesma
          // altura (a área rola, então a altura vem do maior).
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _CartaoTipo(
                    icone: Icons.mic_none_rounded,
                    titulo: 'Músico',
                    descricao:
                        'Quero divulgar meu trabalho e buscar oportunidades.',
                    selecionado: _tipoSelecionado == TipoUsuario.musico,
                    onTap: () =>
                        setState(() => _tipoSelecionado = TipoUsuario.musico),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _CartaoTipo(
                    icone: Icons.storefront_outlined,
                    titulo: 'Dono de estabelecimento',
                    descricao:
                        'Quero contratar músicos para meu bar ou casa de show.',
                    selecionado: _tipoSelecionado == TipoUsuario.casaShow,
                    onTap: () =>
                        setState(() => _tipoSelecionado = TipoUsuario.casaShow),
                  ),
                ),
              ],
            ),
          ),
          if (authProvider.precisaTelefone) ...[
            const SizedBox(height: AppSpacing.lg),
            Form(
              key: _formTelefone,
              child: CustomTextField(
                controller: _telefoneController,
                label: 'Telefone',
                icone: Icons.phone_outlined,
                dica: '(16) 99999-0000',
                ajuda: 'Fica só na sua conta; não aparece no seu perfil.',
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                validator: Validators.validarTelefone,
                formatadores: const [MascaraTelefone()],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            text: 'Continuar',
            carregando: authProvider.isLoading,
            onPressed: _tipoSelecionado == null ? null : _continuar,
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

    final texto = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _IndicadorPasso(passo: 2),
          const SizedBox(height: AppSpacing.lg),
          Text(
            tipo == TipoUsuario.musico
                ? 'Conte sobre seu trabalho artístico.'
                : 'Conte sobre seu estabelecimento.',
            style: texto.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Esses dados aparecem para os outros usuários na busca.',
            style: texto.bodyMedium?.copyWith(color: AppColors.textoSecundario),
          ),
          const SizedBox(height: AppSpacing.lg),
          formulario,
        ],
      ),
    );
  }
}

/// "Passo 1 de 2" com barra de progresso (Plano 8).
class _IndicadorPasso extends StatelessWidget {
  const _IndicadorPasso({required this.passo});

  final int passo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Passo $passo de 2',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.primariaTexto),
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: AppRadius.circular(AppRadius.pilula),
          child: LinearProgressIndicator(value: passo / 2, minHeight: 6),
        ),
      ],
    );
  }
}

/// Cartão de tipo de conta (protótipo): ícone, título e descrição; borda e
/// fundo roxos quando escolhido.
class _CartaoTipo extends StatelessWidget {
  const _CartaoTipo({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.selecionado,
    required this.onTap,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final raio = AppRadius.circular(AppRadius.lg);
    return Semantics(
      selected: selecionado,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selecionado
              ? AppColors.primariaContainer
              : AppColors.superficie,
          borderRadius: raio,
          border: Border.all(
            color: selecionado ? AppColors.primaria : AppColors.borda,
            width: selecionado ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: raio,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Icon(
                    icone,
                    size: 36,
                    color: selecionado
                        ? AppColors.primariaTexto
                        : AppColors.textoSecundario,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: texto.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    descricao,
                    textAlign: TextAlign.center,
                    style: texto.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
