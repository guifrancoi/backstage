import 'dart:async';

import 'package:backstage/core/logging/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/captura_log.dart';

class _DestinoQueFalha extends DestinoLog {
  @override
  void registrar(RegistroLog registro) => throw StateError('destino caiu');

  @override
  void definirUsuario(String? uid) => throw StateError('destino caiu');
}

FirebaseException _firestore(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

void main() {
  group('nivelDaFalha', () {
    test('erros de uso normal viram aviso', () {
      expect(
        nivelDaFalha(FirebaseAuthException(code: 'invalid-credential')),
        NivelLog.aviso,
      );
      expect(nivelDaFalha(_firestore('permission-denied')), NivelLog.aviso);
      expect(nivelDaFalha(_firestore('unavailable')), NivelLog.aviso);
      expect(nivelDaFalha(TimeoutException('lento')), NivelLog.aviso);
    });

    test('o resto vira erro', () {
      expect(nivelDaFalha(_firestore('internal')), NivelLog.erro);
      expect(
        nivelDaFalha(FirebaseAuthException(code: 'operation-not-allowed')),
        NivelLog.erro,
      );
      expect(nivelDaFalha(StateError('bug')), NivelLog.erro);
    });
  });

  test('descreverErro dá plugin/código ou o tipo', () {
    expect(
      descreverErro(FirebaseAuthException(code: 'weak-password')),
      'auth/weak-password',
    );
    expect(
      descreverErro(_firestore('not-found')),
      'cloud_firestore/not-found',
    );
    expect(descreverErro(TimeoutException('x')), 'TimeoutException');
  });

  test('falha registra o código, sem a mensagem nativa do erro', () {
    final captura = capturarLogs();
    final erro = FirebaseAuthException(
      code: 'email-already-in-use',
      message: 'fulano@email.com já existe',
    );

    AppLogger.falha('Teste', 'Falha no cadastro', erro, StackTrace.current);

    final registro = captura.registros.single;
    expect(registro.nivel, NivelLog.aviso);
    expect(registro.origem, 'Teste');
    expect(registro.mensagem, 'Falha no cadastro (auth/email-already-in-use)');
    expect(registro.mensagem, isNot(contains('@')));
    expect(registro.erro, same(erro));
    expect(registro.stack, isNotNull);
  });

  test('info, aviso, erro e fatal chegam com o nível certo', () {
    final captura = capturarLogs();

    AppLogger.info('T', 'a');
    AppLogger.aviso('T', 'b');
    AppLogger.erro('T', 'c', StateError('x'));
    AppLogger.fatal(StateError('y'), null);

    expect(captura.registros.map((r) => r.nivel), [
      NivelLog.info,
      NivelLog.aviso,
      NivelLog.erro,
      NivelLog.fatal,
    ]);
    expect(captura.registros.last.mensagem, 'Erro não tratado (StateError)');
  });

  test('aoFalhar serve de onError de stream', () async {
    final captura = capturarLogs();

    final sub = Stream<int>.error(_firestore('permission-denied')).listen(
      (_) {},
      onError: AppLogger.aoFalhar('T', 'Falha no stream'),
    );
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(
      captura.registros.single.mensagem,
      'Falha no stream (cloud_firestore/permission-denied)',
    );
  });

  test('um destino que lança não impede os outros nem o app', () {
    final captura = CapturaLog();
    AppLogger.configurar([_DestinoQueFalha(), captura]);
    addTearDown(AppLogger.restaurarPadrao);

    AppLogger.info('T', 'segue');
    AppLogger.definirUsuario('u1');

    expect(captura.registros, hasLength(1));
    expect(captura.usuarios, ['u1']);
  });
}
