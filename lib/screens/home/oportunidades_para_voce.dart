import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/compatibilidade.dart';
import '../../core/utils/data_hora.dart';
import '../../core/utils/painel_numeros.dart';
import '../../models/avaliacao.dart';
import '../../models/oportunidade.dart';
import '../../providers/avaliacao_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../providers/perfil_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/card_destaque.dart';
import '../../widgets/etiqueta.dart';
import '../../widgets/motivos_compatibilidade.dart';
import '../../widgets/musico_card.dart' show SeloAssinante;
import '../../widgets/texto_valor.dart';
import '../../widgets/titulo_secao.dart';
import 'abas.dart';

/// "Oportunidades para você" (Plano 15) na Home do músico: as 3 futuras
/// mais compatíveis com o perfil e a agenda dele, com os motivos. A mais
/// compatível vai no card de destaque (Plano 8). Sem perfil de músico não
/// aparece.
class OportunidadesParaVoce extends StatelessWidget {
  const OportunidadesParaVoce({super.key});

  void _abrir(BuildContext context, Oportunidade oportunidade) {
    Navigator.pushNamed(
      context,
      AppRoutes.detalheOportunidade,
      arguments: oportunidade.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<PerfilProvider>().perfilMusico;
    if (perfil == null) return const SizedBox.shrink();
    final provider = context.watch<OportunidadeProvider>();
    final interesses = context.watch<InteresseProvider>();
    // Plano 17: média do dono, só informativa.
    final avaliacoes = context.watch<AvaliacaoProvider>();
    final sugestoes = provider.oportunidadesSugeridas(
      perfil,
      comInteresse: interesses.oportunidadesComInteresse(),
    );
    final hoje = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloSecao(
          'Oportunidades para você',
          rotuloAcao: 'Ver todas',
          onAcao: () => irParaAba(context, AbaPrincipal.buscar),
        ),
        if (sugestoes.isEmpty)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: AppSpacing.card,
              child: Text(
                'Nenhuma oportunidade compatível no momento.',
                style: TextStyle(color: context.cores.textoSecundario),
              ),
            ),
          ),
        for (final (i, sugestao) in sugestoes.indexed) ...[
          if (i == 0)
            _Destaque(
              sugestao: sugestao,
              hoje: hoje,
              onTap: () => _abrir(context, sugestao.item),
            )
          else
            _Compacta(
              sugestao: sugestao,
              resumoDono: avaliacoes.resumoDe(sugestao.item.donoId),
              onTap: () => _abrir(context, sugestao.item),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (sugestoes.isNotEmpty) const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _Destaque extends StatelessWidget {
  const _Destaque({
    required this.sugestao,
    required this.hoje,
    required this.onTap,
  });

  final Sugestao<Oportunidade> sugestao;
  final DateTime hoje;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final o = sugestao.item;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CardDestaque(
          titulo: o.titulo,
          etiqueta: o.generoMusical,
          selo: sugestao.assinante ? const SeloAssinante() : null,
          subtitulo: '${o.contratante} · ${o.cidade}',
          infos: [
            InfoDestaque('Data', formatarDataCurta(o.dataEvento, hoje: hoje)),
            InfoDestaque(
              'Cachê',
              formatarReais(o.cacheOferecido),
              dinheiro: true,
            ),
          ],
          onTap: onTap,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxs,
            AppSpacing.xs,
            AppSpacing.xxs,
            0,
          ),
          child: MotivosCompatibilidade(
            compatibilidade: sugestao.compatibilidade,
          ),
        ),
      ],
    );
  }
}

class _Compacta extends StatelessWidget {
  const _Compacta({
    required this.sugestao,
    required this.resumoDono,
    required this.onTap,
  });

  final Sugestao<Oportunidade> sugestao;
  final ResumoAvaliacoes resumoDono;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final o = sugestao.item;
    final texto = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: AppRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(o.titulo, style: texto.titleMedium)),
                  const SizedBox(width: AppSpacing.xs),
                  TextoValor(o.cacheOferecido),
                ],
              ),
              const SizedBox(height: 2),
              Text(o.contratante, style: texto.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xxs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Etiqueta(o.generoMusical),
                  if (sugestao.assinante) const SeloAssinante(),
                  _Detalhe(Icons.place_outlined, o.cidade),
                  _Detalhe(
                    Icons.calendar_today_outlined,
                    formatarDataCurta(o.dataEvento, hoje: DateTime.now()),
                  ),
                  if (resumoDono.temAvaliacao)
                    Text(
                      resumoDono.rotuloCurto,
                      style: texto.bodySmall?.copyWith(
                        color: AppColors.estrela,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              MotivosCompatibilidade(compatibilidade: sugestao.compatibilidade),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ícone pequeno + texto de apoio ("📍 Franca").
class _Detalhe extends StatelessWidget {
  const _Detalhe(this.icone, this.texto);

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.bodySmall;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 14, color: estilo?.color),
        const SizedBox(width: 3),
        Text(texto, style: estilo),
      ],
    );
  }
}
