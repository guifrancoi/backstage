import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/data_hora.dart';
import '../../providers/avaliacao_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../providers/perfil_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/motivos_compatibilidade.dart';
import '../../widgets/musico_card.dart' show SeloAssinante;

/// "Oportunidades para você" (Plano 15) na Home do músico: as 3 futuras
/// mais compatíveis com o perfil e a agenda dele, com os motivos. Sem
/// perfil de músico não aparece.
class OportunidadesParaVoce extends StatelessWidget {
  const OportunidadesParaVoce({super.key});

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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Oportunidades para você',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (sugestoes.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Nenhuma oportunidade compatível no momento.',
                  style: TextStyle(color: AppColors.textoSecundario),
                ),
              ),
            for (final sugestao in sugestoes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    Flexible(child: Text(sugestao.item.titulo)),
                    if (sugestao.assinante) ...[
                      const SizedBox(width: 6),
                      const SeloAssinante(),
                    ],
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (avaliacoes.resumoDe(sugestao.item.donoId)
                        case final resumo when resumo.temAvaliacao)
                      Text(
                        resumo.rotuloCurto,
                        style: const TextStyle(color: AppColors.estrela),
                      ),
                    Text(
                      '${sugestao.item.contratante} · '
                      '${formatarData(sugestao.item.dataEvento)} · '
                      'R\$ ${sugestao.item.cacheOferecido.toStringAsFixed(0)}',
                    ),
                    MotivosCompatibilidade(
                      compatibilidade: sugestao.compatibilidade,
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.detalheOportunidade,
                  arguments: sugestao.item.id,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
