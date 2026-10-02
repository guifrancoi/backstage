/// O que foi denunciado (Plano 22), persistido como `.name`.
enum TipoAlvoDenuncia {
  perfil('Perfil'),
  oportunidade('Oportunidade'),
  mensagem('Mensagem'),
  avaliacao('Avaliação');

  const TipoAlvoDenuncia(this.rotulo);
  final String rotulo;
}

/// Motivo da denúncia (lista fechada, igual à das regras).
enum MotivoDenuncia {
  spam('Spam ou propaganda'),
  ofensivo('Conteúdo ofensivo'),
  golpe('Golpe ou fraude'),
  perfilFalso('Perfil falso'),
  outro('Outro');

  const MotivoDenuncia(this.rotulo);
  final String rotulo;
}

/// Denúncia de um usuário sobre um perfil, oportunidade, mensagem ou
/// avaliação (Plano 22). `denuncias/{id}` (id automático): qualquer
/// autenticado cria; só o admin lê e marca como analisada.
class Denuncia {
  Denuncia({
    this.id = '',
    required this.autorId,
    required this.autorNome,
    required this.tipoAlvo,
    required this.alvoId,
    required this.alvoUid,
    required this.descricaoAlvo,
    required this.motivo,
    this.texto = '',
    this.analisada = false,
    required this.criadaEm,
    this.analisadaEm,
  });

  static const tamanhoMaximoTexto = 500;
  static const tamanhoMaximoDescricao = 300;

  final String id;
  final String autorId;
  final String autorNome;
  final TipoAlvoDenuncia tipoAlvo;

  /// Id do item denunciado (uid do perfil, id da oportunidade, da mensagem
  /// ou da avaliação).
  final String alvoId;

  /// Pessoa responsável pelo item (não dá para denunciar a si mesmo).
  final String alvoUid;

  /// Retrato do item na hora da denúncia (nome, título ou texto), para o
  /// admin entender sem ter acesso ao conteúdo de terceiros.
  final String descricaoAlvo;
  final MotivoDenuncia motivo;
  final String texto;
  final bool analisada;
  final DateTime criadaEm;
  final DateTime? analisadaEm;

  factory Denuncia.fromMap(String id, Map<String, dynamic> map) {
    return Denuncia(
      id: id,
      autorId: map['autorId'] as String? ?? '',
      autorNome: map['autorNome'] as String? ?? '',
      tipoAlvo: TipoAlvoDenuncia.values.firstWhere(
        (t) => t.name == map['tipoAlvo'],
        orElse: () => TipoAlvoDenuncia.perfil,
      ),
      alvoId: map['alvoId'] as String? ?? '',
      alvoUid: map['alvoUid'] as String? ?? '',
      descricaoAlvo: map['descricaoAlvo'] as String? ?? '',
      motivo: MotivoDenuncia.values.firstWhere(
        (m) => m.name == map['motivo'],
        orElse: () => MotivoDenuncia.outro,
      ),
      texto: map['texto'] as String? ?? '',
      analisada: map['status'] == 'analisada',
      criadaEm: _dateTimeFromValue(map['criadaEm']) ?? DateTime(0),
      analisadaEm: _dateTimeFromValue(map['analisadaEm']),
    );
  }

  /// Só para criar (as regras fecham as chaves; `analisadaEm` entra no
  /// update do admin).
  Map<String, dynamic> toMap() {
    return {
      'autorId': autorId,
      'autorNome': autorNome,
      'tipoAlvo': tipoAlvo.name,
      'alvoId': alvoId,
      'alvoUid': alvoUid,
      'descricaoAlvo': descricaoAlvo.length > tamanhoMaximoDescricao
          ? descricaoAlvo.substring(0, tamanhoMaximoDescricao)
          : descricaoAlvo,
      'motivo': motivo.name,
      'texto': texto,
      'status': analisada ? 'analisada' : 'pendente',
      'criadaEm': criadaEm,
    };
  }
}

/// Usuário que o logado bloqueou (`usuarios/{uid}/bloqueados/{uid}`).
class UsuarioBloqueado {
  const UsuarioBloqueado({
    required this.uid,
    required this.nome,
    required this.criadoEm,
  });

  final String uid;
  final String nome;
  final DateTime criadoEm;

  factory UsuarioBloqueado.fromMap(String uid, Map<String, dynamic> map) {
    return UsuarioBloqueado(
      uid: uid,
      nome: map['nome'] as String? ?? '',
      criadoEm: _dateTimeFromValue(map['criadoEm']) ?? DateTime(0),
    );
  }

  Map<String, dynamic> toMap() => {'nome': nome, 'criadoEm': criadoEm};
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
