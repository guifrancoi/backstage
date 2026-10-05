import 'package:backstage/providers/avaliacao_provider.dart';
import 'package:backstage/providers/agenda_provider.dart';
import 'package:backstage/providers/auth_provider.dart';
import 'package:backstage/providers/chat_provider.dart';
import 'package:backstage/providers/interesse_provider.dart';
import 'package:backstage/providers/oportunidade_provider.dart';
import 'package:backstage/providers/perfil_provider.dart';
import 'package:backstage/routes/app_routes.dart';
import 'package:backstage/screens/busca/lista_musicos_screen.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:backstage/widgets/faixa_generos.dart';
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
      ChangeNotifierProvider(create: (_) => AvaliacaoProvider(service: service)),
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

/// Tela alta: os cards do Plano 8 são mais altos e o `ListView.builder` só
/// monta o que cabe.
void _telaAlta(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('lista os músicos do provider', (tester) async {
    _telaAlta(tester);
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

  testWidgets('Filtrar abre o painel; critério vira chip removível com contador', (tester) async {
    final service = await _logado();
    await service.firestore.collection('perfis_musicos').doc('2').update({
      'formacao': 'duo',
    });
    await tester.pumpWidget(_app(service: service));
    await tester.pumpAndSettle();
    expect(find.text('3 músicos'), findsOneWidget);

    await tester.tap(find.text('Filtrar'));
    await tester.pumpAndSettle();
    expect(find.text('Filtrar músicos'), findsOneWidget);
    await tester.tap(find.text('Qualquer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duo').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(find.text('Filtrar (1)'), findsOneWidget);
    expect(find.text('1 músico'), findsOneWidget);
    expect(find.text('Duo Acústico Sol'), findsOneWidget);
    expect(find.text('Banda Eclipse'), findsNothing);

    tester.widget<InputChip>(find.widgetWithText(InputChip, 'Duo')).onDeleted!();
    await tester.pumpAndSettle();

    expect(find.text('Filtrar'), findsOneWidget);
    expect(find.text('3 músicos'), findsOneWidget);
  });

  testWidgets('Limpar tira os critérios do painel e mantém o gênero', (tester) async {
    await tester.pumpWidget(
      _app(
        service: await _logado(),
        preparar: (p) => p.filtrarMusicos(genero: 'MPB', soEquipamentoProprio: true),
      ),
    );
    await tester.pumpAndSettle();
    // Plano 8: o gênero fica na faixa do topo, fora do "Filtrar (n)".
    expect(find.text('Filtrar (1)'), findsOneWidget);

    await tester.tap(find.text('Limpar'));
    await tester.pumpAndSettle();

    expect(find.text('Filtrar'), findsOneWidget);
    expect(find.byType(InputChip), findsNothing);
    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'MPB')).selected,
      isTrue,
    );
  });

  testWidgets('Plano 8: pesquisa sem acento e faixa de gêneros', (tester) async {
    await tester.pumpWidget(_app(service: await _logado()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'acustico');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('1 músico'), findsOneWidget);
    expect(find.text('Duo Acústico Sol'), findsOneWidget);

    await tester.tap(find.byTooltip('Limpar pesquisa'));
    await tester.pumpAndSettle();
    expect(find.text('3 músicos'), findsOneWidget);

    // A faixa é horizontal e só monta o que aparece: rola até o gênero.
    final eletronica = find.widgetWithText(ChoiceChip, 'Eletrônica');
    await tester.scrollUntilVisible(
      eletronica,
      200,
      scrollable: find.descendant(
        of: find.byType(FaixaGeneros),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(eletronica);
    await tester.pumpAndSettle();
    expect(find.text('1 músico'), findsOneWidget);
    expect(find.text('DJ Pulse'), findsOneWidget);

    final todos = find.widgetWithText(ChoiceChip, 'Todos');
    await tester.scrollUntilVisible(
      todos,
      -200,
      scrollable: find.descendant(
        of: find.byType(FaixaGeneros),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(todos);
    await tester.pumpAndSettle();
    expect(find.text('3 músicos'), findsOneWidget);
  });

  group('Plano 13: livres em uma data', () {
    final dia = DateTime(2099, 3, 10);

    testWidgets('chip mostra o dia, esconde quem não está livre e sai ao remover', (tester) async {
      final service = await _donoLogado();
      await service.firestore.collection('bloqueios').doc('1_2099-03-10').set({
        'usuarioId': '1',
        'data': dia,
        'dia': '2099-03-10',
      });
      await tester.pumpWidget(
        _app(service: service, preparar: (p) => p.filtrarMusicosLivresEm(dia)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Livres em 10/03/2099'), findsOneWidget);
      expect(find.text('Banda Eclipse'), findsNothing);
      expect(find.text('Duo Acústico Sol'), findsOneWidget);

      tester.widget<InputChip>(find.byType(InputChip)).onDeleted!();
      await tester.pumpAndSettle();

      expect(find.text('Livres em 10/03/2099'), findsNothing);
      expect(find.text('Banda Eclipse'), findsOneWidget);
    });

    testWidgets('ninguém livre: mensagem cita o dia', (tester) async {
      final service = await _donoLogado();
      await tester.pumpWidget(
        _app(
          service: service,
          preparar: (p) => p
            ..pesquisarMusicos('Eclipse')
            ..filtrarMusicosLivresEm(dia),
        ),
      );
      await service.firestore.collection('ocupacoes').doc('1_2099-03-10').set({
        'musicoId': '1',
        'dia': '2099-03-10',
        'contratacaoId': 'c1',
      });
      await tester.pumpAndSettle();

      expect(
        find.text('Nenhum músico livre em 10/03/2099 com os filtros informados.'),
        findsOneWidget,
      );
    });

    testWidgets('convite já vem marcado na oportunidade do dia buscado', (tester) async {
      final service = await _donoLogado();
      await gravarCatalogo(
        service.firestore,
        oportunidades: [
          oportunidadeTeste(id: 'outra', titulo: 'Show de outro dia', donoId: 'e1')
              .copyWith(dataEvento: DateTime(2099, 1, 5)),
          oportunidadeTeste(id: 'sexta', titulo: 'Show da sexta', donoId: 'e1')
              .copyWith(dataEvento: dia),
        ],
      );
      await tester.pumpWidget(
        _app(
          service: service,
          preparar: (p) => p
            ..pesquisarMusicos('Eclipse')
            ..filtrarMusicosLivresEm(dia),
        ),
      );
      await tester.pumpAndSettle();

      await abrirPainel(tester);
      await tester.tap(find.text('Enviar convite'));
      await tester.pumpAndSettle();

      final doc = await service.firestore
          .collection('interesses')
          .doc('e1_mu_1_sexta')
          .get();
      expect(doc.exists, isTrue);
    });
  });

  testWidgets('Plano 18: dono favorita no card e filtra só favoritos', (tester) async {
    _telaAlta(tester);
    final service = await _donoLogado();
    await tester.pumpWidget(_app(service: service));
    await tester.pumpAndSettle();

    final card = find.ancestor(
      of: find.text('Duo Acústico Sol'),
      matching: find.byType(Card),
    );
    await tester.tap(
      find.descendant(of: card, matching: find.byTooltip('Adicionar aos favoritos')),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: card, matching: find.byTooltip('Remover dos favoritos')),
      findsOneWidget,
    );

    await tester.tap(find.text('Filtrar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Só favoritos'));
    await tester.tap(find.text('Só favoritos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(find.text('1 músico'), findsOneWidget);
    expect(find.text('Duo Acústico Sol'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Favoritos'), findsOneWidget);
  });

  testWidgets('Plano 18: quem não é dono não vê o coração', (tester) async {
    await tester.pumpWidget(_app(service: await _logado(tipoUsuario: 'musico')));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Adicionar aos favoritos'), findsNothing);
  });
}
