import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/data_hora.dart';
import '../../models/notificacao.dart';
import '../../providers/notificacao_provider.dart';
import '../../routes/app_routes.dart';

/// Avisos recebidos, mais recentes primeiro. Tocar marca como lida e leva ao
/// assunto (Interesses, Contratações ou a oportunidade); deslizar remove.
class NotificacoesScreen extends StatelessWidget {
  const NotificacoesScreen({super.key});

  /// "agora", "há 5 min", "há 3 h" ou a data.
  static String quando(DateTime data, {DateTime? agora}) {
    final diferenca = (agora ?? DateTime.now()).difference(data);
    if (diferenca.inMinutes < 1) return 'agora';
    if (diferenca.inHours < 1) return 'há ${diferenca.inMinutes} min';
    if (diferenca.inDays < 1) return 'há ${diferenca.inHours} h';
    return formatarData(data);
  }

  Future<void> _abrir(BuildContext context, Notificacao notificacao) async {
    await context.read<NotificacaoProvider>().marcarComoLida(notificacao);
    if (!context.mounted) return;

    final oportunidadeId = notificacao.oportunidadeId;
    switch (notificacao.destino) {
      case DestinoNotificacao.oportunidade when oportunidadeId != null:
        Navigator.pushNamed(
          context,
          AppRoutes.detalheOportunidade,
          arguments: oportunidadeId,
        );
      case DestinoNotificacao.contratacoes:
        Navigator.pushNamed(context, AppRoutes.contratacoes);
      default:
        Navigator.pushNamed(context, AppRoutes.interesses);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificacaoProvider>();
    final notificacoes = provider.notificacoes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          if (provider.naoLidas > 0)
            TextButton(
              onPressed: provider.marcarTodasComoLidas,
              child: const Text('Marcar todas como lidas'),
            ),
        ],
      ),
      body: notificacoes.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhuma notificação por aqui.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              itemCount: notificacoes.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final n = notificacoes[index];
                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => provider.remover(n),
                  child: ListTile(
                    tileColor: n.lida
                        ? null
                        : Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.08),
                    leading: Icon(
                      n.lida
                          ? Icons.notifications_none
                          : Icons.notifications_active,
                      color: n.lida ? Colors.grey : Colors.deepPurple,
                    ),
                    title: Text(
                      n.titulo,
                      style: TextStyle(
                        fontWeight: n.lida
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text('${n.texto}\n${quando(n.criadaEm)}'),
                    isThreeLine: true,
                    onTap: () => _abrir(context, n),
                  ),
                );
              },
            ),
    );
  }
}
