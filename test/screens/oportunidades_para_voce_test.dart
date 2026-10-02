import 'package:backstage/providers/avaliacao_provider.dart';
import 'package:backstage/providers/interesse_provider.dart';
import 'package:backstage/providers/oportunidade_provider.dart';
import 'package:backstage/providers/perfil_provider.dart';
import 'package:backstage/screens/home/oportunidades_para_voce.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/firebase_fake.dart';

Widget _app(FirebaseDataService service) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => PerfilProvider(service: service)),
      ChangeNotifierProvider(create: (_) => OportunidadeProvider(service: service)),
      ChangeNotifierProvider(create: (_) => InteresseProvider(service: service)),
      ChangeNotifierProvider(create: (_) => AvaliacaoProvider(service: service)),
    ],
    child: MaterialApp(
      home: const Scaffold(body: SingleChildScrollView(child: OportunidadesParaVoce())),
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (_) => Scaffold(body: Text('${settings.name} ${settings.arguments}')),
      ),
    ),
  );
}

void main() {
  late FakeFirebaseFirestore firestore;

  /// Músico m1 (Rock, Franca, cachê 1000) e oportunidades de e1/e2.
  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('usuarios').doc('m1').set({'tipoUsuario': 'musico'});
    await gravarCatalogo(
      firestore,
      musicos: [musicoTeste(id: 'm1')],
      oportunidades: [
        oportunidadeTeste(id: 'boa', titulo: 'Rock no Bar', donoId: 'e1')
            .copyWith(cacheOferecido: 1500),
        oportunidadeTeste(
          id: 'assinante',
          titulo: 'Rock do Assinante',
          donoId: 'e2',
        ).copyWith(cacheOferecido: 1500, dataEvento: DateTime(2099, 6, 1)),
        oportunidadeTeste(
          id: 'ruim',
          titulo: 'Sarau distante',
          generoMusical: 'MPB',
          cidade: 'Outra',
          donoId: 'e1',
        ),
        oportunidadeTeste(id: 'bloqueada', titulo: 'Dia bloqueado', donoId: 'e1')
            .copyWith(dataEvento: DateTime(2099, 2, 2)),
      ],
    );
    await firestore.collection('bloqueios').doc('m1_2099-02-02').set({
      'usuarioId': 'm1',
      'data': DateTime(2099, 2, 2),
      'dia': '2099-02-02',
    });
    await firestore.collection('assinantes').doc('e2').set({'desde': DateTime(2026)});
  });

  testWidgets('mostra as compatíveis, assinante desempata, e navega', (tester) async {
    await tester.pumpWidget(_app(servicoFake(firestore: firestore, uid: 'm1')));
    await tester.pumpAndSettle();

    expect(find.text('Oportunidades para você'), findsOneWidget);
    expect(find.text('Sarau distante'), findsNothing);
    expect(find.text('Dia bloqueado'), findsNothing);
    // Mesma nota: a do dono assinante vem primeiro, mesmo sendo depois.
    final assinante = tester.getTopLeft(find.text('Rock do Assinante')).dy;
    final outra = tester.getTopLeft(find.text('Rock no Bar')).dy;
    expect(assinante, lessThan(outra));
    expect(find.text('Assinante'), findsOneWidget);

    await tester.tap(find.text('Rock no Bar'));
    await tester.pumpAndSettle();
    expect(find.text('/detalhe-oportunidade boa'), findsOneWidget);
  });

  testWidgets('sem perfil de músico não aparece', (tester) async {
    await tester.pumpWidget(_app(servicoFake(firestore: firestore, uid: 'e1')));
    await tester.pumpAndSettle();

    expect(find.text('Oportunidades para você'), findsNothing);
  });
}
