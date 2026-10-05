import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/foto_perfil.dart';

/// Avatar do protótipo (Plano 8): a miniatura do perfil quando existe; senão
/// as iniciais do nome em roxo sobre `primariaContainer`. Quadrado de cantos
/// arredondados nas listas; [circular] nos cabeçalhos de perfil.
class AvatarIniciais extends StatelessWidget {
  const AvatarIniciais({
    super.key,
    required this.nome,
    this.foto,
    this.tamanho = 52,
    this.circular = false,
  });

  final String nome;

  /// Miniatura em base64 (`Musico.foto`).
  final String? foto;
  final double tamanho;
  final bool circular;

  /// Até duas iniciais: primeira e última palavra ("Ana Vieira" → "AV").
  static String iniciaisDe(String nome) {
    final palavras = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (palavras.isEmpty) return '?';
    final primeira = palavras.first.characters.first;
    if (palavras.length == 1) return primeira.toUpperCase();
    return (primeira + palavras.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final imagem = imagemDaFoto(foto);
    final forma = circular
        ? const CircleBorder()
        : RoundedRectangleBorder(
            borderRadius: AppRadius.circular(tamanho * 0.3),
          );

    return Semantics(
      label: 'Foto de $nome',
      image: true,
      excludeSemantics: true,
      child: Container(
        width: tamanho,
        height: tamanho,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: AppColors.primariaContainer,
          shape: forma,
          image: imagem == null
              ? null
              : DecorationImage(image: imagem, fit: BoxFit.cover),
        ),
        alignment: Alignment.center,
        child: imagem != null
            ? null
            : Text(
                iniciaisDe(nome),
                style: TextStyle(
                  color: context.cores.primariaTexto,
                  fontSize: tamanho * 0.36,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
