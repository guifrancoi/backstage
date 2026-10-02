import 'package:backstage/models/contratacao.dart';
import 'package:backstage/models/denuncia.dart';
import 'package:backstage/models/interesse.dart';
import 'package:backstage/providers/denuncia_provider.dart';
import 'package:backstage/providers/oportunidade_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/firebase_fake.dart';

/// Plano 22: bloqueio (no OportunidadeProvider) e denúncia (DenunciaProvider).
void main() {
  late FakeFirebaseFirestore firestore;

  Interesse interesse(
    String id, {
    required String remetente,
    required String destinatario,
    StatusInteresse status = StatusInteresse.pendente,
  }) => Interesse(
    id: id,
    tipo: remetente == 'e1' ? TipoInteresse.convite : TipoInteresse.candidatura,
    remetenteId: remetente,
    remetenteNome: remetente,
    destinatarioId: destinatario,
    musicoId: remetente == 'e1' ? destinatario : remetente,
    musicoNome: 'Banda',
    criadoEm: DateTime(2026, 9, 1),
    status: status,
  );

  Contratacao contratacao(String id, StatusContratacao status) => Contratacao(
    id: id,
    interesseId: 'i1',
    musicoId: 'm1',
    musicoNome: 'Banda',
    donoId: 'e1',
    donoNome: 'Bar Central',
    titulo: 'Show $id',
    dia: '2099-05-0${id.length}',
    horaInicio: '20:00',
    horaFim: '23:00',
    cacheAcordado: 1000,
    logradouro: 'Rua A',
    numero: '1',
    cidade: 'Franca',
    estado: 'SP',
    criadoEm: DateTime(2026, 9, 1),
    status: status,
    cacheContraproposto: status == StatusContratacao.contraproposta ? 1500 : null,
  );

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await gravarCatalogo(
      firestore,
      musicos: [
        musicoTeste(id: 'm1', nomeArtistico: 'Banda Bloqueada'),
        musicoTeste(id: 'm2', nomeArtistico: 'Banda Livre'),
      ],
      oportunidades: [
        oportunidadeTeste(id: 'o1', titulo: 'Do dono bloqueado', donoId: 'e2'),
        oportunidadeTeste(id: 'o2', titulo: 'De outro dono', donoId: 'e3'),
      ],
    );
  });

  group('bloqueio', () {
    test('bloquear esconde o músico das listas e das sugestões; desbloquear volta', () async {
      final dono = OportunidadeProvider(service: servicoFake(firestore: firestore, uid: 'e1'));
      await aguardar();
      expect(dono.musicos, hasLength(2));

      expect(await dono.bloquear('m1', 'Banda Bloqueada'), isTrue);
      await aguardar();
      expect(dono.ehBloqueado('m1'), isTrue);
      expect(dono.musicos.map((m) => m.id), ['m2']);
      expect(dono.bloqueados.single.nome, 'Banda Bloqueada');
      expect(
        dono
            .musicosSugeridos(
              oportunidadeTeste(id: 'x', donoId: 'e1'),
              indisponiveis: {},
              comInteresse: {},
            )
            .map((s) => s.item.id),
        isNot(contains('m1')),
      );

      expect(await dono.desbloquear('m1'), isTrue);
      await aguardar();
      expect(dono.musicos, hasLength(2));
      dono.dispose();
    });

    test('músico que bloqueia um dono deixa de ver as oportunidades dele', () async {
      final musico = OportunidadeProvider(service: servicoFake(firestore: firestore, uid: 'm2'));
      await aguardar();

      await musico.bloquear('e2', 'Dono');
      await aguardar();

      expect(musico.oportunidades.map((o) => o.id), ['o2']);
      musico.dispose();
    });

    test('bloquear encerra o que está pendente entre os dois; o confirmado fica', () async {
      await firestore.collection('interesses').doc('rec').set(
        interesse('rec', remetente: 'm1', destinatario: 'e1').toMap(),
      );
      await firestore.collection('interesses').doc('env').set(
        interesse('env', remetente: 'e1', destinatario: 'm1').toMap(),
      );
      await firestore.collection('interesses').doc('aceito').set(
        interesse('aceito', remetente: 'e1', destinatario: 'm1', status: StatusInteresse.aceito)
            .toMap(),
      );
      await firestore.collection('interesses').doc('outro').set(
        interesse('outro', remetente: 'm2', destinatario: 'e1').toMap(),
      );
      for (final (id, status) in [
        ('p', StatusContratacao.proposta),
        ('cp', StatusContratacao.contraproposta),
        ('ok!', StatusContratacao.confirmada),
      ]) {
        await firestore.collection('contratacoes').doc(id).set(contratacao(id, status).toMap());
      }
      final dono = OportunidadeProvider(service: servicoFake(firestore: firestore, uid: 'e1'));
      await aguardar();

      expect(await dono.bloquear('m1', 'Banda'), isTrue);
      await aguardar();

      Future<String?> status(String colecao, String id) async =>
          (await firestore.collection(colecao).doc(id).get()).data()?['status'] as String?;
      expect(await status('interesses', 'rec'), 'recusado');
      expect(await status('interesses', 'env'), 'cancelado');
      expect(await status('interesses', 'aceito'), 'aceito');
      expect(await status('interesses', 'outro'), 'pendente'); // de outra pessoa
      expect(await status('contratacoes', 'p'), 'cancelada');
      expect(await status('contratacoes', 'cp'), 'cancelada');
      expect(await status('contratacoes', 'ok!'), 'confirmada');
      dono.dispose();
    });

    test('quando o músico bloqueia: recusa a proposta e retira a contraproposta', () async {
      for (final (id, status) in [
        ('p', StatusContratacao.proposta),
        ('cp', StatusContratacao.contraproposta),
      ]) {
        await firestore.collection('contratacoes').doc(id).set(contratacao(id, status).toMap());
      }
      final musico = OportunidadeProvider(service: servicoFake(firestore: firestore, uid: 'm1'));
      await aguardar();

      await musico.bloquear('e1', 'Bar Central');
      await aguardar();

      expect((await firestore.doc('contratacoes/p').get()).data()?['status'], 'recusada');
      expect((await firestore.doc('contratacoes/cp').get()).data()?['status'], 'cancelada');
      musico.dispose();
    });

    test('não bloqueia a si mesmo', () async {
      final dono = OportunidadeProvider(service: servicoFake(firestore: firestore, uid: 'e1'));
      await aguardar();
      expect(await dono.bloquear('e1', 'Eu'), isFalse);
      dono.dispose();
    });
  });

  group('denúncia', () {
    test('qualquer um denuncia; só o admin vê a lista e marca como analisada', () async {
      final musico = DenunciaProvider(service: servicoFake(firestore: firestore, uid: 'm1'));
      final admin = DenunciaProvider(
        service: servicoFake(firestore: firestore, uid: 'adm', admin: true),
      );
      await aguardar();

      expect(
        await musico.denunciar(
          autorNome: 'Banda',
          tipoAlvo: TipoAlvoDenuncia.perfil,
          alvoId: 'e1',
          alvoUid: 'e1',
          descricaoAlvo: 'Bar Central',
          motivo: MotivoDenuncia.golpe,
          texto: '  Pediu PIX antes  ',
        ),
        isTrue,
      );
      await aguardar();

      expect(musico.denuncias, isEmpty); // não é admin: nem assina
      expect(admin.pendentes, 1);
      final d = admin.denuncias.single;
      expect(d.autorId, 'm1');
      expect(d.texto, 'Pediu PIX antes');

      expect(await admin.marcarAnalisada(d), isTrue);
      await aguardar();
      expect(admin.pendentes, 0);
      expect(admin.denuncias.single.analisada, isTrue);
      musico.dispose();
      admin.dispose();
    });

    test('não denuncia a si mesmo', () async {
      final musico = DenunciaProvider(service: servicoFake(firestore: firestore, uid: 'm1'));
      await aguardar();
      expect(
        await musico.denunciar(
          autorNome: 'Banda',
          tipoAlvo: TipoAlvoDenuncia.perfil,
          alvoId: 'm1',
          alvoUid: 'm1',
          descricaoAlvo: 'Eu',
          motivo: MotivoDenuncia.outro,
        ),
        isFalse,
      );
      musico.dispose();
    });
  });
}
