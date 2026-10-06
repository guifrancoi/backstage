import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/painel_numeros.dart';
import '../../models/casa_show.dart';
import '../../models/musico.dart';
import '../../providers/auth_provider.dart';
import '../../providers/avaliacao_provider.dart';
import '../../providers/perfil_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/bloco_info.dart';
import '../../widgets/cabecalho_perfil.dart';
import '../../widgets/dados_show_musico.dart';
import '../../widgets/estados.dart';
import '../../widgets/etiqueta.dart';
import '../../widgets/link_portfolio.dart';
import '../../widgets/musico_card.dart' show InfoComIcone;
import '../../widgets/primary_button.dart';
import '../../widgets/titulo_secao.dart';
import '../busca/card_local.dart';
import 'perfil_estabelecimento_form.dart';
import 'perfil_musico_form.dart';

/// "Meu perfil" conforme o papel: músico vê o perfil de artista, dono vê o
/// do estabelecimento e a conta admin vê os dois em abas.
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isAdmin) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Meu perfil'),
            actions: const [_AtalhoBloqueados(), _MenuConta()],
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Artista'),
                Tab(text: 'Estabelecimento'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [_PerfilMusicoAba(), _PerfilEstabelecimentoAba()],
          ),
        ),
      );
    }

    final Widget corpo;
    if (auth.atuaComoMusico) {
      corpo = const _PerfilMusicoAba();
    } else if (auth.atuaComoDono) {
      corpo = const _PerfilEstabelecimentoAba();
    } else {
      corpo = const EstadoVazio(
        icone: Icons.person_outline,
        titulo: 'Sem perfil ainda',
        mensagem: 'Complete seu cadastro para ter um perfil.',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu perfil'),
        actions: const [_AtalhoBloqueados(), _MenuConta()],
      ),
      body: corpo,
    );
  }
}

enum _OpcaoConta { sobre, sair }

/// Plano 8: "Sobre" e "Sair" (antes no AppBar da Home), agora que o Perfil é
/// uma aba da barra inferior.
class _MenuConta extends StatelessWidget {
  const _MenuConta();

  Future<void> _escolher(BuildContext context, _OpcaoConta opcao) async {
    switch (opcao) {
      case _OpcaoConta.sobre:
        Navigator.pushNamed(context, AppRoutes.sobre);
      case _OpcaoConta.sair:
        final navigator = Navigator.of(context, rootNavigator: true);
        await context.read<AuthProvider>().logout();
        navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_OpcaoConta>(
      tooltip: 'Mais opções',
      onSelected: (opcao) => _escolher(context, opcao),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _OpcaoConta.sobre,
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Sobre'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _OpcaoConta.sair,
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Sair'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

/// Plano 22: abre a lista de usuários bloqueados.
class _AtalhoBloqueados extends StatelessWidget {
  const _AtalhoBloqueados();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Usuários bloqueados',
      icon: const Icon(Icons.block),
      onPressed: () => Navigator.pushNamed(context, AppRoutes.bloqueados),
    );
  }
}

void _avisar(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
}

/// Grava pelo provider e avisa o resultado; devolve se deu certo.
Future<bool> _salvarComAviso(
  BuildContext context,
  Future<bool> Function(PerfilProvider provider) salvar,
) async {
  final provider = context.read<PerfilProvider>();
  final ok = await salvar(provider);
  if (!context.mounted) return ok;
  _avisar(
    context,
    ok
        ? 'Perfil atualizado com sucesso!'
        : provider.errorMessage ?? 'Não foi possível salvar o perfil.',
  );
  return ok;
}

class _PerfilMusicoAba extends StatefulWidget {
  const _PerfilMusicoAba();

  @override
  State<_PerfilMusicoAba> createState() => _PerfilMusicoAbaState();
}

class _PerfilMusicoAbaState extends State<_PerfilMusicoAba> {
  bool _editando = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PerfilProvider>();
    final perfil = provider.perfilMusico;

    if (perfil == null && provider.isLoading) {
      return const EstadoCarregando(mensagem: 'Carregando perfil...');
    }

    if (perfil == null || _editando) {
      return SingleChildScrollView(
        padding: _margem,
        child: PerfilMusicoForm(
          key: ValueKey(perfil),
          inicial: perfil,
          nomePadrao: context.read<AuthProvider>().usuario?.nome ?? '',
          onCancelar: perfil == null
              ? null
              : () => setState(() => _editando = false),
          onSalvar: (novo) async {
            final ok = await _salvarComAviso(
              context,
              (p) => p.salvarPerfilMusico(novo),
            );
            if (ok && mounted) setState(() => _editando = false);
          },
        ),
      );
    }

    return _visualizacao(perfil);
  }

  Widget _visualizacao(Musico perfil) {
    final avaliacao = context.watch<AvaliacaoProvider>().resumoDe(perfil.id);
    const espaco = SizedBox(height: AppSpacing.sm);

    return ListView(
      padding: _margem,
      children: [
        CabecalhoPerfil(
          nome: perfil.nomeArtistico,
          foto: perfil.foto,
          etiquetas: [
            if (perfil.generoMusical.isNotEmpty) Etiqueta(perfil.generoMusical),
            if (perfil.cidade.isNotEmpty)
              InfoComIcone(Icons.place_outlined, perfil.cidade),
          ],
        ),
        if (!perfil.completo) ...[espaco, const _AvisoIncompleto()],
        espaco,
        GradeBlocos(
          blocos: [
            BlocoInfo(
              rotulo: 'Cachê médio',
              valor: formatarReais(perfil.cacheMedio),
              cor: context.cores.dinheiro,
            ),
            BlocoInfo(
              rotulo: 'Avaliação',
              valor: avaliacao.temAvaliacao
                  ? avaliacao.rotuloCurto.replaceFirst('★ ', '')
                  : 'Sem avaliações',
              icone: avaliacao.temAvaliacao ? Icons.star_rounded : null,
              cor: avaliacao.temAvaliacao ? AppColors.estrela : null,
            ),
          ],
        ),
        if (perfil.descricao.trim().isNotEmpty) ...[
          espaco,
          CardSecao(titulo: 'Sobre', child: Text(perfil.descricao)),
        ],
        DadosShowMusico(
          musico: perfil,
          padding: const EdgeInsets.only(top: AppSpacing.sm),
        ),
        const SizedBox(height: AppSpacing.lg),
        const TituloSecao('Portfólio'),
        if (perfil.portfolioLinks.isEmpty)
          Text(
            'Nenhum link cadastrado.',
            style: TextStyle(color: context.cores.textoSecundario),
          )
        else
          for (final link in perfil.portfolioLinks) LinkPortfolio(link),
        const SizedBox(height: AppSpacing.lg),
        _AcoesPerfil(
          onEditar: () => setState(() => _editando = true),
          rotaPublica: AppRoutes.detalheMusico,
          id: perfil.id,
        ),
      ],
    );
  }
}

class _PerfilEstabelecimentoAba extends StatefulWidget {
  const _PerfilEstabelecimentoAba();

  @override
  State<_PerfilEstabelecimentoAba> createState() =>
      _PerfilEstabelecimentoAbaState();
}

class _PerfilEstabelecimentoAbaState extends State<_PerfilEstabelecimentoAba> {
  bool _editando = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PerfilProvider>();
    final perfil = provider.perfilEstabelecimento;

    if (perfil == null && provider.isLoading) {
      return const EstadoCarregando(mensagem: 'Carregando perfil...');
    }

    if (perfil == null || _editando) {
      return SingleChildScrollView(
        padding: _margem,
        child: PerfilEstabelecimentoForm(
          key: ValueKey(perfil),
          inicial: perfil,
          onCancelar: perfil == null
              ? null
              : () => setState(() => _editando = false),
          onSalvar: (novo) async {
            final ok = await _salvarComAviso(
              context,
              (p) => p.salvarPerfilEstabelecimento(novo),
            );
            if (ok && mounted) setState(() => _editando = false);
          },
        ),
      );
    }

    return _visualizacao(perfil);
  }

  Widget _visualizacao(CasaShow perfil) {
    final cidade = perfil.estado.isEmpty
        ? perfil.cidade
        : '${perfil.cidade}, ${perfil.estado}';
    final texto = Theme.of(context).textTheme;
    const espaco = SizedBox(height: AppSpacing.sm);

    return ListView(
      padding: _margem,
      children: [
        CabecalhoPerfil(
          nome: perfil.nome,
          etiquetas: [InfoComIcone(Icons.place_outlined, cidade)],
        ),
        if (perfil.capacidade > 0) ...[
          espaco,
          GradeBlocos(
            blocos: [
              BlocoInfo(
                rotulo: 'Capacidade',
                valor: '${perfil.capacidade} pessoas',
                icone: Icons.groups_outlined,
              ),
            ],
          ),
        ],
        espaco,
        CardLocal(
          logradouro: perfil.logradouro,
          numero: perfil.numero,
          cidade: perfil.cidade,
          estado: perfil.estado,
          cep: perfil.cep,
          titulo: 'Endereço',
        ),
        if (perfil.estilosDesejados.isNotEmpty) ...[
          espaco,
          CardSecao(
            titulo: 'Estilos que procura',
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final estilo in perfil.estilosDesejados) Etiqueta(estilo),
              ],
            ),
          ),
        ],
        if (perfil.descricao.trim().isNotEmpty) ...[
          espaco,
          CardSecao(titulo: 'Sobre', child: Text(perfil.descricao)),
        ],
        espaco,
        CardSecao(
          titulo: 'Contato',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(perfil.contato),
              if (perfil.cnpj.isNotEmpty)
                Text('CNPJ: ${perfil.cnpj}', style: texto.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: context.cores.textoSecundario,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      'Visível só para quem tem interesse aceito com você.',
                      style: texto.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _AcoesPerfil(
          onEditar: () => setState(() => _editando = true),
          rotaPublica: AppRoutes.detalheEstabelecimento,
          id: perfil.id,
        ),
      ],
    );
  }
}

const _margem = EdgeInsets.fromLTRB(
  AppSpacing.md,
  AppSpacing.xs,
  AppSpacing.md,
  AppSpacing.lg,
);

/// Perfil de artista sem os obrigatórios (conta criada antes do onboarding).
class _AvisoIncompleto extends StatelessWidget {
  const _AvisoIncompleto();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.avisoFundo,
        borderRadius: AppRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: AppColors.aviso,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'Perfil incompleto: ele só aparece bem na busca depois de '
              'preenchido.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.aviso),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Editar perfil" e "Ver como os outros veem" (abre o perfil público).
class _AcoesPerfil extends StatelessWidget {
  const _AcoesPerfil({
    required this.onEditar,
    required this.rotaPublica,
    required this.id,
  });

  final VoidCallback onEditar;
  final String rotaPublica;
  final String id;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButton(
          text: 'Editar perfil',
          icone: Icons.edit_outlined,
          onPressed: onEditar,
        ),
        if (id.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, rotaPublica, arguments: id),
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Ver como os outros veem'),
          ),
        ],
      ],
    );
  }
}
