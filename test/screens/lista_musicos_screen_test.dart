import 'package:backstage/providers/agenda_provider.dart';
import 'package:backstage/providers/auth_provider.dart';
import 'package:backstage/providers/interesse_provider.dart';
import 'package:backstage/providers/oportunidade_provider.dart';
import 'package:backstage/providers/perfil_provider.dart';
import 'package:backstage/routes/app_routes.dart';
import 'package:backstage/screens/busca/lista_musicos_screen.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/firebase_fake.dart';

final _catalogo = [
  musicoTeste(id: '1', nomeArtistico: 'Banda Eclipse', cacheMedio: 1500),
  musicoTeste(id: '2', nomeArtistico: 'Duo Acústico Sol', generoMusical: 'MPB'),
  musicoTeste(id: '3', nomeArtistico: 'DJ Pulse', generoMusical: 'Eletrônica'),
];

/// Monta a tela com os providers que ela usa, todos sobre o mesmo [service].
Widget _app({
  required FirebaseDataService service,
  void Function(OportunidadeProvider)? preparar,
}) {
  final oportunidades = OportunidadeProvider(service: service);
  preparar?.call(oportunidades);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider(service: service)),
      ChangeNotifierProvider(create: (_) => AgendaProvider(service: service)),
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

/// Usuário [uid] logado num Firestore fake com o catálogo de músicos;
/// [tipoUsuario] nulo = onboarding pendente (sem papel).
Future<FirebaseDataService> _logado({
  String uid = 'u1',
  String nome = 'Visitante',
  String? tipoUsuario,
}) async {
  final firestore = FakeFirebaseFirestore();
  await gravarCatalogo(firestore, musicos: _catalogo);
  await firestore.collection('usuarios').doc(uid).set({
    'nome': nome,
    'tipoUsuario': ?tipoUsuario,
  });
  return servicoFake(firestore: firestore, uid: uid);
}

/// Dono de estabelecimento logado (`e1`).
Future<FirebaseDataService> _donoLogado() =>
    _logado(uid: 'e1', nome: 'Bar Central', tipoUsuario: 'casaShow');

void main() {
  testWidgets('lista os músicos do provider', (tester) async {
    await tester.pumpWidget(_app(service: await _logado()));
    await tester.pumpAndSettle();

    for (final musico in _catalogo) {
      expect(find.text(musico.nomeArtistico), findsOneWidget);
    }
  });

  testWidgets('mostra mensagem quando o filtro não encontra ninguém', (tester) async {
    await tester.pumpWidget(
      _app(
        service: await _logado(),
        preparar: (p) => p.pesquisarMusicos('inexistente'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhum músico encontrado com os filtros informados.'),
      findsOneWidget,
    );
  });

  testWidgets('quem não é dono não vê o botão Convidar', (tester) async {
    await tester.pumpWidget(
      _app(service: await _logado(tipoUsuario: 'musico')),
    );
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
    // O diálogo espera a leitura da agenda pública do músico (stream).
    await tester.pump(const Duration(milliseconds: 100));
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
    // O diálogo espera a leitura da agenda pública do músico (stream).
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Convidar'), findsOneWidget);
    final docs = await service.firestore.collection('interesses').get();
    expect(docs.docs, isEmpty);
  });

  testWidgets('Ver detalhes navega passando o id do músico', (tester) async {
    await tester.pumpWidget(
      _app(
        service: await _logado(),
        preparar: (p) => p.pesquisarMusicos('Eclipse'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver detalhes'));
    await tester.pumpAndSettle();

    expect(find.text('Detalhe 1'), findsOneWidget);
  });
}
