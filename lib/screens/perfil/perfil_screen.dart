import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/foto_perfil.dart';
import '../../widgets/dados_show_musico.dart';
import '../../models/casa_show.dart';
import '../../models/musico.dart';
import '../../providers/auth_provider.dart';
import '../../providers/perfil_provider.dart';
import '../../routes/app_routes.dart';
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
            actions: const [_AtalhoBloqueados()],
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
      corpo = const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Complete seu cadastro para ter um perfil.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu perfil'),
        actions: const [_AtalhoBloqueados()],
      ),
      body: corpo,
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
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(mensagem)));
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

  Future<void> _abrirLink(String link) async {
    var url = link.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      _avisar(context, 'Link inválido.');
      return;
    }

    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abriu && mounted) _avisar(context, 'Não foi possível abrir o link.');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PerfilProvider>();
    final perfil = provider.perfilMusico;

    if (perfil == null && provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (perfil == null || _editando) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
    final imagem = imagemDaFoto(perfil.foto);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: CircleAvatar(
            radius: 55,
            backgroundColor: Colors.deepPurple.shade100,
            backgroundImage: imagem,
            child: imagem == null
                ? const Icon(Icons.person, size: 55, color: Colors.deepPurple)
                : null,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            perfil.nomeArtistico,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        if (!perfil.completo) ...[
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Perfil incompleto: ele só aparece bem na busca depois de preenchido.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gênero: ${perfil.generoMusical}'),
                const SizedBox(height: 8),
                Text('Cidade: ${perfil.cidade}'),
                const SizedBox(height: 8),
                Text(
                  'Cachê médio: R\$ ${perfil.cacheMedio.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 16),
                Text('Descrição: ${perfil.descricao}'),
                DadosShowMusico(musico: perfil),
                const SizedBox(height: 16),
                const Text(
                  'Portfólio',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (perfil.portfolioLinks.isEmpty)
                  const Text('Nenhum link cadastrado.')
                else
                  ...perfil.portfolioLinks.map(
                    (link) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _abrirLink(link),
                        child: Text(
                          link,
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => setState(() => _editando = true),
          icon: const Icon(Icons.edit),
          label: const Text('Editar perfil'),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (perfil == null || _editando) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
    final endereco = [
      '${perfil.logradouro}, ${perfil.numero}',
      '${perfil.cidade} - ${perfil.estado}',
      if (perfil.cep != null) 'CEP ${perfil.cep}',
    ].join('\n');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Center(
          child: CircleAvatar(
            radius: 55,
            child: Icon(Icons.storefront, size: 55),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            perfil.nome,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Endereço',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(endereco),
                const SizedBox(height: 16),
                Text('Contato: ${perfil.contato}'),
                if (perfil.cnpj.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('CNPJ: ${perfil.cnpj}'),
                ],
                if (perfil.capacidade > 0) ...[
                  const SizedBox(height: 8),
                  Text('Capacidade: ${perfil.capacidade} pessoas'),
                ],
                if (perfil.estilosDesejados.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Estilos: ${perfil.estilosDesejados.join(', ')}'),
                ],
                if (perfil.descricao.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Descrição: ${perfil.descricao}'),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => setState(() => _editando = true),
          icon: const Icon(Icons.edit),
          label: const Text('Editar perfil'),
        ),
      ],
    );
  }
}
