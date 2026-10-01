import 'package:backstage/providers/agenda_provider.dart';
import 'package:backstage/providers/auth_provider.dart';
import 'package:backstage/providers/chat_provider.dart';
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
      ChangeNotifierProvider(create: (_) => ChatProvider(service: service)),
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
        return MaterialPageRoute(
          builder: (_) => Scaffold(body: Text('${settings.name} ${settings.arguments}')),
        );
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

  /// Toca em "Convidar" e espera o painel (ele lê a agenda pública antes).
  Future<void> abrirPainel(WidgetTester tester, {String botao = 'Convidar'}) async {
    await tester.tap(find.text(botao));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }

  testWidgets('dono convida sem oportunidade: botão segue ativo com o resumo', (tester) async {
    final service = await _donoLogado();
    await tester.pumpWidget(
      _app(service: service, preparar: (p) => p.pesquisarMusicos('Eclipse')),
    );
    await tester.pumpAndSettle();

    await abrirPainel(tester);
    expect(find.text('Convidar Banda Eclipse'), findsOneWidget);
    // Nada marcado: não dá para enviar ainda.
    expect(
      tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Enviar convite')).onPressed,
      isNull,
    );

    await tester.tap(find.text('Sem oportunidade específica'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar convite'));
    await tester.pumpAndSettle();

    expect(find.text('Convite enviado!'), findsOneWidget);
    expect(find.text('Convidar (1 pendente)'), findsOneWidget);
    final doc = await service.firestore.collection('interesses').doc('e1_mu_1').get();
    expect(doc.data()?['remetenteNome'], 'Bar Central');
  });

  testWidgets('convite aceito numa oportunidade não impede convidar para outra', (tester) async {
    final service = await _donoLogado();
    final firestore = service.firestore;
    await gravarCatalogo(
      firestore,
      oportunidades: [
        oportunidadeTeste(id: 'metal', titulo: 'Show Metal 456', donoId: 'e1'),
        oportunidadeTeste(id: 'rock', titulo: 'Show Rock Bar 123', donoId: 'e1')
            .copyWith(dataEvento: DateTime(2099, 12, 1)),
      ],
    );
    await firestore.collection('interesses').doc('e1_mu_1_metal').set({
      'tipo': 'convite',
      'remetenteId': 'e1',
      'remetenteNome': 'Bar Central',
      'destinatarioId': '1',
      'musicoId': '1',
      'musicoNome': 'Banda Eclipse',
      'oportunidadeId': 'metal',
      'oportunidadeTitulo': 'Show Metal 456',
      'status': 'aceito',
      'criadoEm': DateTime(2026, 9, 1),
    });
    await tester.pumpWidget(
      _app(service: service, preparar: (p) => p.pesquisarMusicos('Eclipse')),
    );
    await tester.pumpAndSettle();

    // O botão continua "Convidar" (o convite aceito não trava o músico).
    await abrirPainel(tester);
    expect(find.text('Aceito'), findsOneWidget);

    // A já aceita não pode ser escolhida; a outra sim.
    await tester.tap(find.text('Show Metal 456'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Enviar convite')).onPressed,
      isNull,
    );
    await tester.tap(find.text('Show Rock Bar 123'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar convite'));
    await tester.pumpAndSettle();

    final doc = await firestore.collection('interesses').doc('e1_mu_1_rock').get();
    expect(doc.exists, isTrue);
  });

  testWidgets('quem se candidatou: o painel oferece "Aceitar candidatura"', (tester) async {
    final service = await _donoLogado();
    final firestore = service.firestore;
    await gravarCatalogo(
      firestore,
      oportunidades: [oportunidadeTeste(id: 'rock', titulo: 'Show Rock Bar 123', donoId: 'e1')],
    );
    await firestore.collection('interesses').doc('1_op_rock').set({
      'tipo': 'candidatura',
      'remetenteId': '1',
      'remetenteNome': 'Banda Eclipse',
      'destinatarioId': 'e1',
      'musicoId': '1',
      'musicoNome': 'Banda Eclipse',
      'oportunidadeId': 'rock',
      'oportunidadeTitulo': 'Show Rock Bar 123',
      'status': 'pendente',
      'criadoEm': DateTime(2026, 9, 1),
    });
    await tester.pumpWidget(
      _app(service: service, preparar: (p) => p.pesquisarMusicos('Eclipse')),
    );
    await tester.pumpAndSettle();

    await abrirPainel(tester);
    expect(find.text('Ele se candidatou'), findsOneWidget);
    await tester.tap(find.text('Show Rock Bar 123'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aceitar candidatura'));
    await tester.pumpAndSettle();

    expect(find.text('Candidatura aceita! A conversa foi aberta.'), findsOneWidget);
    final candidatura = await firestore.collection('interesses').doc('1_op_rock').get();
    expect(candidatura.data()?['status'], 'aceito');
  });

  testWidgets('fechar o painel não envia convite', (tester) async {
    final service = await _donoLogado();
    await tester.pumpWidget(
      _app(service: service, preparar: (p) => p.pesquisarMusicos('Eclipse')),
    );
    await tester.pumpAndSettle();

    await abrirPainel(tester);
    // Toca fora do painel (na barreira) para fechar.
    await tester.tapAt(const Offset(400, 20));
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

  testWidgets('quem já conversa com o músico: o painel oferece "Abrir conversa"', (tester) async {
    final service = await _donoLogado();
    // Convite já aceito entre e1 e o músico '1' = os dois já conversam.
    await service.firestore.collection('interesses').doc('e1_mu_1').set({
      'tipo': 'convite',
      'remetenteId': 'e1',
      'remetenteNome': 'Bar Central',
      'destinatarioId': '1',
      'musicoId': '1',
      'musicoNome': 'Banda Eclipse',
      'status': 'aceito',
      'criadoEm': DateTime(2026, 9, 1),
    });
    await tester.pumpWidget(
      _app(service: service, preparar: (p) => p.pesquisarMusicos('Eclipse')),
    );
    await tester.pumpAndSettle();

    await abrirPainel(tester);
    expect(find.text('Sem oportunidade específica'), findsNothing);
    await tester.tap(find.text('Abrir conversa'));
    await tester.pumpAndSettle();

    expect(find.text('${AppRoutes.chat} 1_e1'), findsOneWidget);
    // A conversa do par existe (recriada se tivesse sumido) e nada novo foi enviado.
    final conversa = await service.firestore.collection('conversas').doc('1_e1').get();
    expect(conversa.exists, isTrue);
    final docs = await service.firestore.collection('interesses').get();
    expect(docs.docs, hasLength(1));
  });
}
