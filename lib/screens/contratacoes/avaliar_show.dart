import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/avaliacao.dart';
import '../../models/contratacao.dart';
import '../../providers/auth_provider.dart';
import '../../providers/avaliacao_provider.dart';

/// Abre a folha "Avaliar show" (Plano 17): 1 a 5 estrelas e comentário
/// opcional; envia pelo `AvaliacaoProvider` e mostra o resultado.
Future<void> avaliarShow(BuildContext context, Contratacao contratacao) async {
  final uid = context.read<AuthProvider>().userId;
  final avaliado = uid == contratacao.musicoId
      ? contratacao.donoNome
      : contratacao.musicoNome;
  final enviado = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        _FolhaAvaliacao(contratacao: contratacao, avaliado: avaliado),
  );
  if (enviado == null || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        enviado
            ? 'Avaliação enviada. Obrigado!'
            : context.read<AvaliacaoProvider>().errorMessage ??
                  'Não foi possível enviar a avaliação.',
      ),
    ),
  );
}

class _FolhaAvaliacao extends StatefulWidget {
  const _FolhaAvaliacao({required this.contratacao, required this.avaliado});

  final Contratacao contratacao;
  final String avaliado;

  @override
  State<_FolhaAvaliacao> createState() => _FolhaAvaliacaoState();
}

class _FolhaAvaliacaoState extends State<_FolhaAvaliacao> {
  final _comentario = TextEditingController();
  int _nota = 0;
  bool _enviando = false;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    final ok = await context.read<AvaliacaoProvider>().avaliar(
      widget.contratacao,
      nota: _nota,
      comentario: _comentario.text,
    );
    if (mounted) Navigator.pop(context, ok);
  }

  /// O que cada nota quer dizer (Plano 8).
  static const _significados = [
    'Toque nas estrelas',
    'Ruim',
    'Regular',
    'Bom',
    'Muito bom',
    'Excelente',
  ];

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Avaliar ${widget.avaliado}', style: texto.titleLarge),
            Text(widget.contratacao.titulo, style: texto.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    tooltip: '$i estrela${i == 1 ? '' : 's'}',
                    iconSize: 36,
                    color: AppColors.estrela,
                    icon: Icon(
                      i <= _nota
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                    ),
                    onPressed: () => setState(() => _nota = i),
                  ),
              ],
            ),
            Text(
              _significados[_nota],
              textAlign: TextAlign.center,
              style: texto.labelLarge?.copyWith(
                color: _nota == 0
                    ? AppColors.textoSecundario
                    : AppColors.estrela,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _comentario,
              maxLines: 3,
              maxLength: Avaliacao.tamanhoMaximoComentario,
              decoration: const InputDecoration(
                labelText: 'Comentário (opcional)',
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ElevatedButton(
              onPressed: _nota == 0 || _enviando ? null : _enviar,
              child: Text(_enviando ? 'Enviando...' : 'Enviar avaliação'),
            ),
          ],
        ),
      ),
    );
  }
}
