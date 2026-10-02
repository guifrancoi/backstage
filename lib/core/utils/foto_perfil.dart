import 'dart:convert';

import 'package:flutter/widgets.dart';

/// Miniatura de perfil em base64 (Plano 14) → imagem para exibir.
///
/// Guarda as imagens já decodificadas: um `MemoryImage` novo a cada build
/// seria decodificado de novo (e piscaria), porque o cache de imagens do
/// Flutter compara os bytes por identidade.
ImageProvider? imagemDaFoto(String? base64) {
  if (base64 == null || base64.isEmpty) return null;
  final pronta = _cache[base64];
  if (pronta != null) return pronta;
  try {
    final imagem = MemoryImage(base64Decode(base64));
    if (_cache.length >= _limiteCache) _cache.remove(_cache.keys.first);
    return _cache[base64] = imagem;
  } on FormatException {
    return null;
  }
}

const _limiteCache = 100;
final _cache = <String, MemoryImage>{};
