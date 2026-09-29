import 'package:backstage/providers/auth_provider.dart';
import 'package:backstage/providers/perfil_provider.dart';
import 'package:backstage/routes/app_routes.dart';
import 'package:backstage/screens/auth/completar_perfil_screen.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

FirebaseDataService _service(FakeFirebaseFirestore firestore) {
  return FirebaseDataService(
    auth: MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'u1', email: 'a@b.com'),
    ),
    firestore: firestore,
    enabled: true,
  );
}

Widget _app(FirebaseDataService service, AuthProvider auth) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider(create: (_) => PerfilProvider(service: service)),
    ],
    child: MaterialApp(
      initialRoute: AppRoutes.completarPerfil,
      routes: {
        AppRoutes.completarPerfil: (_) => const CompletarPerfilScreen(),
        AppRoutes.home: (_) =>
            Scaffold(appBar: AppBar(), body: const Text('Tela Home')),
      },
    ),
  );
}

Future<void> _preencher(WidgetTester tester, String rotulo, String texto) async {
  final campo = find.widgetWithText(TextFormField, rotulo);
  await tester.ensureVisible(campo);
  await tester.enterText(campo, texto);
}

Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  // O campo focado rola a tela de volta até ele; tira o foco antes.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('botão Continuar fica desabilitado sem seleção', (tester) async {
    final service = _service(FakeFirebaseFirestore());
    await tester.pumpWidget(_app(service, AuthProvider(service: service)));
    await tester.pumpAndSettle();

    final botao = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(botao.onPressed, isNull);
  });

  testWidgets('músico: passo 1 salva o tipo e o passo 2 grava o perfil antes da Home', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('usuarios').doc('u1').set({'nome': 'Guilherme'});
    final service = _service(firestore);
    await tester.pumpWidget(_app(service, AuthProvider(service: service)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Músico'));
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Passo 2: ainda não foi para a Home.
    expect(find.text('Tela Home'), findsNothing);
    expect(find.text('Seu perfil (2/2)'), findsOneWidget);
    final usuario = await firestore.collection('usuarios').doc('u1').get();
    expect(usuario.data()?['tipoUsuario'], 'musico');

    // Nome artístico vem pré-preenchido com o nome da conta.
    expect(find.widgetWithText(TextFormField, 'Guilherme'), findsOneWidget);

    await _preencher(tester, 'Cidade', 'Franca');
    await _preencher(tester, 'Cachê médio', '1500');
    await _preencher(tester, 'Descrição', 'Duo acústico');
    await _tocar(tester, find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.text('Rock').last);
    await tester.pumpAndSettle();
    await _tocar(tester, find.text('Concluir'));

    expect(find.text('Tela Home'), findsOneWidget);
    final perfil = await firestore.collection('perfis_musicos').doc('u1').get();
    expect(perfil.data()?['nomeArtistico'], 'Guilherme');
    expect(perfil.data()?['generoMusical'], 'Rock');
  });

  testWidgets('formulário incompleto não sai do passo 2', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('usuarios').doc('u1').set({'tipoUsuario': 'casaShow'});
    final service = _service(firestore);
    final auth = AuthProvider(service: service);
    await tester.pumpWidget(_app(service, auth));
    await tester.pumpAndSettle();

    await _tocar(tester, find.text('Concluir'));

    expect(find.text('Tela Home'), findsNothing);
    expect(find.text('Informe o nome.'), findsOneWidget);
  });

  testWidgets('dono com tipo já definido retoma no passo 2 com os dados salvos', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('usuarios').doc('u1').set({'tipoUsuario': 'casaShow'});
    // Perfil parcial: falta o endereço.
    await firestore.collection('estabelecimentos').doc('u1').set({
      'nome': 'Bar Central',
      'cidade': 'Franca',
      'contato': '16 99999-9999',
    });
    final service = _service(firestore);
    final auth = AuthProvider(service: service);
    await tester.pumpWidget(_app(service, auth));
    await tester.pumpAndSettle();

    expect(find.text('Seu perfil (2/2)'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Bar Central'), findsOneWidget);

    await _preencher(tester, 'Logradouro', 'Rua A');
    await _preencher(tester, 'Número', '10');
    await _preencher(tester, 'UF', 'sp');
    await _tocar(tester, find.text('Concluir'));

    expect(find.text('Tela Home'), findsOneWidget);
    final doc = await firestore.collection('estabelecimentos').doc('u1').get();
    expect(doc.data()?['estado'], 'SP');
    expect(doc.data()?['nome'], 'Bar Central');
    expect(await auth.precisaCompletarPerfil(), isFalse);
  });
}
