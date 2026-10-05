import 'package:backstage/core/logging/app_logger.dart';
import 'package:backstage/models/contratacao.dart';
import 'package:backstage/models/conversa.dart';
import 'package:backstage/models/interesse.dart';
import 'package:backstage/models/notificacao.dart';
import 'package:backstage/providers/agenda_provider.dart';
import 'package:backstage/providers/auth_provider.dart';
import 'package:backstage/providers/chat_provider.dart';
import 'package:backstage/providers/contratacao_provider.dart';
import 'package:backstage/providers/interesse_provider.dart';
import 'package:backstage/providers/notificacao_provider.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/captura_log.dart';
import '../helpers/firebase_fake.dart';

/// Plano 6: falhas capturadas vão para o AppLogger em vez de sumir (ou de
/// escapar como erro não tratado, que o Crashlytics contaria como crash).

final _negado = FirebaseException(
  plugin: 'cloud_firestore',
  code: 'permission-denied',
);

/// Usuário logado cujos streams e gravações falham.
class _ServicoQueFalha extends FirebaseDataService {
  _ServicoQueFalha({FakeFirebaseFirestore? firestore})
    : super(
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'u1'),
        ),
        firestore: firestore ?? FakeFirebaseFirestore(),
      );

  @override
  Future<UserCredential> login({required String email, required String senha}) =>
      Future.error(FirebaseAuthException(code: 'invalid-credential'));

  @override
  Stream<List<Interesse>> streamInteressesEnviados(String uid) =>
      Stream.error(_negado);

  @override
  Stream<List<Interesse>> streamInteressesRecebidos(String uid) =>
      Stream.error(_negado);

  @override
  Stream<List<Conversa>> streamConversas(String uid) => Stream.error(_negado);

  @override
  Stream<List<Contratacao>> streamContratacoes(String uid) =>
      Stream.error(_negado);

  @override
  Stream<List<Notificacao>> streamNotificacoes(String uid) =>
      Stream.error(_negado);

  @override
  Future<void> bloquearDia(String usuarioId, DateTime data) =>
      Future.error(_negado);
}

void main() {
  test('login recusado vira aviso com o código, sem o e-mail', () async {
    final captura = capturarLogs();
    final provider = AuthProvider(service: _ServicoQueFalha());
    addTearDown(provider.dispose);

    await provider.login(email: 'fulano@email.com', senha: 'segredo');

    final falhas = captura
        .de('AuthProvider')
        .where((r) => r.nivel == NivelLog.aviso)
        .toList();
    expect(falhas.single.mensagem, 'Falha no login (auth/invalid-credential)');
    for (final r in captura.registros) {
      expect(r.mensagem, isNot(contains('fulano')));
      expect(r.mensagem, isNot(contains('segredo')));
    }
  });

  test('login e logout deixam trilha (info)', () async {
    final captura = capturarLogs();
    final provider = AuthProvider(service: servicoFake(uid: null));
    addTearDown(provider.dispose);

    await provider.login(email: 'u1@backstage.com', senha: '123456');
    await provider.logout();

    expect(captura.de('AuthProvider').map((r) => r.mensagem), [
      'Login',
      'Logout',
    ]);
  });

  test('erro nos streams é registrado, não fica sem tratamento', () async {
    final captura = capturarLogs();
    final service = _ServicoQueFalha();
    final providers = [
      InteresseProvider(service: service),
      ChatProvider(service: service),
      ContratacaoProvider(service: service),
      NotificacaoProvider(service: service),
    ];
    addTearDown(() {
      for (final p in providers) {
        p.dispose();
      }
    });

    await aguardar();

    final origens = captura.registros.map((r) => r.origem).toList();
    expect(origens.where((o) => o == 'InteresseProvider'), hasLength(2));
    expect(origens, contains('ChatProvider'));
    expect(origens, contains('ContratacaoProvider'));
    expect(origens, contains('NotificacaoProvider'));
    expect(
      captura.registros.every(
        (r) =>
            r.nivel == NivelLog.aviso &&
            r.mensagem.endsWith('(cloud_firestore/permission-denied)'),
      ),
      isTrue,
    );
  });

  test('bloquearDia que falha desfaz a marcação e registra', () async {
    final captura = capturarLogs();
    final provider = AgendaProvider(service: _ServicoQueFalha());
    addTearDown(provider.dispose);
    await aguardar();

    await provider.bloquearDia(DateTime(2026, 12, 25));

    expect(provider.bloqueado(DateTime(2026, 12, 25)), isFalse);
    expect(
      captura.de('AgendaProvider').single.mensagem,
      'Falha ao gravar bloqueio (cloud_firestore/permission-denied)',
    );
  });
}
