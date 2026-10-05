import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/data_hora.dart';
import '../../models/filtro_musicos.dart';
import '../../providers/auth_provider.dart';
import '../../providers/avaliacao_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/estados.dart';
import '../../widgets/musico_card.dart';
import 'acoes_interesse.dart';
import 'cabecalho_busca.dart';
import 'painel_filtro_musicos.dart';

/// Músicos do catálogo (Plano 8): pesquisa e gêneros no topo, demais
/// critérios no painel "Filtrar" (viram chips removíveis), no mesmo padrão
/// da lista de oportunidades.
class ListaMusicosScreen extends StatelessWidget {
  const ListaMusicosScreen({super.key, this.embutida = false});

  /// Dentro da aba Buscar (Plano 8): sem AppBar próprio.
  final bool embutida;

  Future<void> _abrirFiltro(BuildContext context) async {
    final provider = context.read<OportunidadeProvider>();
    final escolhido = await abrirPainelFiltroMusicos(
      context,
      atual: provider.filtroMusicos,
      mostrarFavoritos: context.read<AuthProvider>().atuaComoDono,
    );
    if (escolhido != null) provider.aplicarFiltroMusicos(escolhido);
  }

  /// Um chip por critério do painel; o "x" desliga só aquele critério.
  List<Widget> _chips(OportunidadeProvider provider) {
    final f = provider.filtroMusicos;

    Widget chip(String rotulo, FiltroMusicos semEle, {IconData? icone}) =>
        InputChip(
          avatar: icone == null ? null : Icon(icone, size: 18),
          label: Text(rotulo),
          onDeleted: () => provider.aplicarFiltroMusicos(semEle),
          visualDensity: VisualDensity.compact,
        );

    final cidade = f.cidade;
    final formacao = f.formacao;
    final livresEm = f.livresEm;
    return [
      if (cidade != null && cidade.trim().isNotEmpty)
        chip(cidade, f.copyWith(limparCidade: true)),
      if (formacao != null)
        chip(formacao.rotulo, f.copyWith(limparFormacao: true)),
      if (f.soEquipamentoProprio)
        chip('Equipamento próprio', f.copyWith(soEquipamentoProprio: false)),
      if (f.soFavoritos)
        chip(
          'Favoritos',
          f.copyWith(soFavoritos: false),
          icone: Icons.favorite,
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
    final carregando =
        (provider.carregandoMusicos && provider.musicos.isEmpty) ||
        provider.carregandoLivres;
    final total = provider.musicos.length;

    return Scaffold(
      appBar: embutida ? null : AppBar(title: const Text('Músicos')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CabecalhoBusca(
            termo: filtro.termo,
            onTermo: (termo) =>
                provider.aplicarFiltroMusicos(filtro.copyWith(termo: termo)),
            dica: 'Nome, gênero, cidade...',
            genero: filtro.genero,
            onGenero: (genero) => provider.aplicarFiltroMusicos(
              genero == null
                  ? filtro.copyWith(limparGenero: true)
                  : filtro.copyWith(genero: genero),
            ),
            contagem: carregando || provider.erroMusicos
                ? null
                : (total == 1 ? '1 músico' : '$total músicos'),
            ativosNoPainel: filtro.ativos,
            onFiltrar: () => _abrirFiltro(context),
            chips: _chips(provider),
            // Limpa só o painel; pesquisa e gênero ficam no topo.
            onLimpar: () => provider.aplicarFiltroMusicos(
              FiltroMusicos(
                termo: filtro.termo,
                genero: filtro.genero,
                ordenacao: filtro.ordenacao,
              ),
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
    FiltroMusicos filtro,
    bool carregando,
  ) {
    if (carregando) return const EstadoCarregando();
    if (provider.erroMusicos) {
      return const EstadoErro(
        mensagem: 'Erro ao carregar músicos. Verifique sua conexão.',
      );
    }
    final musicos = provider.musicos;
    final livresEm = filtro.livresEm;
    if (musicos.isEmpty) {
      return EstadoVazio(
        icone: Icons.mic_off_outlined,
        titulo: 'Nenhum músico encontrado',
        mensagem: livresEm == null
            ? 'Nenhum músico encontrado com os filtros informados.'
            : 'Nenhum músico livre em ${formatarData(livresEm)} com os '
                  'filtros informados.',
        rotuloAcao: filtro.semCriterios ? null : 'Limpar filtros',
        onAcao: provider.resetarFiltroMusicos,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      itemCount: musicos.length,
      itemBuilder: (context, index) {
        final musico = musicos[index];
        final pode = podeConvidar(auth, musico);
        return MusicoCard(
          musico: musico,
          onConvidar: pode ? () => confirmarConvite(context, musico) : null,
          rotuloConvidar: rotuloConvidar(interesses, musico.id),
          assinante: provider.ehAssinante(musico.id),
          avaliacao: _avaliacao(context, musico.id),
          favorito: provider.ehMusicoFavorito(musico.id),
          onFavoritar: podeFavoritarMusico(auth, musico)
              ? () => alternarFavorito(
                  context,
                  (p) => p.alternarMusicoFavorito(musico.id),
                )
              : null,
          onVerDetalhes: () => Navigator.pushNamed(
            context,
            AppRoutes.detalheMusico,
            arguments: musico.id,
          ),
        );
      },
    );
  }
}

/// "★ 4,6 (8)" do músico, ou `null` se ainda não foi avaliado (Plano 17).
String? _avaliacao(BuildContext context, String uid) {
  final resumo = context.watch<AvaliacaoProvider>().resumoDe(uid);
  return resumo.temAvaliacao ? resumo.rotuloCurto : null;
}
