class Interesse {
  final String id;
  final String oportunidadeId;
  final String usuarioId;
  final DateTime dataHora;

  Interesse({
    required this.id,
    required this.oportunidadeId,
    required this.usuarioId,
    required this.dataHora,
  });

  factory Interesse.fromMap(String id, Map<String, dynamic> map) {
    return Interesse(
      id: id,
      oportunidadeId: map['oportunidadeId'] as String? ?? '',
      usuarioId: map['usuarioId'] as String? ?? '',
      dataHora: _dateTimeFromValue(map['dataHora']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'oportunidadeId': oportunidadeId,
      'usuarioId': usuarioId,
      'dataHora': dataHora,
    };
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
