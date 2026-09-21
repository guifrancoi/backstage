import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:device_preview_plus/device_preview_plus.dart';

import 'app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'providers/agenda_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/oportunidade_provider.dart';
import 'providers/perfil_provider.dart';
import 'services/location_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => PerfilProvider()),
          ChangeNotifierProvider(create: (_) => OportunidadeProvider()),
          ChangeNotifierProvider(create: (_) => AgendaProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          Provider<LocationService>(
            create: (_) => LocationService(),
            dispose: (_, s) => s.dispose(),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}
