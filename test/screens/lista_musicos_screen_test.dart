import 'package:backstage/data/mock_data.dart';
import 'package:backstage/providers/auth_provider.dart';
import 'package:backstage/providers/interesse_provider.dart';
import 'package:backstage/providers/oportunidade_provider.dart';
import 'package:backstage/providers/perfil_provider.dart';
import 'package:backstage/routes/app_routes.dart';
import 'package:backstage/screens/busca/lista_musicos_screen.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Monta a tela com os providers que ela usa, todos sobre o mesmo [service]
/// (ou em modo mock, se [service] for nulo).
Widget _app({FirebaseDataService? service, void Function(OportunidadeProvider)? preparar}) {
  final oportunidades = OportunidadeProvider(service: service);
  preparar?.call(oportunidades);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider(service: service)),
      ChangeNotifierProvider(create: (_) => PerfilProvider(service: service)),
      ChangeNotifierProvider(create: (_) => InteresseProvider(service: service)),
      ChangeNotifierProvider.value(value: oportunidades),
    ],
    child: MaterialApp(
      home: const ListaMusicosScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.detalheMusico) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(body: Text('Detalhe ${settings.arguments}')),
          );
        }
        return null;
      },
    ),
  );
}

/// Dono de estabelecimento logado (`e1`) num Firestore fake.
Future<FirebaseDataService> _donoLogado() async {
  final firestore = FakeFirebaseFirestore();
  await firestore.collection('usuarios').doc('e1').set({
    'nome': 'Bar Central',
    'tipoUsuario': 'casaShow',
  });
  return FirebaseDataService(
    auth: MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'e1', email: 'bar@backstage.com'),
    ),
    firestore: firestore,
    enabled: true,
  );
}

void main() {
  testWidgets('lista os músicos do provider', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    for (final musico in MockData.musicos) {
      expect(find.text(musico.nomeArtistico), findsOneWidget);
    }
  });

  testWidgets('mostra mensagem quando o filtro não encontra ninguém', (tester) async {
    await tester.pumpWidget(_app(preparar: (p) => p.pesquisarMusicos('inexistente')));
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhum músico encontrado com os filtros informados.'),
      findsOneWidget,
    );
  });

  testWidgets('quem não é dono não vê o botão Convidar', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Convidar'), findsNothing);
    expect(find.text('Ver detalhes'), findsWidgets);
  });

  testWidgets('dono convida: confirma no diálogo e o card mostra o status', (tester) async {
    final service = await _donoLogado();
    await tester.pumpWidget(
      _app(service: service, preparar: (p) => p.pesquisarMusicos('Eclipse')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Convidar'));
    await tester.pumpAndSettle();
    expect(find.text('Convidar "Banda Eclipse"?'), findsOneWidget);

    await tester.tap(find.text('Enviar convite'));
    await tester.pumpAndSettle();

    expect(find.text('Convite enviado!'), findsOneWidget);
    expect(find.text('Convite enviado'), findsOneWidget);
    final doc = await service.firestore.collection('interesses').doc('e1_mu_1').get();
    expect(doc.data()?['remetenteNome'], 'Bar Central');
  });

  testWidgets('cancelar o diálogo não envia convite', (tester) async {
    final service = await _donoLogado();
    await tester.pumpWidget(
      _app(service: service, preparar: (p) => p.pesquisarMusicos('Eclipse')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Convidar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Convidar'), findsOneWidget);
    final docs = await service.firestore.collection('interesses').get();
    expect(docs.docs, isEmpty);
  });

  testWidgets('Ver detalhes navega passando o id do músico', (tester) async {
    await tester.pumpWidget(_app(preparar: (p) => p.pesquisarMusicos('Eclipse')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver detalhes'));
    await tester.pumpAndSettle();

    expect(find.text('Detalhe 1'), findsOneWidget);
  });
}
