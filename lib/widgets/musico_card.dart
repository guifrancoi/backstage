import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../models/musico.dart';
import 'avatar_iniciais.dart';
import 'botao_favorito.dart';
import 'etiqueta.dart';
import 'texto_valor.dart';

/// Card de músico das listas (layout do protótipo, Plano 8): avatar, nome,
/// cachê em verde, gênero e cidade, dados do show, descrição e ações.
class MusicoCard extends StatelessWidget {
  final Musico musico;
  final VoidCallback onVerDetalhes;

  /// `null` esconde o botão (ex.: quem vê não é dono de estabelecimento).
  final VoidCallback? onConvidar;

  /// Texto do botão de convite (ex.: "Convidar (1 pendente)"). O botão nunca
  /// fica desabilitado: o estado é por oportunidade, no painel de convite.
  final String rotuloConvidar;

  /// Músico assinante (Plano 7): mostra o selo e vem primeiro na lista.
  final bool assinante;

  /// "★ 4,6 (8)" (Plano 17); `null` = sem avaliações.
  final String? avaliacao;

  /// Plano 18: `null` esconde o coração (quem vê não é dono).
  final VoidCallback? onFavoritar;
  final bool favorito;

  const MusicoCard({
    super.key,
    required this.musico,
    required this.onVerDetalhes,
    this.onConvidar,
    this.rotuloConvidar = 'Convidar',
    this.assinante = false,
    this.avaliacao,
    this.onFavoritar,
    this.favorito = false,
  });

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final resumoShow = musico.resumoShow;

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
                  AvatarIniciais(
                    nome: musico.nomeArtistico,
                    foto: musico.foto,
                    tamanho: 56,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                musico.nomeArtistico,
                                style: texto.titleMedium,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            TextoValor(musico.cacheMedio),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs + 2),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xxs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Etiqueta(musico.generoMusical),
                            InfoComIcone(Icons.place_outlined, musico.cidade),
                            if (avaliacao != null)
                              Text(
                                avaliacao!,
                                style: texto.bodySmall?.copyWith(
                                  color: AppColors.estrela,
                                ),
                              ),
                            if (assinante) const SeloAssinante(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (onFavoritar != null)
                    BotaoFavorito(favorito: favorito, onPressed: onFavoritar!),
                ],
              ),
              if (resumoShow != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  resumoShow,
                  style: texto.labelMedium?.copyWith(
                    color: AppColors.primariaTexto,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              Text(
                musico.descricao,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: texto.bodyMedium?.copyWith(
                  color: context.cores.textoSecundario,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onVerDetalhes,
                      child: const Text('Ver detalhes'),
                    ),
                  ),
                  if (onConvidar != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onConvidar,
                        child: Text(
                          rotuloConvidar,
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

/// Ícone pequeno + texto de apoio ("📍 Franca", "📅 28 jun").
class InfoComIcone extends StatelessWidget {
  const InfoComIcone(this.icone, this.texto, {super.key});

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
        Flexible(
          child: Text(
            texto,
            style: estilo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Selo "Assinante" (Plano 7), usado nos cards de músico e de oportunidade.
class SeloAssinante extends StatelessWidget {
  const SeloAssinante({super.key});

  @override
  Widget build(BuildContext context) {
    return const Etiqueta(
      'Assinante',
      tipo: TipoEtiqueta.aviso,
      icone: Icons.star_rounded,
    );
  }
}
