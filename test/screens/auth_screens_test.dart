import 'package:backstage/core/theme/app_theme.dart';
import 'package:backstage/providers/auth_provider.dart';
import 'package:backstage/routes/app_routes.dart';
import 'package:backstage/screens/auth/cadastro_screen.dart';
import 'package:backstage/screens/auth/login_screen.dart';
import 'package:backstage/screens/auth/recuperar_senha_screen.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/firebase_fake.dart';

/// Plano 8, Fase 4: cadastro, recuperar senha e campo de senha.

class _ServicoRecuperacaoFalha extends FirebaseDataService {
  _ServicoRecuperacaoFalha()
    : super(auth: MockFirebaseAuth(), firestore: FakeFirebaseFirestore());

  @override
  Future<void> recuperarSenha(String email) =>
      Future.error(FirebaseAuthException(code: 'invalid-email'));
}

/// [tela] aberta por cima de uma tela de login falsa (para testar o voltar).
Widget _app(FirebaseDataService service, Widget tela) {
  return ChangeNotifierProvider(
    create: (_) => AuthProvider(service: service),
    child: MaterialApp(
      theme: AppTheme.escuro,
      initialRoute: '/tela',
      routes: {
        AppRoutes.login: (_) => const Scaffold(body: Text('Tela login')),
        '/tela': (_) => tela,
      },
    ),
  );
}

void main() {
  group('Cadastro', () {
    testWidgets('senhas diferentes avisam no próprio campo', (tester) async {
      await tester.pumpWidget(
        _app(servicoFake(uid: null), const CadastroScreen()),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Senha'),
        '123456',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar senha'),
        '654321',
      );
      final criar = find.widgetWithText(ElevatedButton, 'Criar conta');
      await tester.ensureVisible(criar);
      await tester.tap(criar);
      await tester.pump();

      expect(find.text('As senhas não coincidem.'), findsOneWidget);
      expect(find.text('Informe o nome.'), findsOneWidget);
    });

    testWidgets('"Já tem conta? Entrar" volta para o login', (tester) async {
      await tester.pumpWidget(
        _app(servicoFake(uid: null), const CadastroScreen()),
      );

      final entrar = find.widgetWithText(TextButton, 'Entrar');
      await tester.ensureVisible(entrar);
      await tester.tap(entrar);
      await tester.pumpAndSettle();

      expect(find.text('Tela login'), findsOneWidget);
    });
  });

  group('Recuperar senha', () {
    testWidgets('confirma na própria tela e volta ao login', (tester) async {
      await tester.pumpWidget(
        _app(servicoFake(uid: null), const RecuperarSenhaScreen()),
      );

      await tester.enterText(find.byType(TextFormField), 'ana@email.com');
      await tester.tap(find.text('Enviar link'));
      await tester.pumpAndSettle();

      expect(find.text('Verifique seu e-mail'), findsOneWidget);
      expect(find.textContaining('ana@email.com'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);

      await tester.tap(find.text('Voltar ao login'));
      await tester.pumpAndSettle();
      expect(find.text('Tela login'), findsOneWidget);
    });

    testWidgets('falha mostra o erro em PT-BR', (tester) async {
      await tester.pumpWidget(
        _app(_ServicoRecuperacaoFalha(), const RecuperarSenhaScreen()),
      );

      await tester.enterText(find.byType(TextFormField), 'ana@email.com');
      await tester.tap(find.text('Enviar link'));
      await tester.pumpAndSettle();

      expect(find.text('E-mail inválido.'), findsOneWidget);
      expect(find.text('Verifique seu e-mail'), findsNothing);
    });
  });

  testWidgets('senha começa oculta e o olho mostra/oculta', (tester) async {
    await tester.pumpWidget(_app(servicoFake(uid: null), const LoginScreen()));

    EditableText campoSenha() => tester.widget<EditableText>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Senha'),
        matching: find.byType(EditableText),
      ),
    );

    expect(campoSenha().obscureText, isTrue);
    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pump();
    expect(campoSenha().obscureText, isFalse);
    await tester.tap(find.byTooltip('Ocultar senha'));
    await tester.pump();
    expect(campoSenha().obscureText, isTrue);
  });

  testWidgets('login cabe em celular pequeno com teclado aberto', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    // Teclado ocupando quase metade da tela.
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(servicoFake(uid: null), const LoginScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Criar conta'));
    expect(find.text('Criar conta'), findsOneWidget);
  });

  testWidgets('cadastro em celular pequeno: título não fica sob o voltar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(servicoFake(uid: null), const CadastroScreen()),
    );
    await tester.pumpAndSettle();

    final fimDoAppBar = tester.getBottomLeft(find.byType(AppBar)).dy;
    expect(
      // O título "Criar conta" (o botão de mesmo texto vem depois).
      tester.getTopLeft(find.text('Criar conta').first).dy,
      greaterThanOrEqualTo(fimDoAppBar),
    );
  });
}
