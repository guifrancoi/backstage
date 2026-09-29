import 'package:backstage/providers/auth_provider.dart';
import 'package:backstage/routes/app_routes.dart';
import 'package:backstage/screens/auth/login_screen.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Monta só a LoginScreen com o AuthProvider informado e rotas de destino
/// simples, sem DevicePreview nem as demais telas do app.
Widget _app(AuthProvider auth) {
  return ChangeNotifierProvider.value(
    value: auth,
    child: MaterialApp(
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.home: (_) => _destino('Tela Home'),
        AppRoutes.cadastro: (_) => _destino('Tela Cadastro'),
        AppRoutes.recuperarSenha: (_) => _destino('Tela Recuperar Senha'),
        AppRoutes.completarPerfil: (_) => _destino('Tela Completar Perfil'),
      },
    ),
  );
}

/// Tela de destino com AppBar (necessária para o botão voltar do pageBack).
Widget _destino(String texto) =>
    Scaffold(appBar: AppBar(), body: Text(texto));

Future<void> _preencher(WidgetTester tester, {required String email, required String senha}) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'E-mail'), email);
  await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), senha);
}

void main() {
  testWidgets('valida campos vazios sem chamar o login', (tester) async {
    await tester.pumpWidget(_app(AuthProvider()));

    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Informe o e-mail.'), findsOneWidget);
    expect(find.text('Informe a senha.'), findsOneWidget);
  });

  testWidgets('valida formato do e-mail e tamanho da senha', (tester) async {
    await tester.pumpWidget(_app(AuthProvider()));

    await _preencher(tester, email: 'invalido', senha: '123');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(find.text('A senha deve ter ao menos 6 caracteres.'), findsOneWidget);
  });

  testWidgets('modo mock: mostra "Entrando..." e depois o diálogo de erro', (tester) async {
    await tester.pumpWidget(_app(AuthProvider()));

    await _preencher(tester, email: 'a@b.com', senha: '123456');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Entrando...'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Erro'), findsOneWidget);
    expect(find.textContaining('Falha na conexão'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Erro'), findsNothing);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('login com Firebase (fake) e perfil completo navega para a Home', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('usuarios').doc('u1').set({'tipoUsuario': 'musico'});
    await firestore.collection('perfis_musicos').doc('u1').set({
      'nomeArtistico': 'Banda',
      'generoMusical': 'Rock',
      'cidade': 'Franca',
      'descricao': 'Banda de rock',
      'cacheMedio': 1000,
    });
    final auth = AuthProvider(
      service: FirebaseDataService(
        auth: MockFirebaseAuth(mockUser: MockUser(uid: 'u1', email: 'a@b.com')),
        firestore: firestore,
        enabled: true,
      ),
    );
    await tester.pumpWidget(_app(auth));

    await _preencher(tester, email: 'a@b.com', senha: '123456');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Tela Home'), findsOneWidget);
    expect(auth.isLoggedIn, isTrue);
  });

  testWidgets('login com tipoUsuario mas perfil em branco volta ao onboarding', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('usuarios').doc('u1').set({'tipoUsuario': 'musico'});
    await firestore.collection('perfis_musicos').doc('u1').set({
      'nomeArtistico': 'Musico Teste',
      'generoMusical': '',
    });
    final auth = AuthProvider(
      service: FirebaseDataService(
        auth: MockFirebaseAuth(mockUser: MockUser(uid: 'u1', email: 'a@b.com')),
        firestore: firestore,
        enabled: true,
      ),
    );
    await tester.pumpWidget(_app(auth));

    await _preencher(tester, email: 'a@b.com', senha: '123456');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Tela Completar Perfil'), findsOneWidget);
  });

  testWidgets('login com Firebase (fake) sem tipoUsuario navega para completar perfil', (tester) async {
    final auth = AuthProvider(
      service: FirebaseDataService(
        auth: MockFirebaseAuth(mockUser: MockUser(uid: 'u1', email: 'a@b.com')),
        firestore: FakeFirebaseFirestore(),
        enabled: true,
      ),
    );
    await tester.pumpWidget(_app(auth));

    await _preencher(tester, email: 'a@b.com', senha: '123456');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Tela Completar Perfil'), findsOneWidget);
  });

  testWidgets('links abrem cadastro e recuperação de senha', (tester) async {
    await tester.pumpWidget(_app(AuthProvider()));

    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    expect(find.text('Tela Cadastro'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Esqueceu a senha?'));
    await tester.pumpAndSettle();
    expect(find.text('Tela Recuperar Senha'), findsOneWidget);
  });
}
