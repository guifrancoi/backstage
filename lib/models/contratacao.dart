/// `proposta`: o dono propôs, aguarda o músico.
/// `contraproposta` (Plano 21): o músico pediu outro cachê
/// (`cacheContraproposto`), aguarda o dono aceitar (volta a `proposta` com o
/// novo valor) ou recusar (`cancelada`). Uma rodada só.
/// `confirmada`: o músico aceitou; o dia fica ocupado (`ocupacoes`).
/// `recusada`: o músico recusou a proposta.
/// `cancelada`: o dono retirou a proposta, ou uma das partes desfez a
/// confirmada. "Realizada" não é gravado: é confirmada com o dia já passado.
enum StatusContratacao { proposta, contraproposta, confirmada, recusada, cancelada }

/// Show combinado entre dono e músico, nascido de um interesse aceito
/// (coleção `contratacoes`, id automático). Só as duas partes leem.
class Contratacao {
  final String id;
  final String interesseId;
  final String musicoId;
  final String musicoNome;
  final String donoId;
  final String donoNome;
  final String? oportunidadeId;
  final String titulo;

  /// Dia do show, `yyyy-MM-dd` — também compõe o id da ocupação.
  final String dia;
  final String horaInicio;
  final String horaFim;
  final double cacheAcordado;
  final String logradouro;
  final String numero;
  final String cidade;
  final String estado;
  final StatusContratacao status;
  final DateTime criadoEm;
  final DateTime? respondidoEm;
  final DateTime? canceladoEm;
  final String? canceladoPor;
  final String? motivoCancelamento;

  /// Plano 21: valor pedido pelo músico na contraproposta.
  final double? cacheContraproposto;

  /// Plano 21: já houve contraproposta (trava a segunda rodada).
  final bool houveContraproposta;

  Contratacao({
    required this.id,
    required this.interesseId,
    required this.musicoId,
    required this.musicoNome,
    required this.donoId,
    required this.donoNome,
    required this.titulo,
    required this.dia,
    required this.horaInicio,
    required this.horaFim,
    required this.cacheAcordado,
    required this.logradouro,
    required this.numero,
    required this.cidade,
    required this.estado,
    required this.criadoEm,
    this.oportunidadeId,
    StatusContratacao? status,
    this.respondidoEm,
    this.canceladoEm,
    this.canceladoPor,
    this.motivoCancelamento,
    this.cacheContraproposto,
    this.houveContraproposta = false,
  }) : status = status ?? StatusContratacao.proposta;

  /// `yyyy-MM-dd` do dia (sem hora), no fuso local.
  static String diaDe(DateTime data) {
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');
    return '${data.year}-$mes-$dia';
  }

  /// Id de `ocupacoes`: um show confirmado por músico por dia.
  static String idOcupacao(String musicoId, String dia) => '${musicoId}_$dia';

  DateTime get data => DateTime.tryParse(dia) ?? DateTime(0);

  bool get ativa => emNegociacao || status == StatusContratacao.confirmada;

  /// Proposta ou contraproposta: ainda sem acordo.
  bool get emNegociacao =>
      status == StatusContratacao.proposta ||
      status == StatusContratacao.contraproposta;

  /// Plano 21: o músico ainda pode pedir outro cachê (uma vez só).
  bool get podeContrapropor =>
      status == StatusContratacao.proposta && !houveContraproposta;

  bool get realizada {
    if (status != StatusContratacao.confirmada) return false;
    final hoje = DateTime.now();
    return data.isBefore(DateTime(hoje.year, hoje.month, hoje.day));
  }

  String get rotuloStatus {
    if (realizada) return 'Realizada';
    return switch (status) {
      StatusContratacao.proposta => 'Proposta',
      StatusContratacao.contraproposta => 'Contraproposta',
      StatusContratacao.confirmada => 'Confirmada',
      StatusContratacao.recusada => 'Recusada',
      StatusContratacao.cancelada => 'Cancelada',
    };
  }

  /// Última movimentação (criação, resposta ou cancelamento) — critério de
  /// "mais recentes primeiro".
  DateTime get atualizadoEm => [
    criadoEm,
    ?respondidoEm,
    ?canceladoEm,
  ].reduce((a, b) => a.isAfter(b) ? a : b);

  /// Prazo para avaliar o show (Plano 17), contado a partir do dia seguinte.
  static const diasParaAvaliar = 30;

  /// Show confirmado cuja janela de avaliação está aberta em [agora]: do
  /// dia seguinte ao show até [diasParaAvaliar] dias depois. As regras
  /// conferem o mesmo intervalo (meia-noite de Brasília).
  bool podeAvaliarEm(DateTime agora) {
    if (status != StatusContratacao.confirmada) return false;
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final abre = DateTime(data.year, data.month, data.day + 1);
    final fecha = DateTime(data.year, data.month, data.day + 1 + diasParaAvaliar);
    return !hoje.isBefore(abre) && hoje.isBefore(fecha);
  }

  /// Não pede mais ação: recusada, cancelada ou realizada.
  bool get encerrada => !ativa || realizada;

  String get endereco => '$logradouro, $numero — $cidade/$estado';

  Contratacao copyWith({
    String? id,
    StatusContratacao? status,
    DateTime? respondidoEm,
    DateTime? canceladoEm,
    String? canceladoPor,
    String? motivoCancelamento,
    double? cacheAcordado,
    double? cacheContraproposto,
    bool? houveContraproposta,
  }) {
    return Contratacao(
      id: id ?? this.id,
      interesseId: interesseId,
      musicoId: musicoId,
      musicoNome: musicoNome,
      donoId: donoId,
      donoNome: donoNome,
      oportunidadeId: oportunidadeId,
      titulo: titulo,
      dia: dia,
      horaInicio: horaInicio,
      horaFim: horaFim,
      cacheAcordado: cacheAcordado ?? this.cacheAcordado,
      logradouro: logradouro,
      numero: numero,
      cidade: cidade,
      estado: estado,
      criadoEm: criadoEm,
      status: status ?? this.status,
      respondidoEm: respondidoEm ?? this.respondidoEm,
      canceladoEm: canceladoEm ?? this.canceladoEm,
      canceladoPor: canceladoPor ?? this.canceladoPor,
      motivoCancelamento: motivoCancelamento ?? this.motivoCancelamento,
      cacheContraproposto: cacheContraproposto ?? this.cacheContraproposto,
      houveContraproposta: houveContraproposta ?? this.houveContraproposta,
    );
  }

  factory Contratacao.fromMap(String id, Map<String, dynamic> map) {
    return Contratacao(
      id: id,
      interesseId: map['interesseId'] as String? ?? '',
      musicoId: map['musicoId'] as String? ?? '',
      musicoNome: map['musicoNome'] as String? ?? '',
      donoId: map['donoId'] as String? ?? '',
      donoNome: map['donoNome'] as String? ?? '',
      oportunidadeId: map['oportunidadeId'] as String?,
      titulo: map['titulo'] as String? ?? '',
      dia: map['dia'] as String? ?? '',
      horaInicio: map['horaInicio'] as String? ?? '',
      horaFim: map['horaFim'] as String? ?? '',
      cacheAcordado: (map['cacheAcordado'] as num?)?.toDouble() ?? 0,
      logradouro: map['logradouro'] as String? ?? '',
      numero: map['numero'] as String? ?? '',
      cidade: map['cidade'] as String? ?? '',
      estado: map['estado'] as String? ?? '',
      status: _statusFromValue(map['status']),
      criadoEm: _dateTimeFromValue(map['criadoEm']) ?? DateTime.now(),
      respondidoEm: _dateTimeFromValue(map['respondidoEm']),
      canceladoEm: _dateTimeFromValue(map['canceladoEm']),
      canceladoPor: map['canceladoPor'] as String?,
      motivoCancelamento: map['motivoCancelamento'] as String?,
      cacheContraproposto: (map['cacheContraproposto'] as num?)?.toDouble(),
      houveContraproposta: map['houveContraproposta'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'interesseId': interesseId,
      'musicoId': musicoId,
      'musicoNome': musicoNome,
      'donoId': donoId,
      'donoNome': donoNome,
      'oportunidadeId': ?oportunidadeId,
      'titulo': titulo,
      'dia': dia,
      'horaInicio': horaInicio,
      'horaFim': horaFim,
      'cacheAcordado': cacheAcordado,
      'logradouro': logradouro,
      'numero': numero,
      'cidade': cidade,
      'estado': estado,
      'status': status.name,
      'criadoEm': criadoEm,
      'respondidoEm': ?respondidoEm,
      'canceladoEm': ?canceladoEm,
      'canceladoPor': ?canceladoPor,
      'motivoCancelamento': ?motivoCancelamento,
      'cacheContraproposto': ?cacheContraproposto,
      'houveContraproposta': houveContraproposta,
    };
  }
}

StatusContratacao _statusFromValue(dynamic value) {
  for (final item in StatusContratacao.values) {
    if (item.name == value) return item;
  }
  return StatusContratacao.proposta;
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
