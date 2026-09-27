import 'package:backstage/providers/auth_provider.dart';
import 'package:backstage/routes/app_routes.dart';
import 'package:backstage/screens/auth/completar_perfil_screen.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _app(AuthProvider auth) {
  return ChangeNotifierProvider.value(
    value: auth,
    child: MaterialApp(
      initialRoute: AppRoutes.completarPerfil,
      routes: {
        AppRoutes.completarPerfil: (_) => const CompletarPerfilScreen(),
        AppRoutes.home: (_) => Scaffold(appBar: AppBar(), body: const Text('Tela Home')),
      },
    ),
  );
}

void main() {
  testWidgets('botão Continuar fica desabilitado sem seleção', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final auth = AuthProvider(
      service: FirebaseDataService(
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'u1', email: 'a@b.com'),
        ),
        firestore: firestore,
        enabled: true,
      ),
    );
    await tester.pumpWidget(_app(auth));

    final botao = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(botao.onPressed, isNull);
  });

  testWidgets('escolher músico salva tipoUsuario e navega para Home', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final auth = AuthProvider(
      service: FirebaseDataService(
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'u1', email: 'a@b.com'),
        ),
        firestore: firestore,
        enabled: true,
      ),
    );
    await tester.pumpWidget(_app(auth));

    await tester.tap(find.text('Músico'));
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Tela Home'), findsOneWidget);
    final doc = await firestore.collection('usuarios').doc('u1').get();
    expect(doc.data()?['tipoUsuario'], 'musico');
  });
}
