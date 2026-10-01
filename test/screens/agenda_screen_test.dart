import 'package:backstage/models/contratacao.dart';
import 'package:backstage/providers/agenda_provider.dart';
import 'package:backstage/providers/auth_provider.dart';
import 'package:backstage/providers/contratacao_provider.dart';
import 'package:backstage/screens/agenda/agenda_screen.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../helpers/firebase_fake.dart';

Widget _app(FirebaseDataService service) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider(service: service)),
      ChangeNotifierProvider(create: (_) => AgendaProvider(service: service)),
      ChangeNotifierProvider(create: (_) => ContratacaoProvider(service: service)),
    ],
    child: const MaterialApp(home: AgendaScreen()),
  );
}

void main() {
  late FakeFirebaseFirestore firestore;
  final hoje = Contratacao.diaDe(DateTime.now());

  setUpAll(() => initializeDateFormatting('pt_BR'));

  /// Músico m1 e dono e1, com um show confirmado hoje entre eles.
  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('usuarios').doc('m1').set({'tipoUsuario': 'musico'});
    await firestore.collection('usuarios').doc('e1').set({'tipoUsuario': 'casaShow'});
    await firestore.collection('contratacoes').doc('c1').set(
      Contratacao(
        id: 'c1',
        interesseId: 'i1',
        musicoId: 'm1',
        musicoNome: 'Banda',
        donoId: 'e1',
        donoNome: 'Bar Central',
        titulo: 'Show de sexta',
        dia: hoje,
        horaInicio: '21:00',
        horaFim: '23:30',
        cacheAcordado: 1200,
        logradouro: 'Rua A',
        numero: '10',
        cidade: 'Franca',
        estado: 'SP',
        criadoEm: DateTime(2026, 9, 29),
        status: StatusContratacao.confirmada,
      ).toMap(),
    );
  });

  testWidgets('músico vê o calendário, o show do dia e bloqueia o dia', (tester) async {
    await tester.pumpWidget(_app(servicoFake(firestore: firestore, uid: 'm1')));
    await tester.pumpAndSettle();

    expect(find.byWidgetPredicate((w) => w is TableCalendar), findsOneWidget);
    expect(find.text('Show de sexta'), findsOneWidget);
    expect(find.text('Contratante: Bar Central'), findsOneWidget);
    expect(find.text('Show confirmado'), findsOneWidget); // legenda

    expect(find.text('Livre para shows (padrão).'), findsOneWidget);
    await tester.tap(find.text('Bloquear este dia'));
    await tester.pumpAndSettle();

    expect(find.text('Você não aparece como livre neste dia.'), findsOneWidget);
    final doc = await firestore.collection('bloqueios').doc('m1_$hoje').get();
    expect(doc.exists, isTrue);
  });

  testWidgets('dono vê o show que contratou, sem bloquear dias', (tester) async {
    await tester.pumpWidget(_app(servicoFake(firestore: firestore, uid: 'e1')));
    await tester.pumpAndSettle();

    expect(find.text('Show de sexta'), findsOneWidget);
    expect(find.text('Artista: Banda'), findsOneWidget);
    expect(find.text('Bloquear este dia'), findsNothing);
  });

  testWidgets('dia sem show mostra aviso', (tester) async {
    await firestore.collection('contratacoes').doc('c1').delete();
    await tester.pumpWidget(_app(servicoFake(firestore: firestore, uid: 'm1')));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum show neste dia.'), findsOneWidget);
  });
}
