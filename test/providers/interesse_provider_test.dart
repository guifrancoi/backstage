import 'package:backstage/models/interesse.dart';
import 'package:backstage/models/musico.dart';
import 'package:backstage/models/oportunidade.dart';
import 'package:backstage/providers/interesse_provider.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

/// Deixa os streams do Firestore fake entregarem as atualizações.
Future<void> _aguardar() => Future<void>.delayed(const Duration(milliseconds: 50));

/// Dois usuários (músico `m1` e dono `e1`) no mesmo Firestore fake.
void main() {
  late FakeFirebaseFirestore firestore;
  late InteresseProvider musico;
  late InteresseProvider dono;

  InteresseProvider logadoComo(String uid) {
    return InteresseProvider(
      service: FirebaseDataService(
        auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: uid)),
        firestore: firestore,
      ),
    );
  }

  final oportunidade = Oportunidade(
    id: 'o1',
    titulo: 'Show de sexta',
    descricao: '',
    cidade: 'Franca',
    generoMusical: 'Rock',
    dataEvento: DateTime(2026, 10, 10),
    cacheOferecido: 900,
    contratante: 'Bar Central',
    donoId: 'e1',
    logradouro: '',
    numero: '',
    estado: 'SP',
  );

  final perfilMusico = Musico(
    id: 'm1',
    nomeArtistico: 'The VooDooS',
    generoMusical: 'Metal',
    cidade: 'Franca',
    descricao: '',
    cacheMedio: 1000,
    portfolioLinks: const [],
  );

  Future<bool> enviarCandidatura() => musico.enviarCandidatura(
    oportunidade: oportunidade,
    remetenteId: 'm1',
    remetenteNome: 'Guilherme',
    musicoNome: 'The VooDooS',
  );

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    musico = logadoComo('m1');
    dono = logadoComo('e1');
    await _aguardar();
  });

  tearDown(() {
    musico.dispose();
    dono.dispose();
  });

  test('candidatura aparece em enviados do músico e recebidos do dono', () async {
    await enviarCandidatura();
    await _aguardar();

    expect(musico.candidaturaPara('o1')?.rotuloStatus, 'Candidatura enviada');
    expect(dono.recebidos.single.musicoNome, 'The VooDooS');
    expect(dono.pendentesRecebidos, 1);
    expect(musico.pendentesRecebidos, 0);
  });

  test('aceitar abre conversa e atualiza os dois lados', () async {
    await enviarCandidatura();
    await _aguardar();

    final conversaId = await dono.aceitar(
      dono.recebidos.single,
      nomeDestinatario: 'Bar Central',
    );
    await _aguardar();

    expect(conversaId, 'e1_m1');
    expect(dono.pendentesRecebidos, 0);
    expect(musico.candidaturaPara('o1')?.status, StatusInteresse.aceito);
    expect(musico.candidaturaPara('o1')?.conversaId, conversaId);
    final conversa = await firestore.collection('conversas').doc(conversaId).get();
    expect(conversa.data()?['participantes'], ['e1', 'm1']);
  });

  test('recusar marca como recusado para o remetente', () async {
    await enviarCandidatura();
    await _aguardar();

    expect(
      await dono.recusar(dono.recebidos.single, nomeDestinatario: 'Bar Central'),
      isTrue,
    );
    await _aguardar();

    expect(musico.candidaturaPara('o1')?.rotuloStatus, 'Recusado');
  });

  test('cancelar remove dos dois lados', () async {
    await enviarCandidatura();
    await _aguardar();

    expect(await musico.cancelar(musico.enviados.single), isTrue);
    await _aguardar();

    expect(musico.enviados, isEmpty);
    expect(dono.recebidos, isEmpty);
  });

  test('convite com oportunidade chega ao músico', () async {
    await dono.enviarConvite(
      musico: perfilMusico,
      remetenteId: 'e1',
      remetenteNome: 'Bar Central',
      oportunidade: oportunidade,
    );
    await _aguardar();

    // Estado por oportunidade: nesta já há convite; sem oportunidade, livre.
    expect(dono.situacaoConvite('m1', oportunidadeId: 'o1'), SituacaoConvite.enviado);
    expect(dono.situacaoConvite('m1'), SituacaoConvite.livre);
    expect(dono.convitesPendentesPara('m1'), 1);
    expect(musico.recebidos.single.tipo, TipoInteresse.convite);
    expect(musico.recebidos.single.oportunidadeTitulo, 'Show de sexta');
  });

  test('match: candidatura para oportunidade já convidada aceita o convite', () async {
    await dono.enviarConvite(
      musico: perfilMusico,
      remetenteId: 'e1',
      remetenteNome: 'Bar Central',
      oportunidade: oportunidade,
    );
    await _aguardar();

    expect(await enviarCandidatura(), isTrue);
    await _aguardar();

    // Não cria candidatura nova: o convite recebido vira aceito.
    expect(musico.candidaturaPara('o1'), isNull);
    expect(musico.recebidos.single.status, StatusInteresse.aceito);
    expect(dono.situacaoConvite('m1', oportunidadeId: 'o1'), SituacaoConvite.aceito);
    expect(dono.convitesPendentesPara('m1'), 0);
    final conversas = await firestore.collection('conversas').get();
    expect(conversas.docs.single.id, 'e1_m1');
  });

  test('match: convite para quem já se candidatou aceita a candidatura', () async {
    await enviarCandidatura();
    await _aguardar();

    await dono.enviarConvite(
      musico: perfilMusico,
      remetenteId: 'e1',
      remetenteNome: 'Bar Central',
      oportunidade: oportunidade,
    );
    await _aguardar();

    expect(dono.situacaoConvite('m1', oportunidadeId: 'o1'), SituacaoConvite.aceito);
    expect(musico.candidaturaPara('o1')?.status, StatusInteresse.aceito);
  });

  test('situacaoConvite: candidatura pendente, recusado e outra oportunidade livre', () async {
    await enviarCandidatura();
    await _aguardar();
    expect(
      dono.situacaoConvite('m1', oportunidadeId: 'o1'),
      SituacaoConvite.candidaturaPendente,
    );
    // Outra oportunidade do mesmo dono continua livre para convite.
    expect(dono.situacaoConvite('m1', oportunidadeId: 'o2'), SituacaoConvite.livre);

    await dono.enviarConvite(
      musico: perfilMusico,
      remetenteId: 'e1',
      remetenteNome: 'Bar Central',
    );
    await _aguardar();
    await musico.recusar(
      musico.recebidos.firstWhere((i) => i.oportunidadeId == null),
      nomeDestinatario: 'Banda',
    );
    await _aguardar();
    expect(dono.situacaoConvite('m1'), SituacaoConvite.recusado);
    expect(SituacaoConvite.recusado.selecionavel, isFalse);
    expect(SituacaoConvite.candidaturaPendente.selecionavel, isTrue);
  });

  test('logout limpa as listas', () async {
    final auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'm1'));
    final provider = InteresseProvider(
      service: FirebaseDataService(auth: auth, firestore: firestore),
    );
    await enviarCandidatura();
    await _aguardar();
    expect(provider.enviados, isNotEmpty);

    await auth.signOut();
    await _aguardar();

    expect(provider.enviados, isEmpty);
    provider.dispose();
  });

}
