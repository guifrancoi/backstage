import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/data_hora.dart';
import '../../models/notificacao.dart';
import '../../providers/notificacao_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/estados.dart';

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
          // Plano 8: ícone (o texto longo cortava o título).
          if (provider.naoLidas > 0)
            IconButton(
              tooltip: 'Marcar todas como lidas',
              onPressed: provider.marcarTodasComoLidas,
              icon: const Icon(Icons.done_all),
            ),
        ],
      ),
      body: notificacoes.isEmpty
          ? const EstadoVazio(
              icone: Icons.notifications_none_rounded,
              titulo: 'Tudo em dia',
              mensagem: 'Nenhuma notificação por aqui.',
            )
          : ListView.builder(
              padding: AppSpacing.tela,
              itemCount: notificacoes.length,
              itemBuilder: (context, index) {
                final n = notificacoes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Dismissible(
                    key: ValueKey(n.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      decoration: BoxDecoration(
                        color: AppColors.erroFundo,
                        borderRadius: AppRadius.circular(AppRadius.lg),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: AppSpacing.lg),
                      child: const Icon(
                        Icons.delete_outline,
                        color: AppColors.erro,
                      ),
                    ),
                    onDismissed: (_) => provider.remover(n),
                    child: _CardNotificacao(
                      notificacao: n,
                      onTap: () => _abrir(context, n),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Notificação (Plano 8): ícone pelo assunto, título, texto e quando; não
/// lida = fundo e borda roxos + ponto.
class _CardNotificacao extends StatelessWidget {
  const _CardNotificacao({required this.notificacao, required this.onTap});

  final Notificacao notificacao;
  final VoidCallback onTap;

  IconData get _icone => switch (notificacao.destino) {
    DestinoNotificacao.contratacoes => Icons.handshake_outlined,
    DestinoNotificacao.oportunidade => Icons.event_note_outlined,
    DestinoNotificacao.interesses => Icons.favorite_border_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final n = notificacao;
    final texto = Theme.of(context).textTheme;
    final raio = AppRadius.circular(AppRadius.lg);
    return Material(
      color: n.lida ? AppColors.superficie : AppColors.primariaContainer,
      shape: RoundedRectangleBorder(
        borderRadius: raio,
        side: BorderSide(
          color: n.lida
              ? AppColors.borda
              : AppColors.primaria.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: raio,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: n.lida
                      ? AppColors.superficieAlta
                      : AppColors.primaria.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _icone,
                  size: 20,
                  color: n.lida
                      ? AppColors.textoSecundario
                      : AppColors.primariaTexto,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.titulo,
                      style: texto.titleSmall?.copyWith(
                        fontWeight: n.lida ? FontWeight.w500 : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(n.texto, style: texto.bodyMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      NotificacoesScreen.quando(n.criadaEm),
                      style: texto.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!n.lida)
                Semantics(
                  label: 'Não lida',
                  child: Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 6, left: AppSpacing.xs),
                    decoration: const BoxDecoration(
                      color: AppColors.primaria,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
