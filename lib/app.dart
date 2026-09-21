import 'package:flutter/material.dart';
import 'package:device_preview_plus/device_preview_plus.dart';

import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'screens/agenda/agenda_screen.dart';
import 'screens/auth/cadastro_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/recuperar_senha_screen.dart';
import 'screens/busca/filtro_busca_screen.dart';
import 'screens/busca/lista_musicos_screen.dart';
import 'screens/busca/lista_oportunidades_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/chat/conversas_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/perfil/perfil_screen.dart';
import 'screens/sobre/sobre_screen.dart';
import 'screens/busca/meus_interesses_screen.dart';
import 'screens/busca/meus_artistas_interesse_screen.dart';
import 'screens/busca/detalhe_musico_screen.dart';
import 'screens/busca/detalhe_oportunidade_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Backstage',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.cadastro: (_) => const CadastroScreen(),
        AppRoutes.recuperarSenha: (_) => const RecuperarSenhaScreen(),
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.perfil: (_) => const PerfilScreen(),
        AppRoutes.listaMusicos: (_) => const ListaMusicosScreen(),
        AppRoutes.listaOportunidades: (_) => const ListaOportunidadesScreen(),
        AppRoutes.filtroBusca: (_) => const FiltroBuscaScreen(),
        AppRoutes.agenda: (_) => const AgendaScreen(),
        AppRoutes.conversas: (_) => const ConversasScreen(),
        AppRoutes.sobre: (_) => const SobreScreen(),
        AppRoutes.meusInteresses: (_) => const MeusInteressesScreen(),
        AppRoutes.meusArtistasInteresse: (_) =>
            const MeusArtistasInteresseScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.chat) {
          final conversaId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => ChatScreen(conversaId: conversaId),
          );
        }

        if (settings.name == AppRoutes.detalheMusico) {
          final musicoId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => DetalheMusicoScreen(musicoId: musicoId),
          );
        }

        if (settings.name == AppRoutes.detalheOportunidade) {
          final oportunidadeId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) =>
                DetalheOportunidadeScreen(oportunidadeId: oportunidadeId),
          );
        }

        return null;
      },
    );
  }
}
