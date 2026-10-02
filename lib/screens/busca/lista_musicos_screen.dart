import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/data_hora.dart';
import '../../models/filtro_musicos.dart';
import '../../providers/auth_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/musico_card.dart';
import 'acoes_interesse.dart';
import 'painel_filtro_musicos.dart';

/// Músicos do catálogo com filtro (painel "Filtrar" + chips removíveis),
/// no mesmo padrão da lista de oportunidades.
class ListaMusicosScreen extends StatelessWidget {
  const ListaMusicosScreen({super.key});

  Future<void> _abrirFiltro(BuildContext context) async {
    final provider = context.read<OportunidadeProvider>();
    final escolhido = await abrirPainelFiltroMusicos(
      context,
      atual: provider.filtroMusicos,
    );
    if (escolhido != null) provider.aplicarFiltroMusicos(escolhido);
  }

  /// Um chip por critério ligado; o "x" desliga só aquele critério.
  List<Widget> _chips(OportunidadeProvider provider) {
    final f = provider.filtroMusicos;

    Widget chip(String rotulo, FiltroMusicos semEle, {IconData? icone}) =>
        InputChip(
          avatar: icone == null ? null : Icon(icone, size: 18),
          label: Text(rotulo),
          onDeleted: () => provider.aplicarFiltroMusicos(semEle),
          visualDensity: VisualDensity.compact,
        );

    final genero = f.genero;
    final cidade = f.cidade;
    final formacao = f.formacao;
    final livresEm = f.livresEm;
    return [
      if (f.termo.trim().isNotEmpty) chip('"${f.termo}"', f.copyWith(termo: '')),
      if (genero != null && genero.isNotEmpty)
        chip(genero, f.copyWith(limparGenero: true)),
      if (cidade != null && cidade.trim().isNotEmpty)
        chip(cidade, f.copyWith(limparCidade: true)),
      if (formacao != null)
        chip(formacao.rotulo, f.copyWith(limparFormacao: true)),
      if (f.soEquipamentoProprio)
        chip(
          'Equipamento próprio',
          f.copyWith(soEquipamentoProprio: false),
        ),
      if (livresEm != null)
        chip(
          'Livres em ${formatarData(livresEm)}',
          f.copyWith(limparLivresEm: true),
          icone: Icons.event_available,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OportunidadeProvider>();
    final auth = context.watch<AuthProvider>();
    final interesses = context.watch<InteresseProvider>();
    final filtro = provider.filtroMusicos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de músicos'),
        actions: [
          TextButton.icon(
            onPressed: () => _abrirFiltro(context),
            icon: const Icon(Icons.filter_list),
            label: Text(
              filtro.vazio ? 'Filtrar' : 'Filtrar (${filtro.ativos})',
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!filtro.vazio)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ..._chips(provider),
                  TextButton(
                    onPressed: provider.resetarFiltroMusicos,
                    child: const Text('Limpar'),
                  ),
                ],
              ),
            ),
          Expanded(child: _lista(context, provider, auth, interesses, filtro)),
        ],
      ),
    );
  }

  Widget _lista(
    BuildContext context,
    OportunidadeProvider provider,
    AuthProvider auth,
    InteresseProvider interesses,
    FiltroMusicos filtro,
  ) {
    if ((provider.carregandoMusicos && provider.musicos.isEmpty) ||
        provider.carregandoLivres) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.erroMusicos) {
      return const _Mensagem('Erro ao carregar músicos. Verifique sua conexão.');
    }
    final musicos = provider.musicos;
    final livresEm = filtro.livresEm;
    if (musicos.isEmpty) {
      return _Mensagem(
        livresEm == null
            ? 'Nenhum músico encontrado com os filtros informados.'
            : 'Nenhum músico livre em ${formatarData(livresEm)} com os '
                  'filtros informados.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            musicos.length == 1 ? '1 músico' : '${musicos.length} músicos',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: musicos.length,
            itemBuilder: (context, index) {
              final musico = musicos[index];
              final pode = podeConvidar(auth, musico);
              return MusicoCard(
                musico: musico,
                onConvidar: pode
                    ? () => confirmarConvite(context, musico)
                    : null,
                rotuloConvidar: rotuloConvidar(interesses, musico.id),
                onVerDetalhes: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.detalheMusico,
                    arguments: musico.id,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Mensagem extends StatelessWidget {
  const _Mensagem(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
