import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/painel_numeros.dart';
import '../../models/denuncia.dart';
import '../../providers/auth_provider.dart';
import '../../providers/avaliacao_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../widgets/bloco_info.dart';
import '../../widgets/botao_favorito.dart';
import '../../widgets/cabecalho_perfil.dart';
import '../../widgets/dados_show_musico.dart';
import '../../widgets/estados.dart';
import '../../widgets/etiqueta.dart';
import '../../widgets/link_portfolio.dart';
import '../../widgets/musico_card.dart' show InfoComIcone, SeloAssinante;
import '../../widgets/primary_button.dart';
import '../../widgets/titulo_secao.dart';
import '../moderacao/acoes_moderacao.dart';
import 'acoes_interesse.dart';
import 'agenda_publica_secao.dart';
import 'avaliacoes_secao.dart';

/// Perfil público do músico (protótipo "perfil do artista", Plano 8):
/// cabeçalho em gradiente, cachê e avaliação em blocos, sobre, dados do
/// show, agenda, avaliações, portfólio e o convite (só para o dono).
class DetalheMusicoScreen extends StatelessWidget {
  final String musicoId;

  const DetalheMusicoScreen({super.key, required this.musicoId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OportunidadeProvider>();
    final auth = context.watch<AuthProvider>();
    final interesses = context.watch<InteresseProvider>();
    final musico = provider.buscarMusicoPorId(musicoId);

    if (musico == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil do artista')),
        body: const EstadoVazio(
          icone: Icons.person_off_outlined,
          titulo: 'Músico não encontrado.',
        ),
      );
    }

    // Plano 22: bloqueado não recebe convite nem favorito.
    final bloqueado = provider.ehBloqueado(musico.id);
    final pode = podeConvidar(auth, musico) && !bloqueado;
    final avaliacao = context.watch<AvaliacaoProvider>().resumoDe(musico.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do artista'),
        actions: [
          if (podeFavoritarMusico(auth, musico) && !bloqueado)
            BotaoFavorito(
              favorito: provider.ehMusicoFavorito(musico.id),
              onPressed: () => alternarFavorito(
                context,
                (p) => p.alternarMusicoFavorito(musico.id),
              ),
            ),
          MenuModeracao(
            alvoUid: musico.id,
            nome: musico.nomeArtistico,
            tipo: TipoAlvoDenuncia.perfil,
            alvoId: musico.id,
            descricao: musico.nomeArtistico,
            rotuloDenuncia: 'Denunciar perfil',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (bloqueado)
              AvisoBloqueado(uid: musico.id, nome: musico.nomeArtistico),
            CabecalhoPerfil(
              nome: musico.nomeArtistico,
              foto: musico.foto,
              etiquetas: [
                Etiqueta(musico.generoMusical),
                InfoComIcone(Icons.place_outlined, musico.cidade),
                if (provider.ehAssinante(musico.id)) const SeloAssinante(),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            GradeBlocos(
              blocos: [
                BlocoInfo(
                  rotulo: 'Cachê médio',
                  valor: formatarReais(musico.cacheMedio),
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
            if (musico.descricao.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              CardSecao(titulo: 'Sobre', child: Text(musico.descricao)),
            ],
            // Some sozinho quando nada do show foi preenchido.
            DadosShowMusico(
              musico: musico,
              padding: const EdgeInsets.only(top: AppSpacing.sm),
            ),
            const SizedBox(height: AppSpacing.sm),
            CardSecao(
              titulo: 'Agenda',
              child: AgendaPublicaSecao(musicoId: musico.id),
            ),
            const SizedBox(height: AppSpacing.sm),
            AvaliacoesSecao(uid: musico.id),
            const SizedBox(height: AppSpacing.lg),
            const TituloSecao('Portfólio'),
            if (musico.portfolioLinks.isEmpty)
              Text(
                'Nenhum link cadastrado.',
                style: TextStyle(color: context.cores.textoSecundario),
              )
            else
              for (final link in musico.portfolioLinks) LinkPortfolio(link),
            if (pode) ...[
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: rotuloConvidar(
                  interesses,
                  musico.id,
                ).replaceFirst('Convidar', 'Convidar para tocar'),
                icone: Icons.mail_outline,
                onPressed: () => confirmarConvite(context, musico),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
