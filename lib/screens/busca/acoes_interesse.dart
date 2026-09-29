import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/musico.dart';
import '../../models/oportunidade.dart';
import '../../providers/auth_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../providers/perfil_provider.dart';

/// Ações de candidatura/convite compartilhadas pelas telas de lista e de
/// detalhe da busca.

/// Músico (ou admin) se candidata a oportunidade de outro dono (catálogo sem
/// dono não).
bool podeCandidatar(AuthProvider auth, Oportunidade oportunidade) {
  return auth.atuaComoMusico &&
      oportunidade.temDono &&
      oportunidade.donoId != auth.userId;
}

/// Dono de estabelecimento (ou admin) convida músico.
bool podeConvidar(AuthProvider auth, Musico musico) {
  return auth.atuaComoDono && musico.id != auth.userId;
}

/// Dono da oportunidade ou admin podem editá-la e removê-la.
bool podeGerenciar(AuthProvider auth, Oportunidade oportunidade) {
  return auth.isAdmin ||
      (oportunidade.temDono && oportunidade.donoId == auth.userId);
}

/// Pede confirmação e remove a oportunidade; devolve se removeu.
Future<bool> confirmarRemocao(
  BuildContext context,
  Oportunidade oportunidade,
) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Remover oportunidade'),
      content: Text(
        'Remover "${oportunidade.titulo}"? Essa ação não pode ser desfeita.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Remover'),
        ),
      ],
    ),
  );

  if (confirmar != true || !context.mounted) return false;

  final provider = context.read<OportunidadeProvider>();
  final ok = await provider.removerOportunidade(oportunidade.id);
  if (!context.mounted) return ok;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ok
            ? 'Oportunidade removida.'
            : provider.errorMessage ?? 'Não foi possível remover.',
      ),
    ),
  );
  return ok;
}

Future<void> confirmarCandidatura(
  BuildContext context,
  Oportunidade oportunidade,
) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Candidatar-se'),
      content: Text(
        'Enviar sua candidatura para "${oportunidade.titulo}"? '
        'O contratante poderá aceitar ou recusar.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Enviar'),
        ),
      ],
    ),
  );

  if (confirmar != true || !context.mounted) return;

  final auth = context.read<AuthProvider>();
  final perfil = context.read<PerfilProvider>().perfilMusico;
  final interesses = context.read<InteresseProvider>();

  final ok = await interesses.enviarCandidatura(
    oportunidade: oportunidade,
    remetenteId: auth.userId!,
    remetenteNome: auth.nomeExibicao,
    musicoNome: perfil?.nomeArtistico ?? auth.nomeExibicao,
  );

  if (!context.mounted) return;
  _avisar(
    context,
    ok ? 'Candidatura enviada!' : interesses.errorMessage ?? 'Não foi possível enviar.',
  );
}

Future<void> confirmarConvite(BuildContext context, Musico musico) async {
  final auth = context.read<AuthProvider>();
  final minhas = context.read<OportunidadeProvider>().minhasOportunidades(
    auth.userId,
  );

  Oportunidade? escolhida;
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Convidar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Convidar "${musico.nomeArtistico}"?'),
            if (minhas.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<Oportunidade?>(
                initialValue: escolhida,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Para qual oportunidade? (opcional)',
                ),
                items: [
                  const DropdownMenuItem<Oportunidade?>(
                    value: null,
                    child: Text('Nenhuma específica'),
                  ),
                  for (final oportunidade in minhas)
                    DropdownMenuItem<Oportunidade?>(
                      value: oportunidade,
                      child: Text(
                        oportunidade.titulo,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (valor) => setDialogState(() => escolhida = valor),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Enviar convite'),
          ),
        ],
      ),
    ),
  );

  if (confirmar != true || !context.mounted) return;

  final interesses = context.read<InteresseProvider>();
  final ok = await interesses.enviarConvite(
    musico: musico,
    remetenteId: auth.userId!,
    remetenteNome: auth.nomeExibicao,
    oportunidade: escolhida,
  );

  if (!context.mounted) return;
  _avisar(
    context,
    ok ? 'Convite enviado!' : interesses.errorMessage ?? 'Não foi possível enviar.',
  );
}

void _avisar(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
}
