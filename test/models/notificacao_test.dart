import 'package:backstage/models/contratacao.dart';
import 'package:backstage/models/conversa.dart';
import 'package:backstage/models/interesse.dart';
import 'package:backstage/models/mensagem.dart';
import 'package:backstage/models/notificacao.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/firebase_fake.dart';

Interesse _candidatura({StatusInteresse status = StatusInteresse.pendente}) =>
    Interesse(
      id: 'm1_op_o1',
      tipo: TipoInteresse.candidatura,
      remetenteId: 'm1',
      remetenteNome: 'Guilherme',
      destinatarioId: 'e1',
      musicoId: 'm1',
      musicoNome: 'Banda',
      oportunidadeId: 'o1',
      oportunidadeTitulo: 'Show de sexta',
      criadoEm: DateTime(2026, 9, 1),
      status: status,
    );

Interesse _convite() => Interesse(
  id: 'e1_mu_m1',
  tipo: TipoInteresse.convite,
  remetenteId: 'e1',
  remetenteNome: 'Bar Central',
  destinatarioId: 'm1',
  musicoId: 'm1',
  musicoNome: 'Banda',
  criadoEm: DateTime(2026, 9, 1),
);

Contratacao _contratacao() => Contratacao(
  id: 'c1',
  interesseId: 'm1_op_o1',
  musicoId: 'm1',
  musicoNome: 'Banda',
  donoId: 'e1',
  donoNome: 'Bar Central',
  oportunidadeId: 'o1',
  titulo: 'Show de sexta',
  dia: '2026-11-20',
  horaInicio: '21:00',
  horaFim: '23:00',
  cacheAcordado: 1500,
  logradouro: 'Rua A',
  numero: '10',
  cidade: 'Franca',
  estado: 'SP',
  criadoEm: DateTime(2026, 9, 1),
);

void main() {
  group('Notificacao de interesse', () {
    test('candidatura recebida vai para o dono, com autor = músico', () {
      final n = Notificacao.interesseRecebido(_candidatura());

      expect(n.destinatarioId, 'e1');
      expect(n.autorId, 'm1');
      expect(n.interesseId, 'm1_op_o1');
      expect(n.titulo, 'Nova candidatura');
      expect(n.texto, 'Banda quer tocar em "Show de sexta".');
      expect(n.destino, DestinoNotificacao.interesses);
      expect(n.lida, isFalse);
    });

    test('convite recebido vai para o músico', () {
      final n = Notificacao.interesseRecebido(_convite());

      expect(n.destinatarioId, 'm1');
      expect(n.texto, 'Bar Central convidou você para tocar.');
    });

    test('resposta vai para quem enviou', () {
      final aceito = Notificacao.interesseRespondido(
        _candidatura(),
        aceito: true,
        nomeQuemRespondeu: 'Bar Central',
      );
      final recusado = Notificacao.interesseRespondido(
        _convite(),
        aceito: false,
        nomeQuemRespondeu: 'Banda',
      );

      expect(aceito.destinatarioId, 'm1');
      expect(aceito.autorId, 'e1');
      expect(aceito.tipo, TipoNotificacao.interesseAceito);
      expect(aceito.texto, contains('aceitou sua candidatura para "Show de sexta"'));
      expect(recusado.destinatarioId, 'e1');
      expect(recusado.texto, 'Banda recusou seu convite.');
    });
  });

  group('Notificacao de oportunidade', () {
    final antes = oportunidadeTeste(id: 'o1').copyWith(
      horaInicio: '21:00',
      horaFim: '23:00',
    );

    test('mudancas lista data, horário, cachê e local', () {
      final depois = antes.copyWith(
        dataEvento: DateTime(2099, 11, 21),
        horaInicio: '22:00',
        cacheOferecido: 1500,
        numero: '20',
      );

      final mudancas = Notificacao.mudancas(antes, depois);

      expect(mudancas, [
        'data 20/11/2099 → 21/11/2099',
        'horário 21:00 às 23:00 → 22:00 às 23:00',
        'cachê R\$ 1200.00 → R\$ 1500.00',
        'local Rua A, 10 — Franca/SP → Rua A, 20 — Franca/SP',
      ]);
    });

    test('mudar só título ou descrição não notifica', () {
      final depois = antes.copyWith(titulo: 'Novo nome', descricao: 'Outra');

      expect(Notificacao.mudancas(antes, depois), isEmpty);
      expect(
        Notificacao.oportunidadeAlterada(
          _candidatura(),
          antes: antes,
          depois: depois,
          nomeDono: 'Bar Central',
        ),
        isNull,
      );
    });

    test('alterada vai do dono para o músico e leva à oportunidade', () {
      final n = Notificacao.oportunidadeAlterada(
        _candidatura(),
        antes: antes,
        depois: antes.copyWith(cacheOferecido: 1500),
        nomeDono: 'Bar Central',
      )!;

      expect(n.destinatarioId, 'm1');
      expect(n.autorId, 'e1');
      expect(n.oportunidadeId, 'o1');
      expect(n.destino, DestinoNotificacao.oportunidade);
      expect(n.texto, contains('cachê R\$ 1200.00 → R\$ 1500.00'));
    });

    test('removida avisa que o pendente foi encerrado', () {
      final pendente = Notificacao.oportunidadeRemovida(
        _candidatura(),
        tituloOportunidade: 'Show de sexta',
        nomeDono: 'Bar Central',
      );
      final aceito = Notificacao.oportunidadeRemovida(
        _candidatura(status: StatusInteresse.aceito),
        tituloOportunidade: 'Show de sexta',
        nomeDono: 'Bar Central',
      );

      expect(pendente.texto, contains('Seu interesse pendente foi encerrado'));
      expect(aceito.texto, isNot(contains('pendente')));
      expect(pendente.destino, DestinoNotificacao.interesses);
    });
  });

  group('Notificacao de contratação', () {
    test('proposta do dono vai para o músico, com dados do show', () {
      final n = Notificacao.contratacao(
        _contratacao(),
        tipo: TipoNotificacao.contratacaoProposta,
        autorId: 'e1',
      );

      expect(n.destinatarioId, 'm1');
      expect(n.autorNome, 'Bar Central');
      expect(n.contratacaoId, 'c1');
      expect(n.interesseId, 'm1_op_o1');
      expect(n.texto, contains('20/11/2026, 21:00 às 23:00'));
      expect(n.destino, DestinoNotificacao.contratacoes);
    });

    test('confirmação do músico vai para o dono; cancelamento leva o motivo', () {
      final confirmada = Notificacao.contratacao(
        _contratacao(),
        tipo: TipoNotificacao.contratacaoConfirmada,
        autorId: 'm1',
      );
      final cancelada = Notificacao.contratacao(
        _contratacao().copyWith(motivoCancelamento: 'Chuva'),
        tipo: TipoNotificacao.contratacaoCancelada,
        autorId: 'm1',
      );

      expect(confirmada.destinatarioId, 'e1');
      expect(confirmada.autorNome, 'Banda');
      expect(cancelada.texto, endsWith(': Chuva.'));
    });
  });

  test('toMap e fromMap preservam os campos', () {
    final original = Notificacao.interesseRecebido(_candidatura());

    final map = original.toMap();
    final copia = Notificacao.fromMap('n1', {
      ...map,
      'criadaEm': Timestamp.fromDate(DateTime(2026, 9, 29, 10)),
    });

    expect(map['tipo'], 'interesseRecebido');
    expect(map.containsKey('contratacaoId'), isFalse);
    expect(copia.id, 'n1');
    expect(copia.tipo, TipoNotificacao.interesseRecebido);
    expect(copia.criadaEm, DateTime(2026, 9, 29, 10));
    expect(copia.copyWith(lida: true).lida, isTrue);
  });

  group('Conversa.naoLidas', () {
    Mensagem msg(String de, DateTime quando) =>
        Mensagem(id: '$de$quando', remetenteId: de, texto: 'oi', dataHora: quando);

    final conversa = Conversa(
      id: 'c',
      participantes: ['e1', 'm1'],
      nomes: const {},
      mensagens: [
        msg('e1', DateTime(2026, 9, 1, 10)),
        msg('m1', DateTime(2026, 9, 1, 11)),
        msg('e1', DateTime(2026, 9, 1, 12)),
      ],
    );

    test('sem leitura registrada, conta todas as do outro', () {
      expect(conversa.naoLidas('m1'), 2);
      expect(conversa.naoLidas('e1'), 1);
      expect(conversa.naoLidas(null), 0);
    });

    test('conta só as posteriores à última leitura; lidaEm faz ida e volta', () {
      final lida = Conversa.fromMap('c', {
        ...conversa.toMap(),
        'lidaEm': {'m1': Timestamp.fromDate(DateTime(2026, 9, 1, 11, 30))},
      });

      expect(lida.naoLidas('m1'), 1);
      expect(lida.lidaEm['m1'], DateTime(2026, 9, 1, 11, 30));
      expect(conversa.toMap().containsKey('lidaEm'), isFalse);
    });
  });

  test('Interesse cancelado tem rótulo próprio', () {
    expect(
      _candidatura(status: StatusInteresse.cancelado).rotuloStatus,
      'Cancelado',
    );
  });
}
