import 'package:backstage/models/contratacao.dart';
import 'package:backstage/models/interesse.dart';
import 'package:backstage/models/mensagem.dart';
import 'package:backstage/models/notificacao.dart';
import 'package:backstage/providers/chat_provider.dart';
import 'package:backstage/providers/contratacao_provider.dart';
import 'package:backstage/providers/interesse_provider.dart';
import 'package:backstage/providers/notificacao_provider.dart';
import 'package:backstage/providers/oportunidade_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/firebase_fake.dart';

/// Dono `e1` e músico `m1` no mesmo Firestore fake; a oportunidade `o1` é
/// de e1. Cada teste confere quem recebe o aviso de cada ação.
void main() {
  late FakeFirebaseFirestore firestore;
  final descartar = <void Function()>[];

  T criar<T>(T provider, void Function() dispose) {
    descartar.add(dispose);
    return provider;
  }

  NotificacaoProvider notificacoesDe(String uid) {
    final p = NotificacaoProvider(service: servicoFake(firestore: firestore, uid: uid));
    return criar(p, p.dispose);
  }

  InteresseProvider interessesDe(String uid) {
    final p = InteresseProvider(service: servicoFake(firestore: firestore, uid: uid));
    return criar(p, p.dispose);
  }

  OportunidadeProvider oportunidadesDe(String uid) {
    final p = OportunidadeProvider(service: servicoFake(firestore: firestore, uid: uid));
    return criar(p, p.dispose);
  }

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await gravarCatalogo(
      firestore,
      oportunidades: [oportunidadeTeste(id: 'o1', donoId: 'e1')],
    );
  });

  tearDown(() {
    for (final dispose in descartar) {
      dispose();
    }
    descartar.clear();
  });

  Future<void> candidatar() async {
    final musico = interessesDe('m1');
    await aguardar();
    await musico.enviarCandidatura(
      oportunidade: oportunidadeTeste(id: 'o1', donoId: 'e1'),
      remetenteId: 'm1',
      remetenteNome: 'Guilherme',
      musicoNome: 'Banda',
    );
    await aguardar();
  }

  test('candidatura avisa o dono; aceitar avisa o músico', () async {
    final avisosDono = notificacoesDe('e1');
    final avisosMusico = notificacoesDe('m1');
    await candidatar();

    expect(avisosDono.naoLidas, 1);
    expect(avisosDono.notificacoes.single.tipo, TipoNotificacao.interesseRecebido);
    expect(avisosMusico.notificacoes, isEmpty);

    final dono = interessesDe('e1');
    await aguardar();
    await dono.aceitar(dono.recebidos.single, nomeDestinatario: 'Bar Central');
    await aguardar();

    expect(avisosMusico.notificacoes.single.tipo, TipoNotificacao.interesseAceito);
    expect(avisosMusico.notificacoes.single.autorNome, 'Bar Central');
  });

  test('recusar avisa quem se candidatou', () async {
    final avisosMusico = notificacoesDe('m1');
    await candidatar();
    final dono = interessesDe('e1');
    await aguardar();

    await dono.recusar(dono.recebidos.single, nomeDestinatario: 'Bar Central');
    await aguardar();

    expect(avisosMusico.notificacoes.single.tipo, TipoNotificacao.interesseRecusado);
  });

  test('editar cachê avisa o candidato; mudar só o título não', () async {
    final avisosMusico = notificacoesDe('m1');
    await candidatar();
    final oportunidades = oportunidadesDe('e1');
    await aguardar();

    final atual = oportunidades.buscarOportunidadePorId('o1')!;
    await oportunidades.atualizarOportunidade(atual.copyWith(titulo: 'Outro nome'));
    await aguardar();
    expect(avisosMusico.notificacoes, isEmpty);

    await oportunidades.atualizarOportunidade(
      oportunidades.buscarOportunidadePorId('o1')!.copyWith(cacheOferecido: 1500),
    );
    await aguardar();

    final aviso = avisosMusico.notificacoes.single;
    expect(aviso.tipo, TipoNotificacao.oportunidadeAlterada);
    expect(aviso.texto, contains('cachê R\$ 1200.00 → R\$ 1500.00'));
    expect(aviso.oportunidadeId, 'o1');
  });

  test('remover encerra os pendentes e avisa os interessados', () async {
    final avisosMusico = notificacoesDe('m1');
    await candidatar();
    // Convite pendente do dono para outro músico, na mesma oportunidade.
    await firestore.collection('interesses').doc('e1_mu_m2_o1').set(
      Interesse(
        id: 'e1_mu_m2_o1',
        tipo: TipoInteresse.convite,
        remetenteId: 'e1',
        remetenteNome: 'Bar Central',
        destinatarioId: 'm2',
        musicoId: 'm2',
        musicoNome: 'Outra Banda',
        oportunidadeId: 'o1',
        criadoEm: DateTime(2026, 9, 1),
      ).toMap(),
    );
    final avisosM2 = notificacoesDe('m2');
    final oportunidades = oportunidadesDe('e1');
    await aguardar();

    expect(await oportunidades.removerOportunidade('o1'), isTrue);
    await aguardar();

    final candidatura = await firestore.collection('interesses').doc('m1_op_o1').get();
    final convite = await firestore.collection('interesses').doc('e1_mu_m2_o1').get();
    expect(candidatura.data()?['status'], 'recusado');
    expect(convite.data()?['status'], 'cancelado');
    expect((await firestore.collection('oportunidades').doc('o1').get()).exists, isFalse);
    expect(avisosMusico.notificacoes.single.tipo, TipoNotificacao.oportunidadeRemovida);
    expect(avisosM2.notificacoes.single.texto, contains('Seu interesse pendente foi encerrado'));
  });

  test('remover é bloqueado com contratação em andamento', () async {
    await firestore.collection('contratacoes').doc('c1').set({
      'interesseId': 'm1_op_o1',
      'musicoId': 'm1',
      'donoId': 'e1',
      'oportunidadeId': 'o1',
      'dia': '2099-11-20',
      'status': 'confirmada',
    });
    final oportunidades = oportunidadesDe('e1');
    await aguardar();

    expect(await oportunidades.removerOportunidade('o1'), isFalse);
    expect(oportunidades.errorMessage, contains('contratação em andamento'));
    expect((await firestore.collection('oportunidades').doc('o1').get()).exists, isTrue);
  });

  test('propor, confirmar e cancelar avisam sempre a outra parte', () async {
    await candidatar();
    final dono = interessesDe('e1');
    await aguardar();
    await dono.aceitar(dono.recebidos.single, nomeDestinatario: 'Bar Central');
    final avisosDono = notificacoesDe('e1');
    final avisosMusico = notificacoesDe('m1');
    final contratacoesDono = ContratacaoProvider(
      service: servicoFake(firestore: firestore, uid: 'e1'),
    );
    final contratacoesMusico = ContratacaoProvider(
      service: servicoFake(firestore: firestore, uid: 'm1'),
    );
    descartar
      ..add(contratacoesDono.dispose)
      ..add(contratacoesMusico.dispose);
    await aguardar();

    await contratacoesDono.propor(
      Contratacao(
        id: '',
        interesseId: 'm1_op_o1',
        musicoId: 'm1',
        musicoNome: 'Banda',
        donoId: 'e1',
        donoNome: 'Bar Central',
        titulo: 'Show de sexta',
        dia: '2099-11-20',
        horaInicio: '21:00',
        horaFim: '23:00',
        cacheAcordado: 1200,
        logradouro: 'Rua A',
        numero: '10',
        cidade: 'Franca',
        estado: 'SP',
        criadoEm: DateTime.now(),
      ),
    );
    await aguardar();
    final proposta = avisosMusico.notificacoes.firstWhere(
      (n) => n.tipo == TipoNotificacao.contratacaoProposta,
    );
    expect(proposta.contratacaoId, contratacoesMusico.recebidas.single.id);

    await contratacoesMusico.confirmar(contratacoesMusico.recebidas.single);
    await aguardar();
    expect(
      avisosDono.notificacoes.map((n) => n.tipo),
      contains(TipoNotificacao.contratacaoConfirmada),
    );

    await contratacoesMusico.cancelar(
      contratacoesMusico.recebidas.single,
      motivo: 'Imprevisto',
    );
    await aguardar();
    final cancelada = avisosDono.notificacoes.firstWhere(
      (n) => n.tipo == TipoNotificacao.contratacaoCancelada,
    );
    expect(cancelada.texto, endsWith(': Imprevisto.'));
  });

  test('marcar como lida, marcar todas e remover', () async {
    final avisos = notificacoesDe('m1');
    final servico = servicoFake(firestore: firestore, uid: 'e1');
    await servico.notificar([
      for (final titulo in ['A', 'B', 'C'])
        Notificacao(
          destinatarioId: 'm1',
          autorId: 'e1',
          autorNome: 'Bar Central',
          tipo: TipoNotificacao.interesseRecebido,
          titulo: titulo,
          texto: '',
          interesseId: 'i',
          criadaEm: DateTime(2026, 9, titulo.codeUnitAt(0)),
        ),
    ]);
    await aguardar();

    expect(avisos.notificacoes.map((n) => n.titulo), ['C', 'B', 'A']);
    expect(avisos.naoLidas, 3);

    await avisos.marcarComoLida(avisos.notificacoes.first);
    await aguardar();
    expect(avisos.naoLidas, 2);

    await avisos.marcarTodasComoLidas();
    await aguardar();
    expect(avisos.naoLidas, 0);

    await avisos.remover(avisos.notificacoes.last);
    await aguardar();
    expect(avisos.notificacoes.map((n) => n.titulo), ['C', 'B']);
  });

  test('chat: não lidas por conversa, total e marcar como lida', () async {
    await firestore.collection('conversas').doc('i1').set({
      'participantes': ['e1', 'm1'],
      'nomes': {'e1': 'Bar Central', 'm1': 'Banda'},
      'mensagens': [
        for (final (i, de) in ['e1', 'e1', 'm1'].indexed)
          Mensagem(
            id: '$i',
            remetenteId: de,
            texto: 'msg $i',
            dataHora: DateTime(2026, 9, 1, 10, i),
          ).toMap(),
      ],
    });
    final chat = ChatProvider(service: servicoFake(firestore: firestore, uid: 'm1'));
    descartar.add(chat.dispose);
    await aguardar();

    expect(chat.naoLidas(chat.conversas.single), 2);
    expect(chat.totalNaoLidas, 2);

    await chat.marcarComoLida('i1');
    await aguardar();

    expect(chat.totalNaoLidas, 0);
    final doc = await firestore.collection('conversas').doc('i1').get();
    expect((doc.data()?['lidaEm'] as Map).containsKey('m1'), isTrue);
  });
}
