import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static const _androidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
    defaultValue: 'AIzaSyBpuTN8HWqzd_8tbwvk9JXadkFDj1qThQI',
  );
  static const _iosApiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const _webApiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
  static const _genericApiKey = String.fromEnvironment('FIREBASE_API_KEY');

  static const _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
    defaultValue: '1:553548688619:android:0eddee8ad9ba82a3dce2ae',
  );
  static const _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const _webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const _genericAppId = String.fromEnvironment('FIREBASE_APP_ID');

  static const _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'backstage-531a9',
  );
  static const _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '553548688619',
  );
  static const _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'backstage-531a9.firebasestorage.app',
  );
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const _measurementId = String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
  );
  static const _iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');

  static bool get isConfigured {
    return apiKeyForCurrentPlatform.isNotEmpty &&
        appIdForCurrentPlatform.isNotEmpty &&
        _messagingSenderId.isNotEmpty &&
        _projectId.isNotEmpty;
  }

  static String get apiKeyForCurrentPlatform {
    if (kIsWeb) return _webApiKey;

    return switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        _androidApiKey.isNotEmpty ? _androidApiKey : _genericApiKey,
      TargetPlatform.iOS => _iosApiKey.isNotEmpty ? _iosApiKey : _genericApiKey,
      _ => _genericApiKey,
    };
  }

  static String get appIdForCurrentPlatform {
    if (kIsWeb) return _webAppId;

    return switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        _androidAppId.isNotEmpty ? _androidAppId : _genericAppId,
      TargetPlatform.iOS => _iosAppId.isNotEmpty ? _iosAppId : _genericAppId,
      _ => _genericAppId,
    };
  }

  static FirebaseOptions get currentPlatform {
    if (!isConfigured) {
      throw StateError(
        'Firebase nao configurado. Defina as credenciais via --dart-define.',
      );
    }

    return FirebaseOptions(
      apiKey: apiKeyForCurrentPlatform,
      appId: appIdForCurrentPlatform,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      authDomain: _authDomain.isEmpty
          ? '$_projectId.firebaseapp.com'
          : _authDomain,
      storageBucket: _storageBucket,
      measurementId: _measurementId.isEmpty ? null : _measurementId,
      iosBundleId: _iosBundleId.isEmpty ? null : _iosBundleId,
    );
  }
}
