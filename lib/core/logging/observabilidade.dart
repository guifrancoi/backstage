import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../services/firebase_data_service.dart';
import '../firebase/firebase_bootstrap.dart';
import 'app_logger.dart';

/// Envia para o Crashlytics: info/aviso viram trilha (`log`, que acompanha o
/// próximo relatório), erro vira não fatal e fatal vira crash.
class DestinoCrashlytics extends DestinoLog {
  DestinoCrashlytics(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  @override
  void registrar(RegistroLog registro) {
    final texto = '${registro.origem}: ${registro.mensagem}';
    switch (registro.nivel) {
      case NivelLog.info:
      case NivelLog.aviso:
        _crashlytics.log('[${registro.nivel.name}] $texto');
      case NivelLog.erro:
      case NivelLog.fatal:
        _crashlytics.recordError(
          registro.erro ?? texto,
          registro.stack,
          reason: texto,
          fatal: registro.nivel == NivelLog.fatal,
        );
    }
  }

  @override
  void definirUsuario(String? uid) => _crashlytics.setUserIdentifier(uid ?? '');
}

/// Liga o Crashlytics (Plano 6) depois do Firebase inicializado: só em
/// release e só no Android/iOS (o plugin não tem Web/desktop). Em debug os
/// registros ficam no console e o Flutter mostra os erros como sempre.
Future<void> configurarObservabilidade() async {
  if (!FirebaseBootstrap.temConfiguracaoNativa) return;

  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(kReleaseMode);
  if (!kReleaseMode) return;

  AppLogger.configurar([DestinoConsole(), DestinoCrashlytics(crashlytics)]);
  FlutterError.onError = (detalhes) =>
      AppLogger.fatal(detalhes.exception, detalhes.stack, origem: 'flutter');
  PlatformDispatcher.instance.onError = (erro, stack) {
    AppLogger.fatal(erro, stack);
    return true;
  };
  FirebaseDataService().authUserIds.listen(AppLogger.definirUsuario);
}
