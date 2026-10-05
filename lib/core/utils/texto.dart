// Comparação de texto digitado pelo usuário (Plano 8): sem diferença de
// maiúsculas, acentos ou espaços nas pontas.

/// `" São Paulo "` → `"sao paulo"`.
String normalizarTexto(String texto) {
  const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const semAcento = 'aaaaaeeeeiiiiooooouuuuc';
  final buffer = StringBuffer();
  for (final char in texto.trim().toLowerCase().split('')) {
    final i = comAcento.indexOf(char);
    buffer.write(i < 0 ? char : semAcento[i]);
  }
  return buffer.toString();
}

/// Algum dos [campos] contém o [termo] (normalizados). Termo vazio casa
/// com tudo.
bool contemTermo(String termo, Iterable<String> campos) {
  final busca = normalizarTexto(termo);
  if (busca.isEmpty) return true;
  return campos.any((campo) => normalizarTexto(campo).contains(busca));
}
