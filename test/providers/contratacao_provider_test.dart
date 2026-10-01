import 'package:backstage/models/agenda_publica.dart';
import 'package:backstage/models/contratacao.dart';
import 'package:backstage/models/interesse.dart';
import 'package:backstage/providers/agenda_provider.dart';
import 'package:backstage/providers/contratacao_provider.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/firebase_fake.dart';

/// Dono `e1` e músico `m1` sobre o mesmo Firestore fake, com o convite
/// `i1` (e1 → m1) já aceito.
void main() {
  late FakeFirebaseFirestore firestore;
  late ContratacaoProvider dono;
  late ContratacaoProvider musico;

  Contratacao proposta({String dia = '2026-11-20'}) => Contratacao(
    id: '',
    interesseId: 'i1',
    musicoId: 'm1',
    musicoNome: 'Banda',
    donoId: 'e1',
    donoNome: 'Bar Central',
    titulo: 'Show de sexta',
    dia: dia,
    horaInicio: '20:00',
    horaFim: '23:00',
    cacheAcordado: 1500,
    logradouro: 'Rua A',
    numero: '10',
    cidade: 'Franca',
    estado: 'SP',
    criadoEm: DateTime.now(),
  );

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('interesses').doc('i1').set(
      Interesse(
        id: 'i1',
        tipo: TipoInteresse.convite,
        remetenteId: 'e1',
        remetenteNome: 'Bar Central',
        destinatarioId: 'm1',
        musicoId: 'm1',
        musicoNome: 'Banda',
        criadoEm: DateTime(2026, 9, 1),
        status: StatusInteresse.aceito,
      ).toMap(),
    );
    dono = ContratacaoProvider(
      service: servicoFake(firestore: firestore, uid: 'e1'),
    );
    musico = ContratacaoProvider(
      service: servicoFake(firestore: firestore, uid: 'm1'),
    );
    await aguardar();
  });

  tearDown(() {
    dono.dispose();
    musico.dispose();
  });

  Future<bool> ocupado(String dia) async => (await firestore
          .collection('ocupacoes')
          .doc(Contratacao.idOcupacao('m1', dia))
          .get())
      .exists;

  test('dono propõe: aparece como enviada para ele e recebida pelo músico', () async {
    expect(await dono.propor(proposta()), isTrue);
    await aguardar();

    expect(dono.enviadas, hasLength(1));
    expect(dono.recebidas, isEmpty);
    expect(musico.recebidas.single.status, StatusContratacao.proposta);
    expect(musico.propostasPendentes, 1);
    expect(dono.propostasPendentes, 0);
    expect(dono.ativaParaInteresse('i1'), isNotNull);
    expect(musico.doDia(DateTime(2026, 11, 20)), hasLength(1));
  });

  test('músico confirma: status confirmada e o dia fica ocupado', () async {
    await dono.propor(proposta());
    await aguardar();

    expect(await musico.confirmar(musico.recebidas.single), isTrue);
    await aguardar();

    expect(musico.recebidas.single.status, StatusContratacao.confirmada);
    expect(dono.enviadas.single.status, StatusContratacao.confirmada);
    expect(musico.propostasPendentes, 0);
    expect(await ocupado('2026-11-20'), isTrue);
  });

  test('cancelar a confirmada libera o dia e guarda quem e por quê', () async {
    await dono.propor(proposta());
    await aguardar();
    await musico.confirmar(musico.recebidas.single);
    await aguardar();

    expect(
      await dono.cancelar(dono.enviadas.single, motivo: ' Chuva forte '),
      isTrue,
    );
    await aguardar();

    final cancelada = musico.recebidas.single;
    expect(cancelada.status, StatusContratacao.cancelada);
    expect(cancelada.canceladoPor, 'e1');
    expect(cancelada.motivoCancelamento, 'Chuva forte');
    expect(await ocupado('2026-11-20'), isFalse);
    expect(dono.ativaParaInteresse('i1'), isNull);
  });

  test('músico recusa a proposta; nada fica ocupado', () async {
    await dono.propor(proposta());
    await aguardar();

    expect(await musico.recusar(musico.recebidas.single), isTrue);
    await aguardar();

    expect(dono.enviadas.single.status, StatusContratacao.recusada);
    expect(await ocupado('2026-11-20'), isFalse);
    expect(dono.ativaParaInteresse('i1'), isNull);
  });

  test('sem ninguém logado: listas vazias e cancelar não faz nada', () async {
    final deslogado = ContratacaoProvider(
      service: servicoFake(firestore: firestore, uid: null),
    );
    await aguardar();

    expect(deslogado.todas, isEmpty);
    expect(await deslogado.cancelar(proposta()), isFalse);
    deslogado.dispose();
  });

  test('agenda pública junta bloqueios e ocupações do músico', () async {
    final servicoMusico = servicoFake(firestore: firestore, uid: 'm1');
    await servicoMusico.bloquearDia('m1', DateTime(2026, 11, 21));
    await dono.propor(proposta());
    await aguardar();
    await musico.confirmar(musico.recebidas.single);
    await aguardar();

    final agenda = AgendaProvider(
      service: servicoFake(firestore: firestore, uid: 'e1'),
    );
    final AgendaPublica publica = await agenda.agendaPublica('m1').first;

    expect(publica.ocupado('2026-11-20'), isTrue);
    expect(publica.livre('2026-11-20'), isFalse);
    expect(publica.bloqueado('2026-11-21'), isTrue);
    expect(publica.livre('2026-11-22'), isTrue);
    agenda.dispose();
  });

  test('streamContratacoes junta os dois papéis sem repetir', () async {
    // e1 é dono de c1 e músico de c2 (conta admin atua nos dois papéis).
    await firestore.collection('contratacoes').doc('c1').set(proposta().toMap());
    await firestore.collection('contratacoes').doc('c2').set({
      ...proposta().toMap(),
      'musicoId': 'e1',
      'donoId': 'x9',
    });
    final FirebaseDataService servico = servicoFake(
      firestore: firestore,
      uid: 'e1',
    );

    final lista = await servico.streamContratacoes('e1').first;

    expect(lista.map((c) => c.id), unorderedEquals(['c1', 'c2']));
  });

  group('filtrar', () {
    Contratacao c(
      String titulo,
      String dia,
      StatusContratacao status, {
      DateTime? criadoEm,
      DateTime? respondidoEm,
      String cidade = 'Franca',
    }) => Contratacao(
      id: titulo,
      interesseId: 'i',
      musicoId: 'm1',
      musicoNome: 'Banda',
      donoId: 'e1',
      donoNome: 'Bar Central',
      titulo: titulo,
      dia: dia,
      horaInicio: '20:00',
      horaFim: '22:00',
      cacheAcordado: 1,
      logradouro: 'Rua',
      numero: '1',
      cidade: cidade,
      estado: 'SP',
      criadoEm: criadoEm ?? DateTime(2026, 9, 1),
      respondidoEm: respondidoEm,
      status: status,
    );

    final lista = [
      c('A', '2099-05-01', StatusContratacao.proposta, criadoEm: DateTime(2026, 9, 1)),
      // Criada antes, mas confirmada depois: é a movimentação mais recente.
      c('B', '2099-01-01', StatusContratacao.confirmada,
          criadoEm: DateTime(2026, 8, 1), respondidoEm: DateTime(2026, 9, 5)),
      c('C', '2020-01-01', StatusContratacao.confirmada, cidade: 'Ribeirão Preto'),
      c('D', '2099-02-01', StatusContratacao.recusada),
    ];
    List<String> titulos(List<Contratacao> l) => l.map((x) => x.titulo).toList();

    test('mais recentes = última movimentação primeiro (padrão)', () {
      expect(titulos(dono.filtrar(lista)).first, 'B');
    });

    test('data do show: do mais próximo ao mais distante', () {
      expect(
        titulos(dono.filtrar(lista, ordem: OrdemContratacao.dataDoShow)),
        ['C', 'B', 'D', 'A'],
      );
    });

    test('situação: confirmadas exclui realizadas; encerradas inclui', () {
      expect(titulos(dono.filtrar(lista, filtro: FiltroContratacao.propostas)), ['A']);
      expect(titulos(dono.filtrar(lista, filtro: FiltroContratacao.confirmadas)), ['B']);
      expect(
        titulos(dono.filtrar(lista, filtro: FiltroContratacao.encerradas)),
        unorderedEquals(['C', 'D']),
      );
    });

    test('busca por título, nome ou cidade, sem diferenciar maiúsculas', () {
      expect(titulos(dono.filtrar(lista, termo: ' RIBEIRÃO ')), ['C']);
      expect(dono.filtrar(lista, termo: 'bar central'), hasLength(4));
      expect(dono.filtrar(lista, termo: 'xyz'), isEmpty);
    });
  });
}
