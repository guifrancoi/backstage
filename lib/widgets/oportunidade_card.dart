import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/data_hora.dart';
import '../models/oportunidade.dart';
import 'botao_favorito.dart';
import 'etiqueta.dart';
import 'musico_card.dart' show InfoComIcone, SeloAssinante;
import 'texto_valor.dart';

/// Card de oportunidade das listas (layout do protótipo, Plano 8): título,
/// cachê em verde, contratante, gênero/cidade/data, descrição e ações.
class OportunidadeCard extends StatelessWidget {
  final Oportunidade oportunidade;
  final VoidCallback onVerDetalhes;

  /// `null` esconde o botão (ex.: quem vê não é músico, ou a oportunidade
  /// não tem dono).
  final VoidCallback? onCandidatar;

  /// Rótulo da candidatura já enviada; quando presente o botão fica
  /// desabilitado.
  final String? statusCandidatura;

  /// Dono assinante (Plano 7): mostra o selo e vem primeiro na lista.
  final bool assinante;

  /// Plano 18: `null` esconde o coração (quem vê não é músico).
  final VoidCallback? onFavoritar;
  final bool favorita;

  /// Plano 8: troca a linha de botões do fim do card (ex.: Editar/Remover
  /// em "Minhas oportunidades").
  final Widget? rodape;

  const OportunidadeCard({
    super.key,
    required this.oportunidade,
    required this.onVerDetalhes,
    this.onCandidatar,
    this.statusCandidatura,
    this.assinante = false,
    this.onFavoritar,
    this.favorita = false,
    this.rodape,
  });

  /// "28 jun · 21:00 às 23:30" (sem o ano se for o ano corrente).
  String dataFormatada({DateTime? hoje}) {
    final dia = formatarDataCurta(
      oportunidade.dataEvento,
      hoje: hoje ?? DateTime.now(),
    );
    final horario = oportunidade.horario;
    return horario.isEmpty ? dia : '$dia · $horario';
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final mostrarAcao = onCandidatar != null || statusCandidatura != null;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: AppRadius.circular(AppRadius.lg),
        onTap: onVerDetalhes,
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(oportunidade.titulo, style: texto.titleMedium),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  TextoValor(oportunidade.cacheOferecido),
                  if (onFavoritar != null)
                    BotaoFavorito(favorito: favorita, onPressed: onFavoritar!),
                ],
              ),
              const SizedBox(height: 2),
              Text(oportunidade.contratante, style: texto.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xxs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Etiqueta(oportunidade.generoMusical),
                  if (assinante) const SeloAssinante(),
                  InfoComIcone(Icons.place_outlined, oportunidade.cidade),
                  InfoComIcone(Icons.calendar_today_outlined, dataFormatada()),
                ],
              ),
              if (oportunidade.descricao.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  oportunidade.descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: texto.bodyMedium?.copyWith(
                    color: context.cores.textoSecundario,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              rodape ??
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onVerDetalhes,
                          child: const Text('Ver detalhes'),
                        ),
                      ),
                      if (mostrarAcao) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: statusCandidatura == null
                                ? onCandidatar
                                : null,
                            child: Text(
                              statusCandidatura ?? 'Candidatar-se',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
