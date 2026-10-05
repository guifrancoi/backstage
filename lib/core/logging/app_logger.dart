import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Gravidade do registro. `aviso` = falha esperada (usuário digitou senha
/// errada, regra recusou, rede caiu); `erro` = falha que não devia acontecer;
/// `fatal` = erro não tratado que chegou ao topo do app.
enum NivelLog { info, aviso, erro, fatal }

class RegistroLog {
  const RegistroLog({
    required this.nivel,
    required this.origem,
    required this.mensagem,
    this.erro,
    this.stack,
  });

  final NivelLog nivel;

  /// Quem registrou (ex.: `AuthProvider`), para filtrar no console.
  final String origem;
  final String mensagem;
  final Object? erro;
  final StackTrace? stack;
}

/// Para onde os registros vão (console, Crashlytics, captura em teste).
abstract class DestinoLog {
  void registrar(RegistroLog registro);

  /// Uid do usuário logado (`null` no logout), para agrupar as falhas.
  void definirUsuario(String? uid) {}
}

/// Uma linha por registro no terminal do `flutter run` / logcat
/// (`[aviso] AuthProvider: ...`), com a pilha em erro e fatal. Mudo em
/// release: lá quem guarda é o Crashlytics.
class DestinoConsole extends DestinoLog {
  @override
  void registrar(RegistroLog registro) {
    if (kReleaseMode) return;
    debugPrint(
      '[${registro.nivel.name}] ${registro.origem}: ${registro.mensagem}',
    );
    final stack = registro.stack;
    if (stack != null && registro.nivel.index >= NivelLog.erro.index) {
      debugPrint(stack.toString());
    }
  }
}

/// Ponto único de log do app (Plano 6). Nunca registrar senha; e-mail e
/// textos digitados pelo usuário também ficam de fora — basta o `code` do
/// erro e o uid (via [definirUsuario]).
class AppLogger {
  AppLogger._();

  static List<DestinoLog> _destinos = [DestinoConsole()];

  /// Troca os destinos (`main` acrescenta o Crashlytics; testes capturam).
  static void configurar(List<DestinoLog> destinos) =>
      _destinos = List.of(destinos);

  static void restaurarPadrao() => _destinos = [DestinoConsole()];

  static void info(String origem, String mensagem) => _registrar(
    RegistroLog(nivel: NivelLog.info, origem: origem, mensagem: mensagem),
  );

  static void aviso(
    String origem,
    String mensagem, {
    Object? erro,
    StackTrace? stack,
  }) => _registrar(
    RegistroLog(
      nivel: NivelLog.aviso,
      origem: origem,
      mensagem: mensagem,
      erro: erro,
      stack: stack,
    ),
  );

  static void erro(
    String origem,
    String mensagem,
    Object erro, [
    StackTrace? stack,
  ]) => _registrar(
    RegistroLog(
      nivel: NivelLog.erro,
      origem: origem,
      mensagem: mensagem,
      erro: erro,
      stack: stack,
    ),
  );

  /// Registra uma falha capturada em `catch`/`onError`: o nível sai de
  /// [nivelDaFalha] e o `code` do Firebase vai junto na mensagem.
  static void falha(
    String origem,
    String mensagem,
    Object erro, [
    StackTrace? stack,
  ]) => _registrar(
    RegistroLog(
      nivel: nivelDaFalha(erro),
      origem: origem,
      mensagem: '$mensagem (${descreverErro(erro)})',
      erro: erro,
      stack: stack,
    ),
  );

  /// Atalho para `onError` de stream/future: registra com [falha].
  static void Function(Object, StackTrace) aoFalhar(
    String origem,
    String mensagem,
  ) =>
      (erro, stack) => falha(origem, mensagem, erro, stack);

  /// Erro não tratado (`FlutterError.onError` / `PlatformDispatcher.onError`).
  static void fatal(Object erro, StackTrace? stack, {String origem = 'app'}) =>
      _registrar(
        RegistroLog(
          nivel: NivelLog.fatal,
          origem: origem,
          mensagem: 'Erro não tratado (${descreverErro(erro)})',
          erro: erro,
          stack: stack,
        ),
      );

  static void definirUsuario(String? uid) {
    for (final destino in _destinos) {
      try {
        destino.definirUsuario(uid);
      } catch (_) {
        // Log nunca derruba o app.
      }
    }
  }

  static void _registrar(RegistroLog registro) {
    for (final destino in _destinos) {
      try {
        destino.registrar(registro);
      } catch (_) {
        // Log nunca derruba o app.
      }
    }
  }
}

/// Códigos que vêm do uso normal (dado digitado, regra de negócio nas
/// `firestore.rules`, rede): viram aviso, não erro.
const _codigosEsperados = {
  // Auth: o que o usuário digitou.
  'invalid-email',
  'user-disabled',
  'user-not-found',
  'wrong-password',
  'invalid-credential',
  'email-already-in-use',
  'weak-password',
  'too-many-requests',
  'network-request-failed',
  // Firestore: regra recusou, documento sumiu, rede.
  'permission-denied',
  'not-found',
  'already-exists',
  'unavailable',
  'deadline-exceeded',
  'cancelled',
};

NivelLog nivelDaFalha(Object erro) {
  if (erro is TimeoutException) return NivelLog.aviso;
  if (erro is FirebaseException && _codigosEsperados.contains(erro.code)) {
    return NivelLog.aviso;
  }
  return NivelLog.erro;
}

/// Resumo curto, sem a mensagem nativa (que pode citar o e-mail):
/// `auth/invalid-credential`, `cloud_firestore/permission-denied`,
/// `TimeoutException`.
String descreverErro(Object erro) {
  if (erro is FirebaseAuthException) return 'auth/${erro.code}';
  if (erro is FirebaseException) return '${erro.plugin}/${erro.code}';
  return erro.runtimeType.toString();
}
