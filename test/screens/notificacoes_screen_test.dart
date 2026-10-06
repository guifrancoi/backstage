import 'package:backstage/models/contratacao.dart';
import 'package:backstage/providers/avaliacao_provider.dart';
import 'package:backstage/models/mensagem.dart';
import 'package:backstage/models/notificacao.dart';
import 'package:backstage/providers/auth_provider.dart';
import 'package:backstage/providers/chat_provider.dart';
import 'package:backstage/providers/denuncia_provider.dart';
import 'package:backstage/providers/oportunidade_provider.dart';
import 'package:backstage/providers/contratacao_provider.dart';
import 'package:backstage/providers/interesse_provider.dart';
import 'package:backstage/providers/notificacao_provider.dart';
import 'package:backstage/routes/app_routes.dart';
import 'package:backstage/screens/chat/chat_screen.dart';
import 'package:backstage/screens/chat/conversas_screen.dart';
import 'package:backstage/screens/home/home_screen.dart';
import 'package:backstage/screens/home/shell_screen.dart';
import 'package:backstage/screens/notificacoes/notificacoes_screen.dart';
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
      ChangeNotifierProvider(create: (_) => AvaliacaoProvider(service: service)),
      ChangeNotifierProvider(create: (_) => InteresseProvider(service: service)),
      ChangeNotifierProvider(create: (_) => ContratacaoProvider(service: service)),
      ChangeNotifierProvider(create: (_) => NotificacaoProvider(service: service)),
      ChangeNotifierProvider(create: (_) => ChatProvider(service: service)),
      ChangeNotifierProvider(create: (_) => OportunidadeProvider(service: service)),
      ChangeNotifierProvider(create: (_) => DenunciaProvider(service: service)),
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

  Future<void> gravarNotificacao(
    String id,
    TipoNotificacao tipo, {
    String? oportunidadeId,
    bool lida = false,
  }) {
    return firestore.collection('notificacoes').doc(id).set(
      Notificacao(
        destinatarioId: 'm1',
        autorId: 'e1',
        autorNome: 'Bar Central',
        tipo: tipo,
        titulo: 'Título $id',
        texto: 'Texto $id',
        interesseId: 'i1',
        oportunidadeId: oportunidadeId,
        lida: lida,
        criadaEm: DateTime.now(),
      ).toMap(),
    );
  }

  setUp(() => firestore = FakeFirebaseFirestore());

  testWidgets('tocar marca como lida e leva à oportunidade alterada', (tester) async {
    await gravarNotificacao('n1', TipoNotificacao.oportunidadeAlterada, oportunidadeId: 'o1');
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'm1'), const NotificacoesScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Título n1'));
    await tester.pumpAndSettle();

    expect(find.text('${AppRoutes.detalheOportunidade} o1'), findsOneWidget);
    final doc = await firestore.collection('notificacoes').doc('n1').get();
    expect(doc.data()?['lida'], isTrue);
  });

  testWidgets('contratação leva a Contratações; "Marcar todas" some sem não lidas', (tester) async {
    await gravarNotificacao('n1', TipoNotificacao.contratacaoProposta);
    await gravarNotificacao('n2', TipoNotificacao.interesseRecebido);
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'm1'), const NotificacoesScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Marcar todas como lidas'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Marcar todas como lidas'), findsNothing);

    await tester.tap(find.text('Título n1'));
    await tester.pumpAndSettle();
    expect(find.text('${AppRoutes.contratacoes} null'), findsOneWidget);
  });

  testWidgets('lista vazia mostra aviso', (tester) async {
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'm1'), const NotificacoesScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma notificação por aqui.'), findsOneWidget);
  });

  testWidgets('Home: sino com não lidas e selo de mensagens na aba Conversas', (tester) async {
    await gravarNotificacao('n1', TipoNotificacao.interesseAceito);
    await gravarNotificacao('n2', TipoNotificacao.interesseAceito);
    await gravarNotificacao('n3', TipoNotificacao.interesseAceito, lida: true);
    await firestore.collection('conversas').doc('i1').set({
      'participantes': ['e1', 'm1'],
      'nomes': {'e1': 'Bar Central', 'm1': 'Banda'},
      'mensagens': [
        Mensagem(
          id: '1',
          remetenteId: 'e1',
          texto: 'Oi!',
          dataHora: DateTime(2026, 9, 1),
        ).toMap(),
      ],
    });
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'm1'), const ShellScreen()),
    );
    await tester.pumpAndSettle();

    final sino = find.byTooltip('Notificações');
    expect(
      find.descendant(of: sino, matching: find.text('2')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(NavigationDestination, 'Conversas'),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    await tester.tap(sino);
    await tester.pumpAndSettle();
    expect(find.text('${AppRoutes.notificacoes} null'), findsOneWidget);
  });

  testWidgets('Conversas mostra quantas mensagens não lidas cada conversa tem', (tester) async {
    await firestore.collection('conversas').doc('i1').set({
      'participantes': ['e1', 'm1'],
      'nomes': {'e1': 'Bar Central', 'm1': 'Banda'},
      'mensagens': [
        for (final i in [1, 2, 3])
          Mensagem(
            id: '$i',
            remetenteId: 'e1',
            texto: 'msg $i',
            dataHora: DateTime(2026, 9, 1, 10, i),
          ).toMap(),
      ],
    });
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'm1'), const ConversasScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
    expect(find.text('msg 3'), findsOneWidget);
  });

  testWidgets('abrir o chat marca a conversa como lida', (tester) async {
    await firestore.collection('conversas').doc('i1').set({
      'participantes': ['e1', 'm1'],
      'nomes': {'e1': 'Bar Central', 'm1': 'Banda'},
      'mensagens': [
        Mensagem(
          id: '1',
          remetenteId: 'e1',
          texto: 'Oi!',
          dataHora: DateTime(2026, 9, 1),
        ).toMap(),
      ],
    });
    await tester.pumpWidget(
      _app(
        servicoFake(firestore: firestore, uid: 'm1'),
        const ChatScreen(conversaId: 'i1'),
      ),
    );
    await tester.pumpAndSettle();

    final doc = await firestore.collection('conversas').doc('i1').get();
    expect((doc.data()?['lidaEm'] as Map?)?.containsKey('m1'), isTrue);
  });

  testWidgets('Home: lembrete do show de hoje (Plano 19)', (tester) async {
    await firestore.collection('contratacoes').doc('c1').set(
      Contratacao(
        id: 'c1',
        interesseId: 'i1',
        musicoId: 'm1',
        musicoNome: 'Banda',
        donoId: 'e1',
        donoNome: 'Bar Central',
        titulo: 'Sexta do Rock',
        dia: Contratacao.diaDe(DateTime.now()),
        horaInicio: '21:00',
        horaFim: '23:00',
        cacheAcordado: 1500,
        logradouro: 'Rua A',
        numero: '10',
        cidade: 'Franca',
        estado: 'SP',
        criadoEm: DateTime(2026, 9, 1),
        status: StatusContratacao.confirmada,
      ).toMap(),
    );
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'm1'), const HomeScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Seu show é hoje às 21:00 em Bar Central'), findsOneWidget);
    expect(find.text('Sexta do Rock · Rua A, 10 — Franca/SP'), findsOneWidget);
  });
}
