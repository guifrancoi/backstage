import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/oportunidade.dart';
import '../../providers/auth_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/estados.dart';
import '../../widgets/etiqueta.dart';
import '../../widgets/oportunidade_card.dart';
import '../../widgets/titulo_secao.dart';
import '../busca/acoes_interesse.dart';

/// Oportunidades publicadas pelo dono de estabelecimento logado, com editar
/// e remover: próximas primeiro, vencidas na seção "Encerradas".
class MinhasOportunidadesScreen extends StatelessWidget {
  const MinhasOportunidadesScreen({super.key});

  void _nova(BuildContext context) =>
      Navigator.pushNamed(context, AppRoutes.novaOportunidade);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final minhas = context.watch<OportunidadeProvider>().minhasOportunidades(
      auth.userId,
    );
    // Vencidas saem da lista pública; aqui o dono ainda as vê, à parte e da
    // mais recente para a mais antiga.
    final proximas = minhas.where((o) => !o.vencida).toList();
    final encerradas = minhas
        .where((o) => o.vencida)
        .toList()
        .reversed
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas oportunidades')),
      floatingActionButton: minhas.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _nova(context),
              icon: const Icon(Icons.add),
              label: const Text('Nova oportunidade'),
            ),
      body: minhas.isEmpty
          ? EstadoVazio(
              icone: Icons.event_note_outlined,
              titulo: 'Nenhuma oportunidade publicada',
              mensagem:
                  'Publique a primeira para receber candidaturas de músicos.',
              rotuloAcao: 'Nova oportunidade',
              onAcao: () => _nova(context),
            )
          : ListView(
              // Espaço no fim para o botão flutuante não cobrir o último card.
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                88,
              ),
              children: [
                if (proximas.isNotEmpty) ...[
                  const TituloSecao('Próximas'),
                  for (final o in proximas) _ItemOportunidade(o),
                ],
                if (encerradas.isNotEmpty) ...[
                  if (proximas.isNotEmpty)
                    const SizedBox(height: AppSpacing.sm),
                  const TituloSecao('Encerradas'),
                  for (final o in encerradas) _ItemOportunidade(o),
                ],
              ],
            ),
    );
  }
}

class _ItemOportunidade extends StatelessWidget {
  const _ItemOportunidade(this.oportunidade);

  final Oportunidade oportunidade;

  @override
  Widget build(BuildContext context) {
    // Candidaturas que ainda esperam a resposta do dono.
    final pendentes = context
        .watch<InteresseProvider>()
        .recebidos
        .where((i) => i.pendente && i.oportunidadeId == oportunidade.id)
        .length;

    final card = OportunidadeCard(
      oportunidade: oportunidade,
      onVerDetalhes: () => Navigator.pushNamed(
        context,
        AppRoutes.detalheOportunidade,
        arguments: oportunidade.id,
      ),
      rodape: Row(
        children: [
          if (pendentes > 0)
            Flexible(
              child: Etiqueta(
                pendentes == 1 ? '1 candidatura' : '$pendentes candidaturas',
                tipo: TipoEtiqueta.aviso,
                icone: Icons.mail_outline,
              ),
            ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => confirmarRemocao(context, oportunidade),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remover'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.editarOportunidade,
              arguments: oportunidade.id,
            ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar'),
          ),
        ],
      ),
    );

    // Encerrada fica atenuada: continua lá para consulta, sem chamar atenção.
    return oportunidade.vencida ? Opacity(opacity: 0.7, child: card) : card;
  }
}
