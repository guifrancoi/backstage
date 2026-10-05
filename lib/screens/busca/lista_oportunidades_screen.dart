import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/data_hora.dart';
import '../../models/filtro_oportunidades.dart';
import '../../providers/auth_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/estados.dart';
import '../../widgets/oportunidade_card.dart';
import 'acoes_interesse.dart';
import 'cabecalho_busca.dart';
import 'painel_filtro_oportunidades.dart';

/// Oportunidades que ainda vão acontecer, da mais próxima para a mais
/// distante (Plano 8): pesquisa e gêneros no topo, demais critérios no
/// painel "Filtrar" (viram chips removíveis).
class ListaOportunidadesScreen extends StatelessWidget {
  const ListaOportunidadesScreen({super.key, this.embutida = false});

  /// Dentro da aba Buscar (Plano 8): sem AppBar próprio.
  final bool embutida;

  Future<void> _abrirFiltro(BuildContext context) async {
    final provider = context.read<OportunidadeProvider>();
    final escolhido = await abrirPainelFiltroOportunidades(
      context,
      atual: provider.filtroOportunidades,
      mostrarAgenda: context.read<AuthProvider>().atuaComoMusico,
    );
    if (escolhido != null) provider.filtrarOportunidades(escolhido);
  }

  /// Um chip por critério do painel; o "x" desliga só aquele critério.
  List<Widget> _chips(OportunidadeProvider provider) {
    final f = provider.filtroOportunidades;

    Widget chip(String rotulo, FiltroOportunidades semEle) => InputChip(
      label: Text(rotulo),
      onDeleted: () => provider.filtrarOportunidades(semEle),
      visualDensity: VisualDensity.compact,
    );

    final cidade = f.cidade;
    final cache = f.cacheMinimo;
    final de = f.de;
    final ate = f.ate;
    return [
      if (cidade != null && cidade.trim().isNotEmpty)
        chip(cidade, f.copyWith(limparCidade: true)),
      if (cache != null)
        chip(
          'A partir de R\$ ${cache.toStringAsFixed(0)}',
          f.copyWith(limparCacheMinimo: true),
        ),
      if (de != null)
        chip('De ${formatarData(de)}', f.copyWith(limparDe: true)),
      if (ate != null)
        chip('Até ${formatarData(ate)}', f.copyWith(limparAte: true)),
      if (f.soDiasLivres)
        chip('Só dias livres', f.copyWith(soDiasLivres: false)),
      if (f.soFavoritas) chip('Favoritas', f.copyWith(soFavoritas: false)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OportunidadeProvider>();
    final auth = context.watch<AuthProvider>();
    final interesses = context.watch<InteresseProvider>();
    final filtro = provider.filtroOportunidades;
    final carregando =
        provider.carregandoOportunidades && provider.oportunidades.isEmpty;
    final total = provider.oportunidades.length;

    return Scaffold(
      appBar: embutida ? null : AppBar(title: const Text('Oportunidades')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CabecalhoBusca(
            termo: filtro.termo,
            onTermo: (termo) =>
                provider.filtrarOportunidades(filtro.copyWith(termo: termo)),
            dica: 'Festival, casa de show, cidade...',
            genero: filtro.genero,
            onGenero: (genero) => provider.filtrarOportunidades(
              genero == null
                  ? filtro.copyWith(limparGenero: true)
                  : filtro.copyWith(genero: genero),
            ),
            contagem: carregando || provider.erroOportunidades
                ? null
                : (total == 1 ? '1 oportunidade' : '$total oportunidades'),
            ativosNoPainel: filtro.ativos,
            onFiltrar: () => _abrirFiltro(context),
            chips: _chips(provider),
            // Limpa só o painel; pesquisa e gênero ficam no topo.
            onLimpar: () => provider.filtrarOportunidades(
              FiltroOportunidades(termo: filtro.termo, genero: filtro.genero),
            ),
          ),
          Expanded(
            child: _lista(
              context,
              provider,
              auth,
              interesses,
              filtro,
              carregando,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lista(
    BuildContext context,
    OportunidadeProvider provider,
    AuthProvider auth,
    InteresseProvider interesses,
    FiltroOportunidades filtro,
    bool carregando,
  ) {
    if (carregando) return const EstadoCarregando();
    if (provider.erroOportunidades) {
      return const EstadoErro(
        mensagem: 'Erro ao carregar oportunidades. Verifique sua conexão.',
      );
    }
    final oportunidades = provider.oportunidades;
    if (oportunidades.isEmpty) {
      return EstadoVazio(
        icone: Icons.event_busy_outlined,
        titulo: 'Nada por aqui',
        mensagem: filtro.semCriterios
            ? 'Nenhuma oportunidade encontrada.'
            : 'Nenhuma oportunidade com esses filtros.',
        rotuloAcao: filtro.semCriterios ? null : 'Limpar filtros',
        onAcao: provider.resetarFiltroOportunidades,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      itemCount: oportunidades.length,
      itemBuilder: (context, index) {
        final oportunidade = oportunidades[index];
        final pode = podeCandidatar(auth, oportunidade);
        return OportunidadeCard(
          oportunidade: oportunidade,
          assinante: provider.ehAssinante(oportunidade.donoId),
          favorita: provider.ehOportunidadeFavorita(oportunidade.id),
          onFavoritar: podeFavoritarOportunidade(auth, oportunidade)
              ? () => alternarFavorito(
                  context,
                  (p) => p.alternarOportunidadeFavorita(oportunidade.id),
                )
              : null,
          onCandidatar: pode
              ? () => confirmarCandidatura(context, oportunidade)
              : null,
          statusCandidatura: pode
              ? interesses.candidaturaPara(oportunidade.id)?.rotuloStatus
              : null,
          onVerDetalhes: () => Navigator.pushNamed(
            context,
            AppRoutes.detalheOportunidade,
            arguments: oportunidade.id,
          ),
        );
      },
    );
  }
}
