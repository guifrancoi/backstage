class Oportunidade {
  final String id;
  final String titulo;
  final String descricao;
  final String cidade;
  final String generoMusical;
  final DateTime dataEvento;
  final double cacheOferecido;
  final String contratante;
  final bool interesseEnviado;
  final String logradouro;
  final String numero;
  final String estado;
  final String? cep;

  Oportunidade({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.cidade,
    required this.generoMusical,
    required this.dataEvento,
    required this.cacheOferecido,
    required this.contratante,
    required this.logradouro,
    required this.numero,
    required this.estado,
    bool? interesseEnviado,
    this.cep,
  }) : interesseEnviado = interesseEnviado ?? false;

  Oportunidade copyWith({
    String? id,
    String? titulo,
    String? descricao,
    String? cidade,
    String? generoMusical,
    DateTime? dataEvento,
    double? cacheOferecido,
    String? contratante,
    bool? interesseEnviado,
    String? logradouro,
    String? numero,
    String? estado,
    String? cep,
    bool clearCep = false,
  }) {
    return Oportunidade(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      cidade: cidade ?? this.cidade,
      generoMusical: generoMusical ?? this.generoMusical,
      dataEvento: dataEvento ?? this.dataEvento,
      cacheOferecido: cacheOferecido ?? this.cacheOferecido,
      contratante: contratante ?? this.contratante,
      interesseEnviado: interesseEnviado ?? this.interesseEnviado,
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      estado: estado ?? this.estado,
      cep: clearCep ? null : (cep ?? this.cep),
    );
  }

  factory Oportunidade.fromMap(String id, Map<String, dynamic> map) {
    return Oportunidade(
      id: id,
      titulo: map['titulo'] as String? ?? '',
      descricao: map['descricao'] as String? ?? '',
      cidade: map['cidade'] as String? ?? '',
      generoMusical: map['generoMusical'] as String? ?? '',
      dataEvento: _dateTimeFromValue(map['dataEvento']),
      cacheOferecido: (map['cacheOferecido'] as num?)?.toDouble() ?? 0,
      contratante: map['contratante'] as String? ?? '',
      interesseEnviado: map['interesseEnviado'] as bool? ?? false,
      logradouro: map['logradouro'] as String? ?? '',
      numero: map['numero'] as String? ?? '',
      estado: map['estado'] as String? ?? '',
      cep: map['cep'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descricao': descricao,
      'cidade': cidade,
      'generoMusical': generoMusical,
      'dataEvento': dataEvento,
      'cacheOferecido': cacheOferecido,
      'contratante': contratante,
      'interesseEnviado': interesseEnviado,
      'logradouro': logradouro,
      'numero': numero,
      'estado': estado,
      if (cep != null) 'cep': cep,
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
