import 'contratacao.dart';
import 'interesse.dart';
import 'oportunidade.dart';

enum TipoNotificacao {
  interesseRecebido,
  interesseAceito,
  interesseRecusado,
  oportunidadeAlterada,
  oportunidadeRemovida,
  contratacaoProposta,
  contratacaoConfirmada,
  contratacaoRecusada,
  contratacaoCancelada,

  /// Plano 17: a outra parte avaliou o show (convite para avaliar também).
  avaliacaoRecebida,
}

/// Para onde a notificação leva ao ser tocada.
enum DestinoNotificacao { interesses, contratacoes, oportunidade }

/// Aviso dentro do app (coleção `notificacoes`, id automático). Toda
/// notificação aponta para o interesse que liga autor e destinatário
/// (`interesseId`): as regras só aceitam notificar a outra parte dele.
/// Título e texto são montados pelos construtores de cada evento.
class Notificacao {
  final String id;
  final String destinatarioId;
  final String autorId;
  final String autorNome;
  final TipoNotificacao tipo;
  final String titulo;
  final String texto;
  final String interesseId;
  final String? oportunidadeId;
  final String? contratacaoId;
  final bool lida;
  final DateTime criadaEm;

  Notificacao({
    required this.destinatarioId,
    required this.autorId,
    required this.autorNome,
    required this.tipo,
    required this.titulo,
    required this.texto,
    required this.interesseId,
    this.id = '',
    this.oportunidadeId,
    this.contratacaoId,
    this.lida = false,
    DateTime? criadaEm,
  }) : criadaEm = criadaEm ?? DateTime.now();

  // ---------------------------------------------------------------------------
  // Eventos de interesse
  // ---------------------------------------------------------------------------

  /// Candidatura ou convite recebido: avisa o destinatário.
  factory Notificacao.interesseRecebido(Interesse interesse) {
    final convite = interesse.tipo == TipoInteresse.convite;
    final titulo = interesse.oportunidadeTitulo;
    return Notificacao(
      destinatarioId: interesse.destinatarioId,
      autorId: interesse.remetenteId,
      autorNome: interesse.remetenteNome,
      tipo: TipoNotificacao.interesseRecebido,
      titulo: convite ? 'Novo convite' : 'Nova candidatura',
      texto: convite
          ? '${interesse.remetenteNome} convidou você para tocar'
                '${titulo == null ? '' : ' em "$titulo"'}.'
          : '${interesse.musicoNome} quer tocar em "${titulo ?? 'sua oportunidade'}".',
      interesseId: interesse.id,
      oportunidadeId: interesse.oportunidadeId,
    );
  }

  /// Aceite ou recusa: avisa quem enviou o interesse.
  factory Notificacao.interesseRespondido(
    Interesse interesse, {
    required bool aceito,
    required String nomeQuemRespondeu,
  }) {
    final convite = interesse.tipo == TipoInteresse.convite;
    final oQue = convite ? 'seu convite' : 'sua candidatura';
    final titulo = interesse.oportunidadeTitulo;
    final para = titulo == null ? '' : ' para "$titulo"';
    return Notificacao(
      destinatarioId: interesse.remetenteId,
      autorId: interesse.destinatarioId,
      autorNome: nomeQuemRespondeu,
      tipo: aceito
          ? TipoNotificacao.interesseAceito
          : TipoNotificacao.interesseRecusado,
      titulo: aceito ? 'Interesse aceito' : 'Interesse recusado',
      texto: aceito
          ? '$nomeQuemRespondeu aceitou $oQue$para. A conversa foi aberta.'
          : '$nomeQuemRespondeu recusou $oQue$para.',
      interesseId: interesse.id,
      oportunidadeId: interesse.oportunidadeId,
    );
  }

  // ---------------------------------------------------------------------------
  // Eventos de oportunidade (do dono para os músicos interessados)
  // ---------------------------------------------------------------------------

  /// O que mudou entre [antes] e [depois] nos campos que afetam o show:
  /// data, horário, cachê e endereço. Vazio = nada relevante.
  static List<String> mudancas(Oportunidade antes, Oportunidade depois) {
    String data(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
    String endereco(Oportunidade o) =>
        '${o.logradouro}, ${o.numero} — ${o.cidade}/${o.estado}';
    String cache(double v) => 'R\$ ${v.toStringAsFixed(2)}';

    return [
      if (data(antes.dataEvento) != data(depois.dataEvento))
        'data ${data(antes.dataEvento)} → ${data(depois.dataEvento)}',
      if (antes.horario != depois.horario)
        'horário ${antes.horario.isEmpty ? '—' : antes.horario} → ${depois.horario}',
      if (antes.cacheOferecido != depois.cacheOferecido)
        'cachê ${cache(antes.cacheOferecido)} → ${cache(depois.cacheOferecido)}',
      if (endereco(antes) != endereco(depois))
        'local ${endereco(antes)} → ${endereco(depois)}',
    ];
  }

  /// `null` quando não mudou nada relevante (não vale avisar).
  static Notificacao? oportunidadeAlterada(
    Interesse interesse, {
    required Oportunidade antes,
    required Oportunidade depois,
    required String nomeDono,
  }) {
    final lista = mudancas(antes, depois);
    if (lista.isEmpty) return null;
    return Notificacao(
      destinatarioId: interesse.musicoId,
      autorId: interesse.donoId,
      autorNome: nomeDono,
      tipo: TipoNotificacao.oportunidadeAlterada,
      titulo: 'Oportunidade alterada',
      texto: '$nomeDono alterou "${depois.titulo}": ${lista.join('; ')}.',
      interesseId: interesse.id,
      oportunidadeId: depois.id,
    );
  }

  factory Notificacao.oportunidadeRemovida(
    Interesse interesse, {
    required String tituloOportunidade,
    required String nomeDono,
  }) {
    return Notificacao(
      destinatarioId: interesse.musicoId,
      autorId: interesse.donoId,
      autorNome: nomeDono,
      tipo: TipoNotificacao.oportunidadeRemovida,
      titulo: 'Oportunidade removida',
      texto: interesse.pendente
          ? '$nomeDono removeu "$tituloOportunidade". Seu interesse pendente '
                'foi encerrado.'
          : '$nomeDono removeu "$tituloOportunidade".',
      interesseId: interesse.id,
    );
  }

  // ---------------------------------------------------------------------------
  // Eventos de contratação (para a outra parte)
  // ---------------------------------------------------------------------------

  /// [tipo] é um dos `contratacao*`; [autorId] é quem agiu (dono ou músico).
  factory Notificacao.contratacao(
    Contratacao contratacao, {
    required TipoNotificacao tipo,
    required String autorId,
  }) {
    final autorEhDono = autorId == contratacao.donoId;
    final autorNome = autorEhDono
        ? contratacao.donoNome
        : contratacao.musicoNome;
    final c = contratacao;
    final data =
        '${c.data.day.toString().padLeft(2, '0')}/'
        '${c.data.month.toString().padLeft(2, '0')}/${c.data.year}';
    final (titulo, texto) = switch (tipo) {
      TipoNotificacao.contratacaoProposta => (
        'Proposta de show',
        '$autorNome propôs "${c.titulo}" em $data, ${c.horaInicio} às '
            '${c.horaFim}, por R\$ ${c.cacheAcordado.toStringAsFixed(2)}.',
      ),
      TipoNotificacao.contratacaoConfirmada => (
        'Show confirmado',
        '$autorNome confirmou "${c.titulo}" em $data.',
      ),
      TipoNotificacao.contratacaoRecusada => (
        'Proposta recusada',
        '$autorNome recusou a proposta "${c.titulo}" de $data.',
      ),
      _ => (
        'Contratação cancelada',
        '$autorNome cancelou "${c.titulo}" de $data'
            '${c.motivoCancelamento == null ? '' : ': ${c.motivoCancelamento}'}.',
      ),
    };
    return Notificacao(
      destinatarioId: autorEhDono ? c.musicoId : c.donoId,
      autorId: autorId,
      autorNome: autorNome,
      tipo: tipo,
      titulo: titulo,
      texto: texto,
      interesseId: c.interesseId,
      oportunidadeId: c.oportunidadeId,
      contratacaoId: c.id,
    );
  }

  /// Plano 17: [autorId] avaliou o show com [nota] estrelas; avisa a outra
  /// parte e a convida a avaliar também (se ainda não avaliou).
  factory Notificacao.avaliacaoRecebida(
    Contratacao contratacao, {
    required String autorId,
    required int nota,
    required bool outraParteJaAvaliou,
  }) {
    final c = contratacao;
    final autorEhDono = autorId == c.donoId;
    final autorNome = autorEhDono ? c.donoNome : c.musicoNome;
    return Notificacao(
      destinatarioId: autorEhDono ? c.musicoId : c.donoId,
      autorId: autorId,
      autorNome: autorNome,
      tipo: TipoNotificacao.avaliacaoRecebida,
      titulo: 'Nova avaliação',
      texto:
          '$autorNome avaliou o show "${c.titulo}" com $nota '
          'estrela${nota == 1 ? '' : 's'}.'
          '${outraParteJaAvaliou ? '' : ' Avalie também.'}',
      interesseId: c.interesseId,
      oportunidadeId: c.oportunidadeId,
      contratacaoId: c.id,
    );
  }

  DestinoNotificacao get destino => switch (tipo) {
    TipoNotificacao.oportunidadeAlterada => DestinoNotificacao.oportunidade,
    TipoNotificacao.contratacaoProposta ||
    TipoNotificacao.contratacaoConfirmada ||
    TipoNotificacao.contratacaoRecusada ||
    TipoNotificacao.contratacaoCancelada ||
    TipoNotificacao.avaliacaoRecebida => DestinoNotificacao.contratacoes,
    _ => DestinoNotificacao.interesses,
  };

  Notificacao copyWith({String? id, bool? lida}) {
    return Notificacao(
      id: id ?? this.id,
      destinatarioId: destinatarioId,
      autorId: autorId,
      autorNome: autorNome,
      tipo: tipo,
      titulo: titulo,
      texto: texto,
      interesseId: interesseId,
      oportunidadeId: oportunidadeId,
      contratacaoId: contratacaoId,
      lida: lida ?? this.lida,
      criadaEm: criadaEm,
    );
  }

  factory Notificacao.fromMap(String id, Map<String, dynamic> map) {
    return Notificacao(
      id: id,
      destinatarioId: map['destinatarioId'] as String? ?? '',
      autorId: map['autorId'] as String? ?? '',
      autorNome: map['autorNome'] as String? ?? '',
      tipo: _tipoFromValue(map['tipo']),
      titulo: map['titulo'] as String? ?? '',
      texto: map['texto'] as String? ?? '',
      interesseId: map['interesseId'] as String? ?? '',
      oportunidadeId: map['oportunidadeId'] as String?,
      contratacaoId: map['contratacaoId'] as String?,
      lida: map['lida'] as bool? ?? false,
      criadaEm: _dateTimeFromValue(map['criadaEm']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'destinatarioId': destinatarioId,
      'autorId': autorId,
      'autorNome': autorNome,
      'tipo': tipo.name,
      'titulo': titulo,
      'texto': texto,
      'interesseId': interesseId,
      'oportunidadeId': ?oportunidadeId,
      'contratacaoId': ?contratacaoId,
      'lida': lida,
      'criadaEm': criadaEm,
    };
  }
}

TipoNotificacao _tipoFromValue(dynamic value) {
  for (final item in TipoNotificacao.values) {
    if (item.name == value) return item;
  }
  return TipoNotificacao.interesseRecebido;
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
