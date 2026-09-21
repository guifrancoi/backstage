import 'mensagem.dart';

class Conversa {
  final String id;
  final String nomeContato;
  final List<Mensagem> mensagens;

  Conversa({
    required this.id,
    required this.nomeContato,
    required this.mensagens,
  });

  String get ultimaMensagem =>
      mensagens.isNotEmpty ? mensagens.last.texto : 'Sem mensagens';

  factory Conversa.fromMap(String id, Map<String, dynamic> map) {
    final mensagensMap = map['mensagens'] as List? ?? [];

    return Conversa(
      id: id,
      nomeContato: map['nomeContato'] as String? ?? '',
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
      'nomeContato': nomeContato,
      'mensagens': mensagens.map((mensagem) => mensagem.toMap()).toList(),
    };
  }
}
