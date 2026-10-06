import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/data_hora.dart';
import '../../providers/chat_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/avatar_iniciais.dart';
import '../../widgets/estados.dart';

/// Conversas do usuário (Plano 8): avatar com iniciais, nome, última
/// mensagem, quando e selo de não lidas.
class ConversasScreen extends StatelessWidget {
  const ConversasScreen({super.key});

  /// "14:05" (hoje), "ontem" ou a data curta.
  static String quando(DateTime data, {DateTime? agora}) {
    final hoje = agora ?? DateTime.now();
    final dia = DateTime(data.year, data.month, data.day);
    final hojeDia = DateTime(hoje.year, hoje.month, hoje.day);
    final dias = hojeDia.difference(dia).inDays;
    if (dias == 0) {
      return '${data.hour.toString().padLeft(2, '0')}:'
          '${data.minute.toString().padLeft(2, '0')}';
    }
    if (dias == 1) return 'ontem';
    return formatarDataCurta(data, hoje: hoje);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final conversas = provider.conversas;
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Conversas')),
      body: conversas.isEmpty
          ? const EstadoVazio(
              icone: Icons.chat_bubble_outline,
              titulo: 'Nenhuma conversa ainda',
              mensagem: 'Uma conversa começa quando um interesse é aceito.',
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              itemCount: conversas.length,
              separatorBuilder: (_, _) =>
                  const Divider(indent: 80, endIndent: AppSpacing.md),
              itemBuilder: (context, index) {
                final conversa = conversas[index];
                final naoLidas = provider.naoLidas(conversa);
                final nome = conversa.nomeContato(provider.meuUid);
                final atualizado = conversa.atualizadoEm;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xxs,
                  ),
                  leading: AvatarIniciais(
                    nome: nome,
                    tamanho: 48,
                    circular: true,
                  ),
                  title: Text(nome, style: texto.titleSmall),
                  subtitle: Text(
                    conversa.ultimaMensagem,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: naoLidas > 0
                        ? texto.bodyMedium?.copyWith(
                            color: AppColors.texto,
                            fontWeight: FontWeight.w600,
                          )
                        : texto.bodySmall,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (atualizado != null)
                        Text(
                          quando(atualizado),
                          style: texto.bodySmall?.copyWith(
                            color: naoLidas > 0
                                ? AppColors.primariaTexto
                                : null,
                          ),
                        ),
                      if (naoLidas > 0) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Badge(label: Text('$naoLidas')),
                      ],
                    ],
                  ),
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.chat,
                    arguments: conversa.id,
                  ),
                );
              },
            ),
    );
  }
}
