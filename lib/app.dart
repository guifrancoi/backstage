import 'package:flutter/material.dart';
import 'package:device_preview_plus/device_preview_plus.dart';

import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'screens/agenda/agenda_screen.dart';
import 'screens/auth/cadastro_screen.dart';
import 'screens/auth/completar_perfil_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/recuperar_senha_screen.dart';
import 'screens/busca/lista_musicos_screen.dart';
import 'screens/busca/lista_oportunidades_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/chat/conversas_screen.dart';
import 'screens/contratacoes/contratacoes_screen.dart';
import 'screens/contratacoes/propor_contratacao_screen.dart';
import 'screens/home/shell_screen.dart';
import 'screens/interesses/interesses_screen.dart';
import 'screens/notificacoes/notificacoes_screen.dart';
import 'screens/oportunidades/minhas_oportunidades_screen.dart';
import 'screens/oportunidades/nova_oportunidade_screen.dart';
import 'screens/perfil/perfil_screen.dart';
import 'screens/sobre/sobre_screen.dart';
import 'screens/busca/detalhe_estabelecimento_screen.dart';
import 'screens/moderacao/bloqueados_screen.dart';
import 'screens/moderacao/denuncias_screen.dart';
import 'screens/numeros/meus_numeros_screen.dart';
import 'screens/busca/detalhe_musico_screen.dart';
import 'screens/busca/detalhe_oportunidade_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Backstage',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.escuro,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.cadastro: (_) => const CadastroScreen(),
        AppRoutes.completarPerfil: (_) => const CompletarPerfilScreen(),
        AppRoutes.recuperarSenha: (_) => const RecuperarSenhaScreen(),
        AppRoutes.home: (_) => const ShellScreen(),
        AppRoutes.perfil: (_) => const PerfilScreen(),
        AppRoutes.listaMusicos: (_) => const ListaMusicosScreen(),
        AppRoutes.listaOportunidades: (_) => const ListaOportunidadesScreen(),
        AppRoutes.agenda: (_) => const AgendaScreen(),
        AppRoutes.conversas: (_) => const ConversasScreen(),
        AppRoutes.sobre: (_) => const SobreScreen(),
        AppRoutes.meusNumeros: (_) => const MeusNumerosScreen(),
        AppRoutes.bloqueados: (_) => const BloqueadosScreen(),
        AppRoutes.denuncias: (_) => const DenunciasScreen(),
        AppRoutes.interesses: (_) => const InteressesScreen(),
        AppRoutes.minhasOportunidades: (_) => const MinhasOportunidadesScreen(),
        AppRoutes.novaOportunidade: (_) => const NovaOportunidadeScreen(),
        AppRoutes.contratacoes: (_) => const ContratacoesScreen(),
        AppRoutes.notificacoes: (_) => const NotificacoesScreen(),
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

        if (settings.name == AppRoutes.proporContratacao) {
          final interesseId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => ProporContratacaoScreen(interesseId: interesseId),
          );
        }

        if (settings.name == AppRoutes.editarOportunidade) {
          final oportunidadeId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) =>
                NovaOportunidadeScreen(oportunidadeId: oportunidadeId),
          );
        }

        if (settings.name == AppRoutes.detalheEstabelecimento) {
          final donoId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => DetalheEstabelecimentoScreen(donoId: donoId),
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
