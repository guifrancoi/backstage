/// Avaliação de um show realizado (Plano 17), uma por parte da contratação:
/// o músico avalia o dono e o dono avalia o músico. `avaliacoes/{id}`, id =
/// `{contratacaoId}_{autorId}` (as regras exigem e não deixam editar nem
/// apagar). Leitura aberta a autenticados: a reputação é pública.
class Avaliacao {
  Avaliacao({
    required this.contratacaoId,
    required this.autorId,
    required this.autorNome,
    required this.avaliadoId,
    required this.nota,
    required this.comentario,
    required this.criadaEm,
  });

  static const tamanhoMaximoComentario = 300;

  final String contratacaoId;
  final String autorId;
  final String autorNome;
  final String avaliadoId;

  /// 1 a 5 estrelas.
  final int nota;

  /// Opcional (`''`), até [tamanhoMaximoComentario] caracteres.
  final String comentario;
  final DateTime criadaEm;

  String get id => idDe(contratacaoId, autorId);

  static String idDe(String contratacaoId, String autorId) =>
      '${contratacaoId}_$autorId';

  factory Avaliacao.fromMap(String id, Map<String, dynamic> map) {
    return Avaliacao(
      contratacaoId: map['contratacaoId'] as String? ?? '',
      autorId: map['autorId'] as String? ?? '',
      autorNome: map['autorNome'] as String? ?? '',
      avaliadoId: map['avaliadoId'] as String? ?? '',
      nota: (map['nota'] as num?)?.toInt() ?? 0,
      comentario: map['comentario'] as String? ?? '',
      criadaEm: _dateTimeFromValue(map['criadaEm']) ?? DateTime(0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contratacaoId': contratacaoId,
      'autorId': autorId,
      'autorNome': autorNome,
      'avaliadoId': avaliadoId,
      'nota': nota,
      'comentario': comentario,
      'criadaEm': criadaEm,
    };
  }
}

/// Média e quantidade das avaliações recebidas por alguém.
class ResumoAvaliacoes {
  const ResumoAvaliacoes(this.media, this.quantidade);

  final double media;
  final int quantidade;

  static const vazio = ResumoAvaliacoes(0, 0);

  factory ResumoAvaliacoes.de(Iterable<Avaliacao> avaliacoes) {
    final notas = avaliacoes.map((a) => a.nota).toList();
    if (notas.isEmpty) return vazio;
    return ResumoAvaliacoes(
      notas.reduce((a, b) => a + b) / notas.length,
      notas.length,
    );
  }

  bool get temAvaliacao => quantidade > 0;

  /// "★ 4,6 (8)" — vírgula decimal, como no resto do app em PT-BR.
  String get rotuloCurto =>
      '★ ${media.toStringAsFixed(1).replaceAll('.', ',')} ($quantidade)';

  /// "★ 4,6 · 8 avaliações".
  String get rotulo =>
      '★ ${media.toStringAsFixed(1).replaceAll('.', ',')} · '
      '$quantidade avaliaç${quantidade == 1 ? 'ão' : 'ões'}';
}

DateTime? _dateTimeFromValue(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  try {
    return value.toDate() as DateTime;
  } catch (_) {
    return null;
  }
}
