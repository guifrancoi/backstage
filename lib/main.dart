import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:device_preview_plus/device_preview_plus.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'providers/agenda_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/contratacao_provider.dart';
import 'providers/interesse_provider.dart';
import 'providers/notificacao_provider.dart';
import 'providers/oportunidade_provider.dart';
import 'providers/perfil_provider.dart';
import 'screens/erro/erro_inicializacao_app.dart';
import 'services/location_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nomes de mês/dia em PT-BR no calendário da agenda (table_calendar).
  await initializeDateFormatting('pt_BR');
  await _iniciar();
}

/// Sem Firebase não há app: mostra a tela de erro, que chama de novo esta
/// função em "Tentar novamente".
Future<void> _iniciar() async {
  if (!await FirebaseBootstrap.initialize()) {
    runApp(ErroInicializacaoApp(onTentarNovamente: _iniciar));
    return;
  }

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
          ChangeNotifierProvider(create: (_) => InteresseProvider()),
          ChangeNotifierProvider(create: (_) => ContratacaoProvider()),
          ChangeNotifierProvider(create: (_) => NotificacaoProvider()),
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
