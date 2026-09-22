import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

class FirebaseBootstrap {
  static Future<bool> initialize() async {
    if (Firebase.apps.isNotEmpty) return true;

    if (DefaultFirebaseOptions.isConfigured) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return true;
    }

    // Android/iOS: usa google-services.json / GoogleService-Info.plist.
    if (_temConfiguracaoNativa) {
      try {
        await Firebase.initializeApp();
        return true;
      } catch (_) {
        return false;
      }
    }

    return false;
  }

  static bool get isEnabled => Firebase.apps.isNotEmpty;

  static bool get _temConfiguracaoNativa =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}
