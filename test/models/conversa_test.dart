import 'package:backstage/models/conversa.dart';
import 'package:backstage/models/mensagem.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final data = DateTime(2026, 3, 21, 10, 30);

  Mensagem mensagem(String id, String texto) => Mensagem(
    id: id,
    remetenteId: 'u1',
    texto: texto,
    dataHora: data,
    enviadaPorMim: true,
  );

  group('Mensagem', () {
    test('toMap inclui o id e fromMap preserva os campos', () {
      final map = mensagem('1', 'Olá').toMap();
      final copia = Mensagem.fromMap('1', map);

      expect(map['id'], '1');
      expect(copia.texto, 'Olá');
      expect(copia.remetenteId, 'u1');
      expect(copia.dataHora, data);
      expect(copia.enviadaPorMim, isTrue);
    });

    test('fromMap aplica padrões para campos ausentes', () {
      final copia = Mensagem.fromMap('1', {'dataHora': data});

      expect(copia.texto, '');
      expect(copia.enviadaPorMim, isFalse);
    });
  });

  group('Conversa', () {
    test('toMap e fromMap preservam as mensagens embutidas', () {
      final original = Conversa(
        id: 'c1',
        nomeContato: 'Bar Central',
        mensagens: [mensagem('1', 'Olá'), mensagem('2', 'Tudo bem?')],
      );

      final copia = Conversa.fromMap('c1', original.toMap());

      expect(copia.nomeContato, 'Bar Central');
      expect(copia.mensagens.map((m) => m.id), ['1', '2']);
      expect(copia.mensagens.map((m) => m.texto), ['Olá', 'Tudo bem?']);
    });

    test('fromMap lê mensagens vindas do Firestore (Timestamp e Map genérico)', () {
      final copia = Conversa.fromMap('c1', {
        'nomeContato': 'Pub',
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
    });

    test('ultimaMensagem retorna o texto da última ou um aviso', () {
      final comMensagens = Conversa(
        id: 'c1',
        nomeContato: 'A',
        mensagens: [mensagem('1', 'Primeira'), mensagem('2', 'Última')],
      );
      final vazia = Conversa(id: 'c2', nomeContato: 'B', mensagens: []);

      expect(comMensagens.ultimaMensagem, 'Última');
      expect(vazia.ultimaMensagem, 'Sem mensagens');
    });
  });
}
