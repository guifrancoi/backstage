import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/data_hora.dart';
import '../../core/utils/painel_numeros.dart';
import '../../models/musico.dart';
import '../../providers/auth_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/avatar_iniciais.dart';
import '../../widgets/card_destaque.dart';
import '../../widgets/titulo_secao.dart';
import 'abas.dart';

/// Destaques da Home do dono (Plano 8, Fase 1): a próxima oportunidade dele
/// (ou o convite para publicar a primeira) e músicos em destaque — a lista
/// da busca, com assinantes primeiro.
class DestaquesDono extends StatelessWidget {
  const DestaquesDono({super.key});

  /// Quantos músicos mostrar na faixa horizontal.
  static const limiteMusicos = 8;

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().userId;
    final provider = context.watch<OportunidadeProvider>();
    final proxima = provider
        .minhasOportunidades(uid)
        .where((o) => !o.vencida)
        .firstOrNull;
    final musicos = provider.musicos
        .where((m) => m.id != uid)
        .take(limiteMusicos)
        .toList();
    final hoje = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloSecao(
          'Sua próxima oportunidade',
          rotuloAcao: 'Ver todas',
          onAcao: () =>
              Navigator.pushNamed(context, AppRoutes.minhasOportunidades),
        ),
        if (proxima != null)
          CardDestaque(
            titulo: proxima.titulo,
            etiqueta: proxima.generoMusical,
            subtitulo: '${proxima.contratante} · ${proxima.cidade}',
            infos: [
              InfoDestaque(
                'Data',
                formatarDataCurta(proxima.dataEvento, hoje: hoje),
              ),
              InfoDestaque(
                'Cachê',
                formatarReais(proxima.cacheOferecido),
                dinheiro: true,
              ),
            ],
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.detalheOportunidade,
              arguments: proxima.id,
            ),
          )
        else
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xxs,
              ),
              leading: const Icon(
                Icons.add_circle_outline,
                color: AppColors.primariaTexto,
              ),
              title: const Text('Publique uma oportunidade'),
              subtitle: const Text('Músicos compatíveis podem se candidatar.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.novaOportunidade),
            ),
          ),
        if (musicos.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          TituloSecao(
            'Músicos em destaque',
            rotuloAcao: 'Ver todos',
            onAcao: () => irParaAba(context, AbaPrincipal.buscar),
          ),
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: musicos.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) => _CardMusico(musicos[i]),
            ),
          ),
        ],
      ],
    );
  }
}

/// Card vertical do protótipo: avatar, nome, gênero · cidade e cachê.
class _CardMusico extends StatelessWidget {
  const _CardMusico(this.musico);

  final Musico musico;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final cores = context.cores;
    return SizedBox(
      width: 148,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: AppRadius.circular(AppRadius.lg),
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.detalheMusico,
            arguments: musico.id,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              children: [
                AvatarIniciais(
                  nome: musico.nomeArtistico,
                  foto: musico.foto,
                  tamanho: 64,
                  circular: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  musico.nomeArtistico,
                  style: texto.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  '${musico.generoMusical} · ${musico.cidade}',
                  style: texto.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: cores.superficieAlta,
                    borderRadius: AppRadius.circular(AppRadius.pilula),
                  ),
                  child: Text(
                    formatarReais(musico.cacheMedio),
                    style: texto.labelMedium?.copyWith(color: cores.dinheiro),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
