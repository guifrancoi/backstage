import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/data_hora.dart';
import '../../models/denuncia.dart';
import '../../providers/auth_provider.dart';
import '../../providers/avaliacao_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../widgets/titulo_secao.dart';
import '../moderacao/acoes_moderacao.dart';

/// Avaliações recebidas por [uid] (Plano 17): média e os 5 comentários mais
/// recentes. Usada no detalhe do músico e no perfil do estabelecimento.
/// Plano 8: é um `CardSecao` próprio.
class AvaliacoesSecao extends StatelessWidget {
  const AvaliacoesSecao({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AvaliacaoProvider>();
    final resumo = provider.resumoDe(uid);
    // Plano 22: comentários de quem eu bloqueei não aparecem.
    final catalogo = context.watch<OportunidadeProvider>();
    final meuUid = context.watch<AuthProvider>().userId;
    final recentes = provider
        .recebidasPor(uid)
        .where((a) => !catalogo.ehBloqueado(a.autorId))
        .take(5)
        .toList();

    return CardSecao(
      titulo: 'Avaliações',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!resumo.temAvaliacao)
            const Text(
              'Ainda sem avaliações.',
              style: TextStyle(color: AppColors.textoSecundario),
            )
          else ...[
            Text(
              resumo.rotulo,
              style: const TextStyle(
                color: AppColors.estrela,
                fontWeight: FontWeight.bold,
              ),
            ),
            for (final a in recentes)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${'★' * a.nota}${'☆' * (5 - a.nota)}  ${a.autorNome} · '
                            '${formatarData(a.criadaEm)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        if (a.autorId != meuUid)
                          IconButton(
                            tooltip: 'Denunciar avaliação',
                            visualDensity: VisualDensity.compact,
                            iconSize: 18,
                            icon: const Icon(Icons.flag_outlined),
                            onPressed: () => abrirDenuncia(
                              context,
                              tipo: TipoAlvoDenuncia.avaliacao,
                              alvoId: a.id,
                              alvoUid: a.autorId,
                              descricao: a.comentario.isEmpty
                                  ? '${a.nota} estrelas, sem comentário'
                                  : a.comentario,
                            ),
                          ),
                      ],
                    ),
                    if (a.comentario.isNotEmpty) Text(a.comentario),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
