import 'mensagem.dart';

class Conversa {
  final String id;
  final List<String> participantes;
  final Map<String, String> nomes;
  final String? interesseId;
  final List<Mensagem> mensagens;
  final DateTime? atualizadoEm;

  /// Quando cada participante (uid) abriu a conversa pela última vez.
  final Map<String, DateTime> lidaEm;

  Conversa({
    required this.id,
    required this.participantes,
    required this.nomes,
    required this.mensagens,
    this.interesseId,
    this.atualizadoEm,
    this.lidaEm = const {},
  });

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
      interesseId: interesseId,
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
      interesseId: map['interesseId'] as String?,
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
      'interesseId': ?interesseId,
      'mensagens': mensagens.map((mensagem) => mensagem.toMap()).toList(),
      'atualizadoEm': ?atualizadoEm,
      if (lidaEm.isNotEmpty) 'lidaEm': lidaEm,
    };
  }
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
