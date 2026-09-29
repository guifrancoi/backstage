import 'package:backstage/models/interesse.dart';
import 'package:backstage/providers/auth_provider.dart';
import 'package:backstage/providers/contratacao_provider.dart';
import 'package:backstage/providers/interesse_provider.dart';
import 'package:backstage/routes/app_routes.dart';
import 'package:backstage/screens/interesses/interesses_screen.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _app(FirebaseDataService service) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider(service: service)),
      ChangeNotifierProvider(create: (_) => InteresseProvider(service: service)),
      ChangeNotifierProvider(create: (_) => ContratacaoProvider(service: service)),
    ],
    child: MaterialApp(
      home: const InteressesScreen(),
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
  late FirebaseDataService service;

  /// Dono `e1` logado com uma candidatura pendente de `m1`.
  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('usuarios').doc('e1').set({
      'nome': 'Bar Central',
      'tipoUsuario': 'casaShow',
    });
    await firestore
        .collection('interesses')
        .doc('m1_op_o1')
        .set(
          Interesse(
            id: 'm1_op_o1',
            tipo: TipoInteresse.candidatura,
            remetenteId: 'm1',
            remetenteNome: 'Guilherme',
            destinatarioId: 'e1',
            musicoId: 'm1',
            musicoNome: 'The VooDooS',
            oportunidadeId: 'o1',
            oportunidadeTitulo: 'Show de sexta',
            criadoEm: DateTime(2026, 9, 28),
          ).toMap(),
        );
    service = FirebaseDataService(
      auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'e1')),
      firestore: firestore,
    );
  });

  testWidgets('mostra a candidatura recebida com contador na aba', (tester) async {
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('Recebidos (1)'), findsOneWidget);
    // Mostra também o nome da conta: nome artístico pode repetir entre contas.
    expect(
      find.text('The VooDooS (Guilherme) quer tocar para "Show de sexta"'),
      findsOneWidget,
    );
    expect(find.text('Aceitar'), findsOneWidget);
    expect(find.text('Recusar'), findsOneWidget);
  });

  testWidgets('aceitar abre a conversa', (tester) async {
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aceitar'));
    await tester.pumpAndSettle();

    expect(find.text('${AppRoutes.chat} m1_op_o1'), findsOneWidget);
    final interesse = await firestore.collection('interesses').doc('m1_op_o1').get();
    expect(interesse.data()?['status'], 'aceito');
  });

  testWidgets('recusar atualiza o card e zera o contador', (tester) async {
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Recusar'));
    await tester.pumpAndSettle();

    expect(find.text('Interesse recusado.'), findsOneWidget);
    expect(find.text('Recebidos'), findsOneWidget);
    expect(find.text('Aceitar'), findsNothing);
    expect(find.textContaining('Recusado'), findsOneWidget);
  });

  testWidgets('aba Enviados vazia mostra aviso', (tester) async {
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enviados'));
    await tester.pumpAndSettle();

    expect(
      find.text('Você ainda não enviou candidaturas ou convites.'),
      findsOneWidget,
    );
  });
}
