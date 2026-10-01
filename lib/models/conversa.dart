import 'interesse.dart';
import 'mensagem.dart';

/// Uma conversa por **par de usuários** (id fixo `Conversa.idPar`): todo
/// interesse aceito entre os dois reaproveita a mesma conversa e entra nela
/// como mensagem de sistema.
class Conversa {
  final String id;
  final List<String> participantes;
  final Map<String, String> nomes;
  /// Interesses aceitos entre os dois (contexto do "Propor show").
  final List<String> interesseIds;
  final List<Mensagem> mensagens;
  final DateTime? atualizadoEm;

  /// Quando cada participante (uid) abriu a conversa pela última vez.
  final Map<String, DateTime> lidaEm;

  Conversa({
    required this.id,
    required this.participantes,
    required this.nomes,
    required this.mensagens,
    this.interesseIds = const [],
    this.atualizadoEm,
    this.lidaEm = const {},
  });

  /// Id da conversa entre [a] e [b]: os dois uids em ordem.
  static String idPar(String a, String b) {
    final par = participantesDoPar(a, b);
    return '${par[0]}_${par[1]}';
  }

  /// Participantes em ordem (as regras exigem exatamente esta lista).
  static List<String> participantesDoPar(String a, String b) =>
      a.compareTo(b) <= 0 ? [a, b] : [b, a];

  /// Texto da mensagem de sistema registrada quando [interesse] é aceito.
  static String textoAceite(Interesse interesse) {
    final titulo = interesse.oportunidadeTitulo;
    if (interesse.tipo == TipoInteresse.candidatura) {
      return 'Candidatura para "${titulo ?? 'a oportunidade'}" aceita.';
    }
    return titulo == null
        ? 'Convite aceito.'
        : 'Convite para "$titulo" aceito.';
  }

  /// Nome do outro participante, do ponto de vista de [meuUid].
  String nomeContato(String? meuUid) {
    for (final uid in participantes) {
      if (uid != meuUid) return nomes[uid] ?? 'Contato';
    }
    return nomes.values.isNotEmpty ? nomes.values.first : 'Contato';
  }

  /// Mensagens do outro participante depois da última leitura de [meuUid].
  /// Sem leitura registrada, todas as dele contam.
  int naoLidas(String? meuUid) {
    if (meuUid == null) return 0;
    final lida = lidaEm[meuUid];
    return mensagens
        .where(
          (m) =>
              m.remetenteId != meuUid &&
              (lida == null || m.dataHora.isAfter(lida)),
        )
        .length;
  }

  String get ultimaMensagem =>
      mensagens.isNotEmpty ? mensagens.last.texto : 'Sem mensagens';

  Conversa copyWith({List<Mensagem>? mensagens, DateTime? atualizadoEm}) {
    return Conversa(
      id: id,
      participantes: participantes,
      nomes: nomes,
      interesseIds: interesseIds,
      mensagens: mensagens ?? this.mensagens,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      lidaEm: lidaEm,
    );
  }

  factory Conversa.fromMap(String id, Map<String, dynamic> map) {
    final mensagensMap = map['mensagens'] as List? ?? [];
    final nomesMap = map['nomes'] as Map? ?? {};
    final lidaEmMap = map['lidaEm'] as Map? ?? {};

    return Conversa(
      id: id,
      participantes: List<String>.from(map['participantes'] as List? ?? []),
      nomes: nomesMap.map(
        (chave, valor) => MapEntry(chave.toString(), valor.toString()),
      ),
      interesseIds: _interesseIds(map),
      atualizadoEm: _dateTimeFromValue(map['atualizadoEm']),
      lidaEm: {
        for (final entrada in lidaEmMap.entries)
          entrada.key.toString(): ?_dateTimeFromValue(entrada.value),
      },
      mensagens: mensagensMap
          .whereType<Map>()
          .map(
            (mensagem) => Mensagem.fromMap(
              mensagem['id'] as String? ?? '',
              Map<String, dynamic>.from(mensagem),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participantes': participantes,
      'nomes': nomes,
      'interesseIds': interesseIds,
      'mensagens': mensagens.map((mensagem) => mensagem.toMap()).toList(),
      'atualizadoEm': ?atualizadoEm,
      if (lidaEm.isNotEmpty) 'lidaEm': lidaEm,
    };
  }
}

/// `interesseIds` (lista); documentos antigos só tinham `interesseId`.
List<String> _interesseIds(Map<String, dynamic> map) {
  final lista = map['interesseIds'];
  if (lista is List) return List<String>.from(lista);
  final unico = map['interesseId'];
  return unico is String ? [unico] : const [];
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
