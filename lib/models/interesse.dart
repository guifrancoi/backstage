/// `candidatura`: músico → oportunidade (destinatário = dono da oportunidade).
/// `convite`: dono → músico (destinatário = o músico).
enum TipoInteresse { candidatura, convite }

enum StatusInteresse { pendente, aceito, recusado }

class Interesse {
  final String id;
  final TipoInteresse tipo;
  final String remetenteId;
  final String remetenteNome;
  final String destinatarioId;
  final String musicoId;
  final String musicoNome;
  final String? oportunidadeId;
  final String? oportunidadeTitulo;
  final StatusInteresse status;
  final DateTime criadoEm;
  final DateTime? respondidoEm;
  final String? conversaId;

  Interesse({
    required this.id,
    required this.tipo,
    required this.remetenteId,
    required this.remetenteNome,
    required this.destinatarioId,
    required this.musicoId,
    required this.musicoNome,
    required this.criadoEm,
    this.oportunidadeId,
    this.oportunidadeTitulo,
    StatusInteresse? status,
    this.respondidoEm,
    this.conversaId,
  }) : status = status ?? StatusInteresse.pendente;

  static String idCandidatura(String remetenteId, String oportunidadeId) =>
      '${remetenteId}_op_$oportunidadeId';

  static String idConvite(
    String remetenteId,
    String musicoId, {
    String? oportunidadeId,
  }) {
    final base = '${remetenteId}_mu_$musicoId';
    return oportunidadeId == null ? base : '${base}_$oportunidadeId';
  }

  bool get pendente => status == StatusInteresse.pendente;

  String get rotuloStatus => switch (status) {
    StatusInteresse.pendente =>
      tipo == TipoInteresse.convite ? 'Convite enviado' : 'Candidatura enviada',
    StatusInteresse.aceito => 'Aceito',
    StatusInteresse.recusado => 'Recusado',
  };

  Interesse copyWith({
    StatusInteresse? status,
    DateTime? respondidoEm,
    String? conversaId,
  }) {
    return Interesse(
      id: id,
      tipo: tipo,
      remetenteId: remetenteId,
      remetenteNome: remetenteNome,
      destinatarioId: destinatarioId,
      musicoId: musicoId,
      musicoNome: musicoNome,
      oportunidadeId: oportunidadeId,
      oportunidadeTitulo: oportunidadeTitulo,
      status: status ?? this.status,
      criadoEm: criadoEm,
      respondidoEm: respondidoEm ?? this.respondidoEm,
      conversaId: conversaId ?? this.conversaId,
    );
  }

  factory Interesse.fromMap(String id, Map<String, dynamic> map) {
    return Interesse(
      id: id,
      tipo: _enumFromValue(TipoInteresse.values, map['tipo']) ??
          TipoInteresse.candidatura,
      remetenteId: map['remetenteId'] as String? ?? '',
      remetenteNome: map['remetenteNome'] as String? ?? '',
      destinatarioId: map['destinatarioId'] as String? ?? '',
      musicoId: map['musicoId'] as String? ?? '',
      musicoNome: map['musicoNome'] as String? ?? '',
      oportunidadeId: map['oportunidadeId'] as String?,
      oportunidadeTitulo: map['oportunidadeTitulo'] as String?,
      status: _enumFromValue(StatusInteresse.values, map['status']),
      criadoEm: _dateTimeFromValue(map['criadoEm']) ?? DateTime.now(),
      respondidoEm: _dateTimeFromValue(map['respondidoEm']),
      conversaId: map['conversaId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo.name,
      'remetenteId': remetenteId,
      'remetenteNome': remetenteNome,
      'destinatarioId': destinatarioId,
      'musicoId': musicoId,
      'musicoNome': musicoNome,
      'oportunidadeId': ?oportunidadeId,
      'oportunidadeTitulo': ?oportunidadeTitulo,
      'status': status.name,
      'criadoEm': criadoEm,
      'respondidoEm': ?respondidoEm,
      'conversaId': ?conversaId,
    };
  }
}

T? _enumFromValue<T extends Enum>(List<T> values, dynamic value) {
  if (value is! String) return null;
  for (final item in values) {
    if (item.name == value) return item;
  }
  return null;
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
