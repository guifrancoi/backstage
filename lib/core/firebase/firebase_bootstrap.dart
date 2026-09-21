import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

class FirebaseBootstrap {
  static Future<bool> initialize() async {
    if (!DefaultFirebaseOptions.isConfigured) return false;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    return true;
  }

  static bool get isEnabled => Firebase.apps.isNotEmpty;
}
