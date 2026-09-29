import 'package:backstage/providers/auth_provider.dart';
import 'package:backstage/providers/perfil_provider.dart';
import 'package:backstage/screens/perfil/perfil_screen.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _estabelecimento = {
  'nome': 'Bar Central',
  'cidade': 'Franca',
  'logradouro': 'Rua A',
  'numero': '10',
  'estado': 'SP',
  'contato': '16 99999-9999',
};

/// Usuário `u1` logado com os documentos informados; [admin] liga a claim.
Future<(Widget, FakeFirebaseFirestore)> _app({
  String? tipoUsuario,
  Map<String, dynamic>? perfilMusico,
  Map<String, dynamic>? estabelecimento,
  bool admin = false,
}) async {
  final firestore = FakeFirebaseFirestore();
  await firestore.collection('usuarios').doc('u1').set({
    'nome': 'Musico Teste',
    'tipoUsuario': ?tipoUsuario,
  });
  if (perfilMusico != null) {
    await firestore.collection('perfis_musicos').doc('u1').set(perfilMusico);
  }
  if (estabelecimento != null) {
    await firestore.collection('estabelecimentos').doc('u1').set(estabelecimento);
  }
  final service = FirebaseDataService(
    auth: MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'u1',
        customClaim: admin ? {'admin': true} : null,
      ),
    ),
    firestore: firestore,
  );

  final app = MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider(service: service)),
      ChangeNotifierProvider(create: (_) => PerfilProvider(service: service)),
    ],
    child: const MaterialApp(home: PerfilScreen()),
  );
  return (app, firestore);
}

void main() {
  testWidgets('perfil de músico em branco abre a edição sem erro e salva', (tester) async {
    final (app, firestore) = await _app(
      tipoUsuario: 'musico',
      perfilMusico: {
        'nomeArtistico': 'Musico Teste',
        'generoMusical': '',
        'cidade': '',
        'descricao': '',
        'cacheMedio': 0,
        'portfolioLinks': [],
        'fotoPath': null,
      },
    );
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('Meu perfil'), findsOneWidget);
    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.enterText(find.widgetWithText(TextFormField, 'Cidade'), 'Franca');
    await tester.enterText(find.widgetWithText(TextFormField, 'Cachê médio'), '800');
    await tester.enterText(find.widgetWithText(TextFormField, 'Descrição'), 'Duo');
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rock').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Perfil atualizado com sucesso!'), findsOneWidget);
    expect(find.text('Editar perfil'), findsOneWidget);
    final doc = await firestore.collection('perfis_musicos').doc('u1').get();
    expect(doc.data()?['cidade'], 'Franca');
  });

  testWidgets('dono vê o perfil do estabelecimento, não o de artista', (tester) async {
    final (app, _) = await _app(
      tipoUsuario: 'casaShow',
      estabelecimento: _estabelecimento,
    );
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('Bar Central'), findsOneWidget);
    expect(find.textContaining('Rua A, 10'), findsOneWidget);
    expect(find.text('Perfil do artista'), findsNothing);
    expect(find.text('Artista'), findsNothing);
  });

  testWidgets('dono sem estabelecimento já vê o formulário', (tester) async {
    final (app, _) = await _app(tipoUsuario: 'casaShow');
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Nome do estabelecimento'), findsOneWidget);
    expect(find.text('Cancelar'), findsNothing);
  });

  testWidgets('admin vê abas de artista e estabelecimento', (tester) async {
    final (app, _) = await _app(admin: true, estabelecimento: _estabelecimento);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('Artista'), findsOneWidget);
    expect(find.text('Estabelecimento'), findsOneWidget);

    await tester.tap(find.text('Estabelecimento'));
    await tester.pumpAndSettle();
    expect(find.text('Bar Central'), findsOneWidget);
  });
}
