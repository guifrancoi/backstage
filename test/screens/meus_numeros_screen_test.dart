import 'package:backstage/models/contratacao.dart';
import 'package:backstage/providers/auth_provider.dart';
import 'package:backstage/providers/avaliacao_provider.dart';
import 'package:backstage/providers/contratacao_provider.dart';
import 'package:backstage/providers/interesse_provider.dart';
import 'package:backstage/providers/oportunidade_provider.dart';
import 'package:backstage/screens/numeros/meus_numeros_screen.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/firebase_fake.dart';

Widget _app(FirebaseDataService service) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider(service: service)),
      ChangeNotifierProvider(create: (_) => AvaliacaoProvider(service: service)),
      ChangeNotifierProvider(create: (_) => ContratacaoProvider(service: service)),
      ChangeNotifierProvider(create: (_) => InteresseProvider(service: service)),
      ChangeNotifierProvider(create: (_) => OportunidadeProvider(service: service)),
    ],
    child: const MaterialApp(home: MeusNumerosScreen()),
  );
}

void main() {
  late FakeFirebaseFirestore firestore;

  Future<void> show(String id, int diasAtras, double cache) {
    return firestore.collection('contratacoes').doc(id).set(
      Contratacao(
        id: id,
        interesseId: 'i1',
        musicoId: 'm1',
        musicoNome: 'Banda',
        donoId: 'e1',
        donoNome: 'Bar Central',
        titulo: 'Show $id',
        dia: Contratacao.diaDe(DateTime.now().subtract(Duration(days: diasAtras))),
        horaInicio: '20:00',
        horaFim: '23:00',
        cacheAcordado: cache,
        logradouro: 'Rua A',
        numero: '1',
        cidade: 'Franca',
        estado: 'SP',
        criadoEm: DateTime(2026, 1, 1),
        status: StatusContratacao.confirmada,
      ).toMap(),
    );
  }

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('usuarios').doc('m1').set({'tipoUsuario': 'musico'});
    await firestore.collection('usuarios').doc('e1').set({'tipoUsuario': 'casaShow'});
  });

  testWidgets('músico vê indicadores e o gráfico; dono vê o lado dele', (tester) async {
    await show('a', 1, 1500);
    await show('b', -5, 1000); // próximo

    await tester.pumpWidget(_app(servicoFake(firestore: firestore, uid: 'm1')));
    await tester.pumpAndSettle();

    expect(find.text('Como músico'), findsOneWidget);
    expect(find.text('Como contratante'), findsNothing);
    expect(find.text('Próximos confirmados'), findsOneWidget);
    expect(find.text('R\$ 1.500'), findsOneWidget);
    expect(find.text('—'), findsOneWidget); // nenhuma candidatura respondida
    expect(find.byType(BarChart), findsOneWidget);
  });

  testWidgets('dono sem shows: indicadores zerados e frase no lugar do gráfico', (tester) async {
    await tester.pumpWidget(_app(servicoFake(firestore: firestore, uid: 'e1')));
    await tester.pumpAndSettle();

    expect(find.text('Como contratante'), findsOneWidget);
    expect(find.text('Oportunidades abertas'), findsOneWidget);
    expect(find.text('Nenhum show realizado nesses meses.'), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);
  });
}
