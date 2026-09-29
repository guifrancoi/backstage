import 'package:backstage/models/conversa.dart';
import 'package:backstage/models/mensagem.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final data = DateTime(2026, 3, 21, 10, 30);

  Mensagem mensagem(String id, String texto) =>
      Mensagem(id: id, remetenteId: 'u1', texto: texto, dataHora: data);

  Conversa conversa({List<Mensagem> mensagens = const []}) => Conversa(
    id: 'c1',
    participantes: ['m1', 'e1'],
    nomes: {'m1': 'The VooDooS', 'e1': 'Bar Central'},
    interesseId: 'm1_op_o1',
    mensagens: mensagens,
    atualizadoEm: data,
  );

  group('Mensagem', () {
    test('toMap inclui o id e fromMap preserva os campos', () {
      final map = mensagem('1', 'Olá').toMap();
      final copia = Mensagem.fromMap('1', map);

      expect(map['id'], '1');
      expect(map.containsKey('enviadaPorMim'), isFalse);
      expect(copia.texto, 'Olá');
      expect(copia.remetenteId, 'u1');
      expect(copia.dataHora, data);
    });

    test('fromMap aplica padrões para campos ausentes', () {
      final copia = Mensagem.fromMap('1', {'dataHora': data});

      expect(copia.texto, '');
      expect(copia.remetenteId, '');
    });
  });

  group('Conversa', () {
    test('toMap e fromMap preservam participantes, nomes e mensagens', () {
      final original = conversa(
        mensagens: [mensagem('1', 'Olá'), mensagem('2', 'Tudo bem?')],
      );

      final copia = Conversa.fromMap('c1', original.toMap());

      expect(copia.participantes, ['m1', 'e1']);
      expect(copia.nomes['e1'], 'Bar Central');
      expect(copia.interesseId, 'm1_op_o1');
      expect(copia.atualizadoEm, data);
      expect(copia.mensagens.map((m) => m.id), ['1', '2']);
      expect(copia.mensagens.map((m) => m.texto), ['Olá', 'Tudo bem?']);
    });

    test('nomeContato mostra o outro participante', () {
      final c = conversa();

      expect(c.nomeContato('m1'), 'Bar Central');
      expect(c.nomeContato('e1'), 'The VooDooS');
    });

    test('fromMap lê mensagens vindas do Firestore (Timestamp e Map genérico)', () {
      final copia = Conversa.fromMap('c1', {
        'participantes': ['m1', 'e1'],
        'nomes': <Object?, Object?>{'m1': 'A', 'e1': 'B'},
        'mensagens': [
          <Object?, Object?>{
            'id': '1',
            'texto': 'Oi',
            'dataHora': Timestamp.fromDate(data),
          },
          'item inválido é ignorado',
        ],
      });

      expect(copia.mensagens, hasLength(1));
      expect(copia.mensagens.single.dataHora, data);
      expect(copia.nomes, {'m1': 'A', 'e1': 'B'});
    });

    test('ultimaMensagem retorna o texto da última ou um aviso', () {
      final comMensagens = conversa(
        mensagens: [mensagem('1', 'Primeira'), mensagem('2', 'Última')],
      );

      expect(comMensagens.ultimaMensagem, 'Última');
      expect(conversa().ultimaMensagem, 'Sem mensagens');
    });

    test('copyWith troca mensagens sem mexer no original', () {
      final original = conversa();
      final nova = original.copyWith(mensagens: [mensagem('1', 'Oi')]);

      expect(nova.mensagens, hasLength(1));
      expect(original.mensagens, isEmpty);
      expect(nova.participantes, original.participantes);
    });
  });
}
