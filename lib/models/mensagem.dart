class Mensagem {
  final String id;
  final String remetenteId;
  final String texto;
  final DateTime dataHora;
  final bool enviadaPorMim;

  Mensagem({
    required this.id,
    required this.remetenteId,
    required this.texto,
    required this.dataHora,
    required this.enviadaPorMim,
  });

  factory Mensagem.fromMap(String id, Map<String, dynamic> map) {
    return Mensagem(
      id: id,
      remetenteId: map['remetenteId'] as String? ?? '',
      texto: map['texto'] as String? ?? '',
      dataHora: _dateTimeFromValue(map['dataHora']),
      enviadaPorMim: map['enviadaPorMim'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'remetenteId': remetenteId,
      'texto': texto,
      'dataHora': dataHora,
      'enviadaPorMim': enviadaPorMim,
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
