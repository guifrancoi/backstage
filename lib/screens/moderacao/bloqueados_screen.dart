import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/data_hora.dart';
import '../../providers/oportunidade_provider.dart';
import '../../widgets/avatar_iniciais.dart';
import '../../widgets/estados.dart';
import 'acoes_moderacao.dart';

/// Usuários que o logado bloqueou (Plano 22), com "Desbloquear".
class BloqueadosScreen extends StatelessWidget {
  const BloqueadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloqueados = context.watch<OportunidadeProvider>().bloqueados;

    return Scaffold(
      appBar: AppBar(title: const Text('Usuários bloqueados')),
      body: bloqueados.isEmpty
          ? const EstadoVazio(
              icone: Icons.shield_outlined,
              titulo: 'Ninguém bloqueado',
              mensagem: 'Você não bloqueou ninguém.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    'Com quem está aqui, nenhum dos dois pode convidar, se '
                    'candidatar, mandar mensagem nem propor show. '
                    'Desbloquear não reabre o que foi encerrado.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                for (final b in bloqueados)
                  Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xxs,
                      ),
                      leading: AvatarIniciais(
                        nome: b.nome.isEmpty ? '?' : b.nome,
                        tamanho: 40,
                        circular: true,
                      ),
                      title: Text(b.nome.isEmpty ? 'Usuário' : b.nome),
                      subtitle: Text(
                        'Bloqueado em ${formatarData(b.criadoEm)}',
                      ),
                      trailing: TextButton(
                        onPressed: () =>
                            desbloquear(context, uid: b.uid, nome: b.nome),
                        child: const Text('Desbloquear'),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
