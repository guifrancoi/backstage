class InteresseMusico {
  final String id;
  final String musicoId;
  final String usuarioId;
  final DateTime dataHora;

  InteresseMusico({
    required this.id,
    required this.musicoId,
    required this.usuarioId,
    required this.dataHora,
  });

  factory InteresseMusico.fromMap(String id, Map<String, dynamic> map) {
    return InteresseMusico(
      id: id,
      musicoId: map['musicoId'] as String? ?? '',
      usuarioId: map['usuarioId'] as String? ?? '',
      dataHora: _dateTimeFromValue(map['dataHora']),
    );
  }

  Map<String, dynamic> toMap() {
    return {'musicoId': musicoId, 'usuarioId': usuarioId, 'dataHora': dataHora};
  }
}

DateTime _dateTimeFromValue(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();

  try {
    return value.toDate() as DateTime;
  } catch (_) {
    return DateTime.now();
  }
}
