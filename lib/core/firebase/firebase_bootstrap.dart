import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

/// Inicializa o Firebase. Não existe mais modo offline/mock (Plano 5): se
/// devolver `false`, o `main` mostra a tela de erro em vez do app.
class FirebaseBootstrap {
  static Future<bool> initialize() async {
    if (Firebase.apps.isNotEmpty) return true;

    try {
      if (DefaultFirebaseOptions.isConfigured) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        return true;
      }

      // Android/iOS: usa google-services.json / GoogleService-Info.plist.
      if (temConfiguracaoNativa) {
        await Firebase.initializeApp();
        return true;
      }
    } catch (_) {
      return false;
    }

    // Web e desktop só têm configuração via --dart-define.
    return false;
  }

  static bool get temConfiguracaoNativa =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}
