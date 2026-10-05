import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/contratacao.dart';
import '../../models/oportunidade.dart';
import '../../providers/avaliacao_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/avatar_iniciais.dart';
import '../../widgets/etiqueta.dart';
import '../../widgets/motivos_compatibilidade.dart';
import '../../widgets/musico_card.dart' show SeloAssinante;
import '../../widgets/texto_valor.dart';
import '../../widgets/titulo_secao.dart';
import 'acoes_interesse.dart';

/// "Músicos sugeridos" (Plano 15) no detalhe da oportunidade do próprio
/// dono: os 5 mais compatíveis, com os motivos e o Convidar já marcado
/// nesta oportunidade. Quem tem show ou bloqueou o dia não aparece.
class MusicosSugeridosSecao extends StatefulWidget {
  const MusicosSugeridosSecao({super.key, required this.oportunidade});

  final Oportunidade oportunidade;

  @override
  State<MusicosSugeridosSecao> createState() => _MusicosSugeridosSecaoState();
}

class _MusicosSugeridosSecaoState extends State<MusicosSugeridosSecao> {
  late Stream<Set<String>> _indisponiveis = _assinar();

  Stream<Set<String>> _assinar() => context
      .read<OportunidadeProvider>()
      .indisponiveisNoDia(widget.oportunidade.dataEvento);

  @override
  void didUpdateWidget(MusicosSugeridosSecao antigo) {
    super.didUpdateWidget(antigo);
    // Data do evento editada: consulta o novo dia.
    if (Contratacao.diaDe(antigo.oportunidade.dataEvento) !=
        Contratacao.diaDe(widget.oportunidade.dataEvento)) {
      _indisponiveis = _assinar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OportunidadeProvider>();
    final interesses = context.watch<InteresseProvider>();
    // Plano 17: a média aparece junto, mas não entra na nota.
    final avaliacoes = context.watch<AvaliacaoProvider>();

    return StreamBuilder<Set<String>>(
      stream: _indisponiveis,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        // Sem a agenda do dia, sugere mesmo assim (sem "livre no dia").
        final sugestoes = provider.musicosSugeridos(
          widget.oportunidade,
          indisponiveis: snapshot.data,
          comInteresse: interesses.musicosComInteresseEm(
            widget.oportunidade.id,
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TituloSecao('Músicos sugeridos', padding: EdgeInsets.zero),
            Text(
              'Pelo gênero, cidade, cachê e agenda do dia.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (sugestoes.isEmpty)
              const Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: AppSpacing.card,
                  child: Text('Nenhum músico compatível sem convite ainda.'),
                ),
              ),
            for (final sugestao in sugestoes)
              Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Padding(
                  padding: AppSpacing.card,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AvatarIniciais(
                            nome: sugestao.item.nomeArtistico,
                            foto: sugestao.item.foto,
                            tamanho: 48,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sugestao.item.nomeArtistico,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Wrap(
                                  spacing: AppSpacing.xs,
                                  runSpacing: AppSpacing.xxs,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Etiqueta(sugestao.item.generoMusical),
                                    if (sugestao.assinante)
                                      const SeloAssinante(),
                                    if (avaliacoes.resumoDe(sugestao.item.id)
                                        case final resumo
                                        when resumo.temAvaliacao)
                                      Text(
                                        resumo.rotuloCurto,
                                        style: const TextStyle(
                                          color: AppColors.estrela,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          TextoValor(sugestao.item.cacheMedio),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      MotivosCompatibilidade(
                        compatibilidade: sugestao.compatibilidade,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                AppRoutes.detalheMusico,
                                arguments: sugestao.item.id,
                              ),
                              child: const Text('Ver perfil'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => confirmarConvite(
                                context,
                                sugestao.item,
                                oportunidade: widget.oportunidade,
                              ),
                              child: const Text('Convidar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
