import 'package:backstage/core/theme/app_theme.dart';
import 'package:backstage/models/mensagem.dart';
import 'package:backstage/providers/auth_provider.dart';
import 'package:backstage/providers/chat_provider.dart';
import 'package:backstage/providers/contratacao_provider.dart';
import 'package:backstage/providers/denuncia_provider.dart';
import 'package:backstage/providers/interesse_provider.dart';
import 'package:backstage/providers/oportunidade_provider.dart';
import 'package:backstage/screens/chat/chat_screen.dart';
import 'package:backstage/screens/chat/conversas_screen.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/firebase_fake.dart';

/// Plano 8, Fase 5: chat por dia, aviso só na falha e horário das conversas.

/// Envio sempre recusado (como um bloqueio nas regras).
class _ServicoSemEnviar extends FirebaseDataService {
  _ServicoSemEnviar(FakeFirebaseFirestore firestore)
    : super(
        auth: servicoFake(firestore: firestore, uid: 'm1').auth,
        firestore: firestore,
      );

  @override
  Future<void> enviarMensagem(String conversaId, Mensagem mensagem) =>
      Future.error(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );
}

Widget _app(FirebaseDataService service, Widget tela) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider(service: service)),
      ChangeNotifierProvider(create: (_) => ChatProvider(service: service)),
      ChangeNotifierProvider(
        create: (_) => InteresseProvider(service: service),
      ),
      ChangeNotifierProvider(
        create: (_) => ContratacaoProvider(service: service),
      ),
      ChangeNotifierProvider(
        create: (_) => OportunidadeProvider(service: service),
      ),
      ChangeNotifierProvider(create: (_) => DenunciaProvider(service: service)),
    ],
    child: MaterialApp(theme: AppTheme.escuro, home: tela),
  );
}

void main() {
  late FakeFirebaseFirestore firestore;
  final agora = DateTime.now();
  final ontem = agora.subtract(const Duration(days: 1));

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('conversas').doc('i1').set({
      'participantes': ['e1', 'm1'],
      'nomes': {'e1': 'Bar Central', 'm1': 'Banda'},
      'mensagens': [
        Mensagem(
          id: '1',
          remetenteId: 'e1',
          texto: 'Oi, ontem',
          dataHora: ontem,
        ).toMap(),
        Mensagem(
          id: '2',
          remetenteId: 'm1',
          texto: 'Oi, hoje',
          dataHora: agora,
        ).toMap(),
      ],
      'atualizadoEm': agora,
    });
  });

  test('rotuloDia: Hoje, Ontem ou a data curta', () {
    final ref = DateTime(2026, 10, 5, 15);
    expect(rotuloDia(DateTime(2026, 10, 5, 8), agora: ref), 'Hoje');
    expect(rotuloDia(DateTime(2026, 10, 4, 23), agora: ref), 'Ontem');
    expect(rotuloDia(DateTime(2026, 9, 20), agora: ref), '20 set');
  });

  test('ConversasScreen.quando: hora, ontem ou data', () {
    final ref = DateTime(2026, 10, 5, 15);
    expect(
      ConversasScreen.quando(DateTime(2026, 10, 5, 9, 7), agora: ref),
      '09:07',
    );
    expect(
      ConversasScreen.quando(DateTime(2026, 10, 4, 22), agora: ref),
      'ontem',
    );
    expect(
      ConversasScreen.quando(DateTime(2025, 12, 1), agora: ref),
      '1 dez 2025',
    );
  });

  testWidgets('chat separa as mensagens por dia, com nome e avatar no topo', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        servicoFake(firestore: firestore, uid: 'm1'),
        const ChatScreen(conversaId: 'i1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bar Central'), findsOneWidget);
    expect(find.text('BC'), findsOneWidget);
    expect(find.text('Ontem'), findsOneWidget);
    expect(find.text('Hoje'), findsOneWidget);
    // Ordem na tela: separador Ontem, mensagem de ontem, Hoje, a de hoje.
    double y(String t) => tester.getTopLeft(find.text(t)).dy;
    expect(y('Ontem'), lessThan(y('Oi, ontem')));
    expect(y('Oi, ontem'), lessThan(y('Hoje')));
    expect(y('Hoje'), lessThan(y('Oi, hoje')));
  });

  testWidgets('enviar com sucesso não mostra aviso', (tester) async {
    await tester.pumpWidget(
      _app(
        servicoFake(firestore: firestore, uid: 'm1'),
        const ChatScreen(conversaId: 'i1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Tudo certo!');
    await tester.tap(find.byTooltip('Enviar'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Tudo certo!'), findsOneWidget);
  });

  testWidgets('falha ao enviar mostra o aviso e mantém o texto', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_ServicoSemEnviar(firestore), const ChatScreen(conversaId: 'i1')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Não vai');
    await tester.tap(find.byTooltip('Enviar'));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível enviar a mensagem.'), findsOneWidget);
    // O texto fica no campo para tentar de novo.
    expect(find.widgetWithText(TextField, 'Não vai'), findsOneWidget);
  });
}
