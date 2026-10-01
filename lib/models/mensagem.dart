class Mensagem {
  final String id;
  final String remetenteId;
  final String texto;
  final DateTime dataHora;

  /// Aviso do app dentro da conversa (ex.: "Convite para X aceito"),
  /// mostrado centralizado e não como fala de um dos participantes.
  final bool sistema;

  Mensagem({
    required this.id,
    required this.remetenteId,
    required this.texto,
    required this.dataHora,
    this.sistema = false,
  });

  factory Mensagem.fromMap(String id, Map<String, dynamic> map) {
    return Mensagem(
      id: id,
      remetenteId: map['remetenteId'] as String? ?? '',
      texto: map['texto'] as String? ?? '',
      dataHora: _dateTimeFromValue(map['dataHora']),
      sistema: map['sistema'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'remetenteId': remetenteId,
      'texto': texto,
      'dataHora': dataHora,
      if (sistema) 'sistema': true,
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
