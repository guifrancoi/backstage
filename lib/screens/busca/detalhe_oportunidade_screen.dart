import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/data_hora.dart';
import '../../core/utils/painel_numeros.dart';
import '../../models/denuncia.dart';
import '../../models/oportunidade.dart';
import '../../providers/auth_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/avatar_iniciais.dart';
import '../../widgets/botao_favorito.dart';
import '../../widgets/card_destaque.dart';
import '../../widgets/estados.dart';
import '../../widgets/etiqueta.dart';
import '../../widgets/musico_card.dart' show SeloAssinante;
import '../../widgets/primary_button.dart';
import '../../widgets/titulo_secao.dart';
import '../moderacao/acoes_moderacao.dart';
import 'acoes_interesse.dart';
import 'card_local.dart';
import 'musicos_sugeridos_secao.dart';

/// Detalhe da oportunidade (protótipo "evento", Plano 8): card de destaque
/// com data, cachê, cidade e horário; contratante (abre o perfil do
/// estabelecimento); descrição; local com mapa; e as ações pelo papel —
/// candidatura do músico, ou sugestões, editar e remover do dono.
class DetalheOportunidadeScreen extends StatelessWidget {
  final String oportunidadeId;

  const DetalheOportunidadeScreen({super.key, required this.oportunidadeId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OportunidadeProvider>();
    final auth = context.watch<AuthProvider>();
    final interesses = context.watch<InteresseProvider>();
    final oportunidade = provider.buscarOportunidadePorId(oportunidadeId);

    if (oportunidade == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes da oportunidade')),
        body: const EstadoVazio(
          icone: Icons.event_busy_outlined,
          titulo: 'Oportunidade não encontrada.',
          mensagem: 'Ela pode ter sido removida pelo contratante.',
        ),
      );
    }

    final pode = podeCandidatar(auth, oportunidade);
    final candidatura = interesses.candidaturaPara(oportunidade.id);
    final gerencia = podeGerenciar(auth, oportunidade);
    final hoje = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da oportunidade'),
        actions: [
          if (podeFavoritarOportunidade(auth, oportunidade))
            BotaoFavorito(
              favorito: provider.ehOportunidadeFavorita(oportunidade.id),
              onPressed: () => alternarFavorito(
                context,
                (p) => p.alternarOportunidadeFavorita(oportunidade.id),
              ),
            ),
          if (oportunidade.temDono)
            MenuModeracao(
              alvoUid: oportunidade.donoId,
              nome: oportunidade.contratante,
              tipo: TipoAlvoDenuncia.oportunidade,
              alvoId: oportunidade.id,
              descricao: oportunidade.titulo,
              rotuloDenuncia: 'Denunciar oportunidade',
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
            CardDestaque(
              titulo: oportunidade.titulo,
              etiqueta: oportunidade.generoMusical,
              selo: oportunidade.vencida
                  ? const Etiqueta(
                      'Evento encerrado',
                      tipo: TipoEtiqueta.erro,
                      icone: Icons.event_busy,
                    )
                  : (provider.ehAssinante(oportunidade.donoId)
                        ? const SeloAssinante()
                        : null),
              subtitulo: oportunidade.contratante,
              infos: [
                InfoDestaque(
                  'Data',
                  formatarDataCurta(oportunidade.dataEvento, hoje: hoje),
                ),
                InfoDestaque(
                  'Cachê',
                  formatarReais(oportunidade.cacheOferecido),
                  dinheiro: true,
                ),
                InfoDestaque(
                  'Cidade',
                  oportunidade.estado.isEmpty
                      ? oportunidade.cidade
                      : '${oportunidade.cidade}, ${oportunidade.estado}',
                ),
                if (oportunidade.horario.isNotEmpty)
                  InfoDestaque('Horário', oportunidade.horario),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _CardContratante(oportunidade: oportunidade),
            if (oportunidade.descricao.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              CardSecao(
                titulo: 'Descrição',
                child: Text(oportunidade.descricao),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            CardLocal(
              logradouro: oportunidade.logradouro,
              numero: oportunidade.numero,
              cidade: oportunidade.cidade,
              estado: oportunidade.estado,
              cep: oportunidade.cep,
            ),
            if (pode) ...[
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: candidatura?.rotuloStatus ?? 'Candidatar-se',
                icone: Icons.send_outlined,
                onPressed: candidatura == null
                    ? () => confirmarCandidatura(context, oportunidade)
                    : null,
              ),
            ],
            // Atalho do dono (Plano 13): quem pode tocar nesse dia.
            if (gerencia && auth.atuaComoDono && !oportunidade.vencida) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () {
                  provider.filtrarMusicosLivresEm(oportunidade.dataEvento);
                  Navigator.pushNamed(context, AppRoutes.listaMusicos);
                },
                icon: const Icon(Icons.event_available),
                label: const Text('Ver músicos livres neste dia'),
              ),
              const SizedBox(height: AppSpacing.lg),
              MusicosSugeridosSecao(oportunidade: oportunidade),
            ],
            if (gerencia) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final removeu = await confirmarRemocao(
                          context,
                          oportunidade,
                        );
                        if (removeu && context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remover'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.editarOportunidade,
                        arguments: oportunidade.id,
                      ),
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Quem contrata (Plano 16): toca para abrir o perfil do estabelecimento.
/// Oportunidade de catálogo (sem dono) só mostra o nome.
class _CardContratante extends StatelessWidget {
  const _CardContratante({required this.oportunidade});

  final Oportunidade oportunidade;

  @override
  Widget build(BuildContext context) {
    final temPerfil = oportunidade.temDono;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        leading: AvatarIniciais(nome: oportunidade.contratante, tamanho: 44),
        title: const RotuloSecao('Contratante', destaque: true),
        subtitle: Text(
          oportunidade.contratante,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        trailing: temPerfil
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ver perfil',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: context.cores.primariaTexto,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: context.cores.primariaTexto),
                ],
              )
            : null,
        onTap: temPerfil
            ? () => Navigator.pushNamed(
                context,
                AppRoutes.detalheEstabelecimento,
                arguments: oportunidade.donoId,
              )
            : null,
      ),
    );
  }
}
