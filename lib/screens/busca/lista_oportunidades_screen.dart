import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/data_hora.dart';
import '../../models/filtro_oportunidades.dart';
import '../../providers/auth_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/oportunidade_card.dart';
import 'acoes_interesse.dart';
import 'painel_filtro_oportunidades.dart';

/// Oportunidades que ainda vão acontecer, da mais próxima para a mais
/// distante, com filtro (painel "Filtrar" + chips removíveis).
class ListaOportunidadesScreen extends StatelessWidget {
  const ListaOportunidadesScreen({super.key});

  Future<void> _abrirFiltro(BuildContext context) async {
    final provider = context.read<OportunidadeProvider>();
    final escolhido = await abrirPainelFiltroOportunidades(
      context,
      atual: provider.filtroOportunidades,
      mostrarAgenda: context.read<AuthProvider>().atuaComoMusico,
    );
    if (escolhido != null) provider.filtrarOportunidades(escolhido);
  }

  /// Um chip por critério ligado; o "x" desliga só aquele critério.
  List<Widget> _chips(OportunidadeProvider provider) {
    final f = provider.filtroOportunidades;
    void trocar(FiltroOportunidades novo) => provider.filtrarOportunidades(novo);

    Widget chip(String rotulo, FiltroOportunidades semEle) => InputChip(
      label: Text(rotulo),
      onDeleted: () => trocar(semEle),
      visualDensity: VisualDensity.compact,
    );

    final genero = f.genero;
    final cidade = f.cidade;
    final cache = f.cacheMinimo;
    final de = f.de;
    final ate = f.ate;
    return [
      if (genero != null && genero.isNotEmpty)
        chip(genero, f.copyWith(limparGenero: true)),
      if (cidade != null && cidade.trim().isNotEmpty)
        chip(cidade, f.copyWith(limparCidade: true)),
      if (cache != null)
        chip(
          'A partir de R\$ ${cache.toStringAsFixed(0)}',
          f.copyWith(limparCacheMinimo: true),
        ),
      if (de != null) chip('De ${formatarData(de)}', f.copyWith(limparDe: true)),
      if (ate != null)
        chip('Até ${formatarData(ate)}', f.copyWith(limparAte: true)),
      if (f.soDiasLivres)
        chip('Só dias livres', f.copyWith(soDiasLivres: false)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OportunidadeProvider>();
    final auth = context.watch<AuthProvider>();
    final interesses = context.watch<InteresseProvider>();
    final filtro = provider.filtroOportunidades;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de oportunidades'),
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
      body: Builder(
        builder: (context) {
          if (provider.carregandoOportunidades &&
              provider.oportunidades.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.erroOportunidades) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Erro ao carregar oportunidades. Verifique sua conexão.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }
          final oportunidades = provider.oportunidades;

          return Column(
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
                        onPressed: provider.resetarFiltroOportunidades,
                        child: const Text('Limpar'),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  oportunidades.length == 1
                      ? '1 oportunidade'
                      : '${oportunidades.length} oportunidades',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              Expanded(
                child: oportunidades.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            filtro.vazio
                                ? 'Nenhuma oportunidade encontrada.'
                                : 'Nenhuma oportunidade com esses filtros.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: oportunidades.length,
                        itemBuilder: (context, index) {
                          final oportunidade = oportunidades[index];
                          final pode = podeCandidatar(auth, oportunidade);
                          return OportunidadeCard(
                            oportunidade: oportunidade,
                            onCandidatar: pode
                                ? () =>
                                      confirmarCandidatura(context, oportunidade)
                                : null,
                            statusCandidatura: pode
                                ? interesses
                                      .candidaturaPara(oportunidade.id)
                                      ?.rotuloStatus
                                : null,
                            onVerDetalhes: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.detalheOportunidade,
                                arguments: oportunidade.id,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
