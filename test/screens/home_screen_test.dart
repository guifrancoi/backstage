import 'package:backstage/core/theme/app_theme.dart';
import 'package:backstage/providers/auth_provider.dart';
import 'package:backstage/providers/avaliacao_provider.dart';
import 'package:backstage/providers/chat_provider.dart';
import 'package:backstage/providers/contratacao_provider.dart';
import 'package:backstage/providers/denuncia_provider.dart';
import 'package:backstage/providers/interesse_provider.dart';
import 'package:backstage/providers/notificacao_provider.dart';
import 'package:backstage/providers/oportunidade_provider.dart';
import 'package:backstage/providers/perfil_provider.dart';
import 'package:backstage/routes/app_routes.dart';
import 'package:backstage/screens/busca/busca_screen.dart';
import 'package:backstage/screens/home/home_screen.dart';
import 'package:backstage/screens/home/shell_screen.dart';
import 'package:backstage/screens/perfil/perfil_screen.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/firebase_fake.dart';

/// Plano 8, Fase 1: barra inferior, Home por papel e menu da conta.
Widget _app(
  FirebaseDataService service,
  Widget home, {
  bool comLogin = false,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider(service: service)),
      ChangeNotifierProvider(create: (_) => PerfilProvider(service: service)),
      ChangeNotifierProvider(create: (_) => AvaliacaoProvider(service: service)),
      ChangeNotifierProvider(create: (_) => InteresseProvider(service: service)),
      ChangeNotifierProvider(create: (_) => ContratacaoProvider(service: service)),
      ChangeNotifierProvider(create: (_) => NotificacaoProvider(service: service)),
      ChangeNotifierProvider(create: (_) => ChatProvider(service: service)),
      ChangeNotifierProvider(create: (_) => OportunidadeProvider(service: service)),
      ChangeNotifierProvider(create: (_) => DenunciaProvider(service: service)),
    ],
    child: MaterialApp(
      theme: AppTheme.escuro,
      // AppRoutes.login é '/': com `home`, '/' seria a própria tela.
      home: comLogin ? null : home,
      initialRoute: comLogin ? '/tela' : null,
      routes: comLogin
          ? {
              AppRoutes.login: (_) => const Scaffold(body: Text('Tela login')),
              '/tela': (_) => home,
            }
          : const {},
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(),
          body: Text('${settings.name} ${settings.arguments}'),
        ),
      ),
    ),
  );
}

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('usuarios').doc('e1').set({
      'nome': 'Bar Central',
      'tipoUsuario': 'casaShow',
    });
    await gravarCatalogo(
      firestore,
      musicos: [musicoTeste(id: 'm1', nomeArtistico: 'Ana Vieira')],
      oportunidades: [oportunidadeTeste(id: 'o1', titulo: 'Sexta do Rock')],
    );
  });

  test('saudação pela hora do dia', () {
    expect(saudacaoPara(DateTime(2026, 1, 1, 8)), 'Bom dia');
    expect(saudacaoPara(DateTime(2026, 1, 1, 14)), 'Boa tarde');
    expect(saudacaoPara(DateTime(2026, 1, 1, 21)), 'Boa noite');
    expect(saudacaoPara(DateTime(2026, 1, 1, 3)), 'Boa noite');
  });

  testWidgets('Home do dono: próxima oportunidade, músicos e atalhos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'e1'), const HomeScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bar Central'), findsWidgets);
    expect(find.text('Sua próxima oportunidade'), findsOneWidget);
    expect(find.text('Sexta do Rock'), findsOneWidget);
    expect(find.text('Músicos em destaque'), findsOneWidget);
    expect(find.text('Ana Vieira'), findsOneWidget);
    expect(find.text('Minhas vagas'), findsOneWidget);

    await tester.tap(find.text('Ana Vieira'));
    await tester.pumpAndSettle();
    expect(find.text('${AppRoutes.detalheMusico} m1'), findsOneWidget);
  });

  testWidgets('Home cabe numa tela de 320 px (celular compacto)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'e1'), const ShellScreen()),
    );
    await tester.pumpAndSettle();

    // Overflow de layout vira exceção no teste.
    expect(tester.takeException(), isNull);
    expect(find.text('Acesso rápido'), findsOneWidget);
  });

  testWidgets('dono sem oportunidade futura é convidado a publicar', (
    tester,
  ) async {
    await firestore.collection('oportunidades').doc('o1').delete();
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'e1'), const HomeScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Publique uma oportunidade'));
    await tester.pumpAndSettle();
    expect(find.text('${AppRoutes.novaOportunidade} null'), findsOneWidget);
  });

  testWidgets('shell: busca da Home abre a aba Buscar e voltar volta ao Início', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'e1'), const ShellScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Buscar músicos e oportunidades'));
    await tester.pumpAndSettle();
    // Dono começa em Músicos (procurado dentro da aba Buscar: a Home
    // continua montada por trás e também mostra o músico).
    expect(find.widgetWithText(AppBar, 'Buscar'), findsOneWidget);
    final busca = find.byType(BuscaScreen);
    expect(
      DefaultTabController.of(tester.element(find.byType(TabBar))).index,
      1,
    );
    expect(
      find.descendant(of: busca, matching: find.text('Ana Vieira')),
      findsOneWidget,
    );

    // Voltar do sistema fora do Início leva ao Início (não sai do app).
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Sua próxima oportunidade'), findsOneWidget);
  });

  testWidgets('menu da conta no Perfil: Sobre e Sair', (tester) async {
    await tester.pumpWidget(
      _app(
        servicoFake(firestore: firestore, uid: 'e1'),
        const PerfilScreen(),
        comLogin: true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();
    expect(find.text('Sobre'), findsOneWidget);
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(find.text('Tela login'), findsOneWidget);
  });
}
