import 'package:backstage/providers/agenda_provider.dart';
import 'package:backstage/providers/auth_provider.dart';
import 'package:backstage/providers/interesse_provider.dart';
import 'package:backstage/providers/oportunidade_provider.dart';
import 'package:backstage/providers/perfil_provider.dart';
import 'package:backstage/routes/app_routes.dart';
import 'package:backstage/screens/busca/detalhe_oportunidade_screen.dart';
import 'package:backstage/screens/busca/lista_oportunidades_screen.dart';
import 'package:backstage/screens/oportunidades/minhas_oportunidades_screen.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:backstage/services/location_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/firebase_fake.dart';

Widget _app(FirebaseDataService service, Widget home) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider(service: service)),
      ChangeNotifierProvider(create: (_) => PerfilProvider(service: service)),
      ChangeNotifierProvider(create: (_) => InteresseProvider(service: service)),
      ChangeNotifierProvider(create: (_) => OportunidadeProvider(service: service)),
      ChangeNotifierProvider(create: (_) => AgendaProvider(service: service)),
      Provider<LocationService>(
        create: (_) => LocationService(),
        dispose: (_, s) => s.dispose(),
      ),
    ],
    child: MaterialApp(
      home: home,
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
  final ontem = DateTime.now().subtract(const Duration(days: 1));

  /// Músico m1 e dono e1; oportunidades de e1: duas futuras e uma vencida.
  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('usuarios').doc('m1').set({'tipoUsuario': 'musico'});
    await firestore.collection('usuarios').doc('e1').set({'tipoUsuario': 'casaShow'});
    await gravarCatalogo(
      firestore,
      oportunidades: [
        oportunidadeTeste(id: 'rock', titulo: 'Noite do rock', donoId: 'e1')
            .copyWith(dataEvento: DateTime(2099, 3, 1)),
        oportunidadeTeste(
          id: 'mpb',
          titulo: 'Sarau MPB',
          generoMusical: 'MPB',
          donoId: 'e1',
        ).copyWith(dataEvento: DateTime(2099, 3, 2)),
        oportunidadeTeste(id: 'velha', titulo: 'Show de ontem', donoId: 'e1')
            .copyWith(dataEvento: ontem),
      ],
    );
  });

  Future<void> escolherGenero(WidgetTester tester, String genero) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(genero).last);
    await tester.pumpAndSettle();
  }

  testWidgets('lista só as futuras; filtrar por gênero vira chip removível', (tester) async {
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'm1'), const ListaOportunidadesScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 oportunidades'), findsOneWidget);
    expect(find.text('Show de ontem'), findsNothing);

    await tester.tap(find.text('Filtrar'));
    await tester.pumpAndSettle();
    // Músico vê as opções que dependem da agenda dele.
    expect(find.text('Só dias em que estou livre'), findsOneWidget);
    await escolherGenero(tester, 'MPB');
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(find.text('Filtrar (1)'), findsOneWidget);
    expect(find.text('1 oportunidade'), findsOneWidget);
    expect(find.text('Sarau MPB'), findsOneWidget);
    expect(find.text('Noite do rock'), findsNothing);

    // Remover o chip desliga o critério.
    final chip = tester.widget<InputChip>(find.widgetWithText(InputChip, 'MPB'));
    chip.onDeleted!();
    await tester.pumpAndSettle();
    expect(find.text('2 oportunidades'), findsOneWidget);
    expect(find.text('Filtrar'), findsOneWidget);
  });

  testWidgets('sem resultado mostra aviso; "Limpar" volta à lista completa', (tester) async {
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'm1'), const ListaOportunidadesScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Filtrar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Cachê mínimo (R\$)'), '99999');
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma oportunidade com esses filtros.'), findsOneWidget);
    expect(find.text('A partir de R\$ 99999'), findsOneWidget);

    await tester.tap(find.text('Limpar'));
    await tester.pumpAndSettle();
    expect(find.text('2 oportunidades'), findsOneWidget);
  });

  testWidgets('dono não vê as opções de agenda no painel', (tester) async {
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'e1'), const ListaOportunidadesScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Filtrar'));
    await tester.pumpAndSettle();

    expect(find.text('Só dias em que estou livre'), findsNothing);
  });

  testWidgets('Minhas oportunidades separa próximas e encerradas', (tester) async {
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'e1'), const MinhasOportunidadesScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Próximas'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Encerradas'), 200);
    expect(find.text('Encerradas'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Show de ontem'), 200);
    expect(find.text('Show de ontem'), findsOneWidget);
  });

  testWidgets('detalhe de oportunidade vencida: sem candidatura e com aviso', (tester) async {
    await tester.pumpWidget(
      _app(
        servicoFake(firestore: firestore, uid: 'm1'),
        const DetalheOportunidadeScreen(oportunidadeId: 'velha'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Evento encerrado'), findsOneWidget);
    expect(find.text('Candidatar-se'), findsNothing);
  });

  testWidgets('detalhe de oportunidade futura: músico pode se candidatar', (tester) async {
    await tester.pumpWidget(
      _app(
        servicoFake(firestore: firestore, uid: 'm1'),
        const DetalheOportunidadeScreen(oportunidadeId: 'rock'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Evento encerrado'), findsNothing);
    expect(find.text('Candidatar-se'), findsOneWidget);
    expect(find.text('Ver músicos livres neste dia'), findsNothing);
  });

  testWidgets('dono abre os músicos livres no dia da oportunidade (Plano 13)', (tester) async {
    await tester.pumpWidget(
      _app(
        servicoFake(firestore: firestore, uid: 'e1'),
        const DetalheOportunidadeScreen(oportunidadeId: 'rock'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Ver músicos livres neste dia'));
    await tester.tap(find.text('Ver músicos livres neste dia'));
    await tester.pumpAndSettle();

    expect(find.text('${AppRoutes.listaMusicos} null'), findsOneWidget);
    final provider = Provider.of<OportunidadeProvider>(
      tester.element(find.text('${AppRoutes.listaMusicos} null')),
      listen: false,
    );
    expect(provider.livresEm, DateTime(2099, 3, 1));
  });

  testWidgets('dono vê músicos sugeridos e convida já nesta oportunidade (Plano 15)', (tester) async {
    await gravarCatalogo(
      firestore,
      musicos: [
        musicoTeste(id: 'm2', nomeArtistico: 'Banda Compatível'),
        musicoTeste(id: 'm3', nomeArtistico: 'Banda Ocupada'),
        musicoTeste(
          id: 'm4',
          nomeArtistico: 'Duo Distante',
          generoMusical: 'MPB',
          cidade: 'Outra',
        ),
      ],
    );
    await firestore.collection('ocupacoes').doc('m3_2099-03-01').set({
      'musicoId': 'm3',
      'dia': '2099-03-01',
      'contratacaoId': 'c1',
    });
    await tester.pumpWidget(
      _app(
        servicoFake(firestore: firestore, uid: 'e1'),
        const DetalheOportunidadeScreen(oportunidadeId: 'rock'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Músicos sugeridos'), findsOneWidget);
    expect(find.text('Banda Compatível'), findsOneWidget);
    expect(find.text('Banda Ocupada'), findsNothing);
    expect(find.text('Duo Distante'), findsNothing);
    expect(find.textContaining('Compatibilidade'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Convidar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Convidar'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    // A oportunidade já vem marcada: é só enviar.
    await tester.tap(find.text('Enviar convite'));
    await tester.pumpAndSettle();

    final convite = await firestore.collection('interesses').doc('e1_mu_m2_rock').get();
    expect(convite.exists, isTrue);
    // Com convite enviado, sai das sugestões.
    expect(find.text('Banda Compatível'), findsNothing);
  });

  testWidgets('oportunidade vencida não oferece músicos livres', (tester) async {
    await tester.pumpWidget(
      _app(
        servicoFake(firestore: firestore, uid: 'e1'),
        const DetalheOportunidadeScreen(oportunidadeId: 'velha'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ver músicos livres neste dia'), findsNothing);
  });
}
