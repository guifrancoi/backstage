import 'package:backstage/providers/avaliacao_provider.dart';
import 'package:backstage/providers/auth_provider.dart';
import 'package:backstage/providers/interesse_provider.dart';
import 'package:backstage/providers/oportunidade_provider.dart';
import 'package:backstage/providers/perfil_provider.dart';
import 'package:backstage/screens/busca/detalhe_estabelecimento_screen.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:backstage/services/location_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/firebase_fake.dart';

Widget _app(FirebaseDataService service, {String donoId = 'e1'}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider(service: service)),
      ChangeNotifierProvider(create: (_) => AvaliacaoProvider(service: service)),
      ChangeNotifierProvider(create: (_) => PerfilProvider(service: service)),
      ChangeNotifierProvider(create: (_) => OportunidadeProvider(service: service)),
      ChangeNotifierProvider(create: (_) => InteresseProvider(service: service)),
      Provider<LocationService>(
        create: (_) => LocationService(),
        dispose: (_, s) => s.dispose(),
      ),
    ],
    child: MaterialApp(
      home: DetalheEstabelecimentoScreen(donoId: donoId),
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

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('usuarios').doc('m1').set({'tipoUsuario': 'musico'});
    await firestore.collection('usuarios').doc('e1').set({'tipoUsuario': 'casaShow'});
    await firestore.collection('estabelecimentos').doc('e1').set({
      'nome': 'Bar Central',
      'cidade': 'Franca',
      'logradouro': 'Rua A',
      'numero': '10',
      'estado': 'SP',
      'capacidade': 150,
      'estilosDesejados': ['Rock', 'Blues'],
      'descricao': 'Bar com palco.',
      'oculto': false,
    });
    await gravarCatalogo(
      firestore,
      oportunidades: [
        oportunidadeTeste(id: 'futura', titulo: 'Sexta do Rock', donoId: 'e1'),
        oportunidadeTeste(id: 'velha', titulo: 'Show de ontem', donoId: 'e1')
            .copyWith(dataEvento: ontem),
        oportunidadeTeste(id: 'outra', titulo: 'De outro dono', donoId: 'e2'),
      ],
    );
  });

  testWidgets('mostra os dados públicos e só as oportunidades abertas do dono', (tester) async {
    await tester.pumpWidget(_app(servicoFake(firestore: firestore, uid: 'm1')));
    await tester.pumpAndSettle();

    expect(find.text('Bar Central'), findsWidgets);
    expect(find.text('Rua A, 10'), findsOneWidget);
    expect(find.text('Ver no mapa'), findsOneWidget);
    expect(find.text('CAPACIDADE'), findsOneWidget);
    expect(find.text('150 pessoas'), findsOneWidget);
    expect(find.text('Blues'), findsOneWidget);
    expect(find.text('Ainda sem avaliações.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Sexta do Rock'), 300);
    expect(find.text('Oportunidades abertas (1)'), findsOneWidget);
    expect(find.text('Sexta do Rock'), findsOneWidget);
    expect(find.text('Show de ontem'), findsNothing);
    expect(find.text('De outro dono'), findsNothing);
  });

  testWidgets('sem acesso ao privado: contato fica bloqueado com aviso', (tester) async {
    await tester.pumpWidget(_app(servicoFake(firestore: firestore, uid: 'm1')));
    await tester.pumpAndSettle();

    expect(
      find.text('Contato e CNPJ são liberados depois de um interesse aceito entre vocês.'),
      findsOneWidget,
    );
  });

  testWidgets('com o privado legível (dono ou quem conversa): mostra contato e CNPJ', (tester) async {
    await firestore
        .collection('estabelecimentos')
        .doc('e1')
        .collection('privado')
        .doc('dados')
        .set({'contato': '(16) 3000-0000', 'cnpj': '00.000.000/0001-10'});
    await tester.pumpWidget(_app(servicoFake(firestore: firestore, uid: 'm1')));
    await tester.pumpAndSettle();

    expect(find.text('(16) 3000-0000'), findsOneWidget);
    expect(find.text('CNPJ: 00.000.000/0001-10'), findsOneWidget);
  });

  testWidgets('dono sem perfil: aviso, mas as oportunidades aparecem', (tester) async {
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'm1'), donoId: 'e2'),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Este estabelecimento ainda não completou o perfil.'),
      findsOneWidget,
    );
    expect(find.text('De outro dono'), findsOneWidget);
  });

  testWidgets('Ver detalhes abre a oportunidade', (tester) async {
    await tester.pumpWidget(_app(servicoFake(firestore: firestore, uid: 'm1')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Ver detalhes'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver detalhes'));
    await tester.pumpAndSettle();

    expect(find.text('/detalhe-oportunidade futura'), findsOneWidget);
  });

  testWidgets('mostra média e comentários recebidos (Plano 17)', (tester) async {
    for (final (autor, nota, comentario, dia) in [
      ('m1', 5, 'Ótima estrutura', 10),
      ('m2', 4, '', 20),
    ]) {
      await firestore.collection('avaliacoes').doc('c${dia}_$autor').set({
        'contratacaoId': 'c$dia',
        'autorId': autor,
        'autorNome': 'Banda $autor',
        'avaliadoId': 'e1',
        'nota': nota,
        'comentario': comentario,
        'criadaEm': DateTime(2026, 9, dia),
      });
    }
    await tester.pumpWidget(_app(servicoFake(firestore: firestore, uid: 'm1')));
    await tester.pumpAndSettle();

    expect(find.text('★ 4,5 · 2 avaliações'), findsOneWidget);
    expect(find.text('Ótima estrutura'), findsOneWidget);
    // Mais recente primeiro.
    final recente = tester.getTopLeft(find.textContaining('Banda m2')).dy;
    final antiga = tester.getTopLeft(find.textContaining('Banda m1')).dy;
    expect(recente, lessThan(antiga));
  });
}
