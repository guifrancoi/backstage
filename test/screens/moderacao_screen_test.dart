import 'package:backstage/providers/agenda_provider.dart';
import 'package:backstage/providers/auth_provider.dart';
import 'package:backstage/providers/avaliacao_provider.dart';
import 'package:backstage/providers/denuncia_provider.dart';
import 'package:backstage/providers/interesse_provider.dart';
import 'package:backstage/providers/oportunidade_provider.dart';
import 'package:backstage/providers/perfil_provider.dart';
import 'package:backstage/screens/busca/detalhe_musico_screen.dart';
import 'package:backstage/screens/moderacao/bloqueados_screen.dart';
import 'package:backstage/screens/moderacao/denuncias_screen.dart';
import 'package:backstage/services/firebase_data_service.dart';
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
      ChangeNotifierProvider(create: (_) => OportunidadeProvider(service: service)),
      ChangeNotifierProvider(create: (_) => InteresseProvider(service: service)),
      ChangeNotifierProvider(create: (_) => AgendaProvider(service: service)),
      ChangeNotifierProvider(create: (_) => AvaliacaoProvider(service: service)),
      ChangeNotifierProvider(create: (_) => DenunciaProvider(service: service)),
    ],
    child: MaterialApp(home: home),
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
      musicos: [musicoTeste(id: 'm1', nomeArtistico: 'Banda Eclipse')],
    );
  });

  Future<void> abrirMenu(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();
  }

  testWidgets('dono bloqueia pelo menu: aviso aparece e Convidar some', (tester) async {
    // Tela alta: o Convidar fica no fim do detalhe.
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'e1'), const DetalheMusicoScreen(musicoId: 'm1')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Convidar'), findsOneWidget);

    await abrirMenu(tester);
    await tester.tap(find.text('Bloquear Banda Eclipse'));
    await tester.pumpAndSettle();
    expect(find.text('Bloquear Banda Eclipse?'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Bloquear'));
    await tester.pumpAndSettle();

    expect(find.text('Você bloqueou Banda Eclipse.'), findsOneWidget);
    expect(find.textContaining('Convidar'), findsNothing);
    final doc = await firestore.doc('usuarios/e1/bloqueados/m1').get();
    expect(doc.data()?['nome'], 'Banda Eclipse');

    // Desbloquear pelo aviso.
    await tester.tap(find.text('Desbloquear'));
    await tester.pumpAndSettle();
    expect(find.text('Você bloqueou Banda Eclipse.'), findsNothing);
  });

  testWidgets('denunciar perfil: escolhe o motivo e envia', (tester) async {
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'e1'), const DetalheMusicoScreen(musicoId: 'm1')),
    );
    await tester.pumpAndSettle();

    await abrirMenu(tester);
    await tester.tap(find.text('Denunciar perfil'));
    await tester.pumpAndSettle();
    final enviar = find.widgetWithText(ElevatedButton, 'Enviar denúncia');
    expect(tester.widget<ElevatedButton>(enviar).onPressed, isNull); // sem motivo
    await tester.tap(find.text('Perfil falso'));
    await tester.enterText(find.widgetWithText(TextField, 'Detalhes (opcional)'), 'Fotos de outra banda');
    await tester.pumpAndSettle();
    await tester.tap(enviar);
    await tester.pumpAndSettle();

    expect(find.text('Denúncia enviada. Obrigado por avisar.'), findsOneWidget);
    final denuncias = await firestore.collection('denuncias').get();
    final d = denuncias.docs.single.data();
    expect(d['tipoAlvo'], 'perfil');
    expect(d['alvoUid'], 'm1');
    expect(d['motivo'], 'perfilFalso');
    expect(d['autorId'], 'e1');
  });

  testWidgets('o próprio músico não vê o menu no seu perfil', (tester) async {
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'm1'), const DetalheMusicoScreen(musicoId: 'm1')),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Mais opções'), findsNothing);
  });

  testWidgets('lista de bloqueados e desbloquear', (tester) async {
    await firestore.doc('usuarios/e1/bloqueados/m1').set({
      'nome': 'Banda Eclipse',
      'criadoEm': DateTime(2026, 10, 1),
    });
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'e1'), const BloqueadosScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Banda Eclipse'), findsOneWidget);
    expect(find.text('Bloqueado em 01/10/2026'), findsOneWidget);
    await tester.tap(find.text('Desbloquear'));
    await tester.pumpAndSettle();

    expect(find.text('Você não bloqueou ninguém.'), findsOneWidget);
  });

  testWidgets('admin vê denúncias pendentes e marca como analisada', (tester) async {
    await firestore.collection('denuncias').doc('d1').set({
      'autorId': 'm1',
      'autorNome': 'Banda',
      'tipoAlvo': 'mensagem',
      'alvoId': 'x',
      'alvoUid': 'e1',
      'descricaoAlvo': 'Me paga por fora',
      'motivo': 'golpe',
      'texto': '',
      'status': 'pendente',
      'criadaEm': DateTime(2026, 10, 2),
    });
    await tester.pumpWidget(
      _app(
        servicoFake(firestore: firestore, uid: 'adm', admin: true),
        const DenunciasScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pendentes (1)'), findsOneWidget);
    expect(find.text('Mensagem · Golpe ou fraude'), findsOneWidget);
    expect(find.text('"Me paga por fora"'), findsOneWidget);
    await tester.tap(find.text('Marcar como analisada'));
    await tester.pumpAndSettle();

    expect(find.text('Pendentes (0)'), findsOneWidget);
    expect((await firestore.doc('denuncias/d1').get()).data()?['status'], 'analisada');
    await tester.tap(find.text('Analisadas'));
    await tester.pumpAndSettle();
    expect(find.text('Mensagem · Golpe ou fraude'), findsOneWidget);
  });
}
