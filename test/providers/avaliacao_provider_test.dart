import 'package:backstage/models/contratacao.dart';
import 'package:backstage/providers/avaliacao_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/firebase_fake.dart';

/// Show c1 entre o músico m1 e o dono e1, realizado anteontem.
void main() {
  late FakeFirebaseFirestore firestore;
  late AvaliacaoProvider musico;
  late AvaliacaoProvider dono;

  String diaHa(int n) =>
      Contratacao.diaDe(DateTime.now().subtract(Duration(days: n)));

  Contratacao show({String id = 'c1', int diasAtras = 2}) => Contratacao(
    id: id,
    interesseId: 'i1',
    musicoId: 'm1',
    musicoNome: 'Banda',
    donoId: 'e1',
    donoNome: 'Bar Central',
    titulo: 'Show de sexta',
    dia: diaHa(diasAtras),
    horaInicio: '20:00',
    horaFim: '23:00',
    cacheAcordado: 1500,
    logradouro: 'Rua A',
    numero: '10',
    cidade: 'Franca',
    estado: 'SP',
    criadoEm: DateTime(2026, 1, 1),
    status: StatusContratacao.confirmada,
  );

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    musico = AvaliacaoProvider(service: servicoFake(firestore: firestore, uid: 'm1'));
    dono = AvaliacaoProvider(service: servicoFake(firestore: firestore, uid: 'e1'));
    await aguardar();
  });

  tearDown(() {
    musico.dispose();
    dono.dispose();
  });

  test('músico avalia o dono: grava, entra na média e avisa o dono', () async {
    expect(await musico.avaliar(show(), nota: 4, comentario: '  Bom palco  '), isTrue);
    await aguardar();

    final doc = await firestore.collection('avaliacoes').doc('c1_m1').get();
    expect(doc.data()?['avaliadoId'], 'e1');
    expect(doc.data()?['comentario'], 'Bom palco');
    expect(dono.resumoDe('e1').quantidade, 1);
    expect(dono.resumoDe('e1').media, 4);
    expect(musico.minhaAvaliacao('c1')?.nota, 4);
    expect(dono.minhaAvaliacao('c1'), isNull);
    expect(dono.recebidasPor('e1').single.autorNome, 'Banda');

    final notificacoes = await firestore.collection('notificacoes').get();
    final aviso = notificacoes.docs.single.data();
    expect(aviso['destinatarioId'], 'e1');
    expect(aviso['tipo'], 'avaliacaoRecebida');
    expect(aviso['texto'], contains('Avalie também.'));
  });

  test('paraAvaliar: só shows dentro do prazo ainda não avaliados por mim', () async {
    final lista = [
      show(),
      show(id: 'hoje', diasAtras: 0),
      show(id: 'velho', diasAtras: 40),
    ];
    expect(musico.paraAvaliar(lista).map((c) => c.id), ['c1']);

    await musico.avaliar(show(), nota: 5, comentario: '');
    await aguardar();

    expect(musico.paraAvaliar(lista), isEmpty);
    // O dono ainda não avaliou.
    expect(dono.paraAvaliar(lista).map((c) => c.id), ['c1']);
  });

  test('segunda avaliação avisa sem convidar a avaliar', () async {
    await musico.avaliar(show(), nota: 5, comentario: '');
    await aguardar();
    await dono.avaliar(show(), nota: 3, comentario: 'Atrasou');
    await aguardar();

    final paraMusico = (await firestore
            .collection('notificacoes')
            .where('destinatarioId', isEqualTo: 'm1')
            .get())
        .docs
        .single
        .data();
    expect(paraMusico['texto'], isNot(contains('Avalie também')));
    expect(musico.resumoDe('m1').media, 3);
  });

  test('sem ninguém logado não avalia', () async {
    final deslogado = AvaliacaoProvider(service: servicoFake(firestore: firestore, uid: null));
    await aguardar();

    expect(await deslogado.avaliar(show(), nota: 5, comentario: ''), isFalse);
    deslogado.dispose();
  });
}
