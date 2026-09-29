class Oportunidade {
  final String id;
  final String titulo;
  final String descricao;
  final String cidade;
  final String generoMusical;
  final DateTime dataEvento;
  final double cacheOferecido;
  final String contratante;
  final String donoId;
  final String logradouro;
  final String numero;
  final String estado;
  final String? cep;

  /// Horário do show, `HH:mm`. Opcional só em documentos antigos (antes da
  /// 9B); o formulário exige os dois.
  final String? horaInicio;
  final String? horaFim;

  /// Criada pela conta admin: não aparece para os outros usuários.
  final bool oculto;

  Oportunidade({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.cidade,
    required this.generoMusical,
    required this.dataEvento,
    required this.cacheOferecido,
    required this.contratante,
    required this.donoId,
    required this.logradouro,
    required this.numero,
    required this.estado,
    this.cep,
    this.horaInicio,
    this.horaFim,
    this.oculto = false,
  });

  /// Oportunidades de catálogo/demonstração não têm dono e não recebem candidatura.
  bool get temDono => donoId.isNotEmpty;

  /// "20:00 às 23:00", ou vazio em oportunidade antiga sem horário.
  String get horario =>
      horaInicio == null || horaFim == null ? '' : '$horaInicio às $horaFim';

  Oportunidade copyWith({
    String? id,
    String? titulo,
    String? descricao,
    String? cidade,
    String? generoMusical,
    DateTime? dataEvento,
    double? cacheOferecido,
    String? contratante,
    String? donoId,
    String? logradouro,
    String? numero,
    String? estado,
    String? cep,
    String? horaInicio,
    String? horaFim,
    bool? oculto,
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
      donoId: donoId ?? this.donoId,
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      estado: estado ?? this.estado,
      cep: clearCep ? null : (cep ?? this.cep),
      horaInicio: horaInicio ?? this.horaInicio,
      horaFim: horaFim ?? this.horaFim,
      oculto: oculto ?? this.oculto,
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
      // Vazio nas oportunidades de catálogo restauradas do backup (sem dono).
      donoId: map['donoId'] as String? ?? '',
      logradouro: map['logradouro'] as String? ?? '',
      numero: map['numero'] as String? ?? '',
      estado: map['estado'] as String? ?? '',
      cep: map['cep'] as String?,
      horaInicio: map['horaInicio'] as String?,
      horaFim: map['horaFim'] as String?,
      oculto: map['oculto'] as bool? ?? false,
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
      'donoId': donoId,
      'logradouro': logradouro,
      'numero': numero,
      'estado': estado,
      'cep': ?cep,
      'horaInicio': ?horaInicio,
      'horaFim': ?horaFim,
      'oculto': oculto,
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
