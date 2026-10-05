import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/foto_perfil.dart';
import '../models/musico.dart';
import 'botao_favorito.dart';

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
    final mostrarAcao = onConvidar != null;
    final foto = imagemDaFoto(musico.foto);
    final resumoShow = musico.resumoShow;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage: foto,
                child: foto == null ? const Icon(Icons.music_note) : null,
              ),
              title: Row(
                children: [
                  Flexible(child: Text(musico.nomeArtistico)),
                  if (assinante) ...[
                    const SizedBox(width: 6),
                    const SeloAssinante(),
                  ],
                ],
              ),
              subtitle: Text(
                '${musico.generoMusical} • ${musico.cidade}'
                '${avaliacao == null ? '' : ' • $avaliacao'}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('R\$ ${musico.cacheMedio.toStringAsFixed(0)}'),
                  if (onFavoritar != null)
                    BotaoFavorito(favorito: favorito, onPressed: onFavoritar!),
                ],
              ),
            ),
            if (resumoShow != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  resumoShow,
                  style: const TextStyle(
                    color: AppColors.primariaTexto,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              musico.descricao,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onVerDetalhes,
                    child: const Text('Ver detalhes'),
                  ),
                ),
                if (mostrarAcao) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConvidar,
                      child: Text(rotuloConvidar),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Selo "Assinante" (Plano 7), usado nos cards de músico e de oportunidade.
class SeloAssinante extends StatelessWidget {
  const SeloAssinante({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.avisoFundo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 14, color: AppColors.estrela),
          SizedBox(width: 2),
          Text('Assinante', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
