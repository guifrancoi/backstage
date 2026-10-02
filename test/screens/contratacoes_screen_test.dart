import 'package:backstage/providers/avaliacao_provider.dart';
import 'package:backstage/models/contratacao.dart';
import 'package:backstage/models/interesse.dart';
import 'package:backstage/providers/agenda_provider.dart';
import 'package:backstage/providers/auth_provider.dart';
import 'package:backstage/providers/chat_provider.dart';
import 'package:backstage/providers/contratacao_provider.dart';
import 'package:backstage/providers/interesse_provider.dart';
import 'package:backstage/providers/oportunidade_provider.dart';
import 'package:backstage/providers/perfil_provider.dart';
import 'package:backstage/routes/app_routes.dart';
import 'package:backstage/screens/chat/chat_screen.dart';
import 'package:backstage/screens/contratacoes/contratacoes_screen.dart';
import 'package:backstage/screens/contratacoes/propor_contratacao_screen.dart';
import 'package:backstage/services/firebase_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/firebase_fake.dart';

/// Como no Firestore real: o stream local já traz a proposta gravada antes
/// de o servidor confirmar a escrita (o `add` só termina depois).
class _ServicoComLatencia extends FirebaseDataService {
  _ServicoComLatencia(FakeFirebaseFirestore firestore)
    : super(
        auth: servicoFake(firestore: firestore, uid: 'e1').auth,
        firestore: firestore,
      );

  @override
  Future<String> proporContratacao(Contratacao contratacao) async {
    final id = await super.proporContratacao(contratacao);
    await Future<void>.delayed(const Duration(seconds: 1));
    return id;
  }
}

/// Tela [home] com todos os providers que as telas de contratação usam.
Widget _app(FirebaseDataService service, Widget home) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider(service: service)),
      ChangeNotifierProvider(create: (_) => AvaliacaoProvider(service: service)),
      ChangeNotifierProvider(create: (_) => PerfilProvider(service: service)),
      ChangeNotifierProvider(create: (_) => OportunidadeProvider(service: service)),
      ChangeNotifierProvider(create: (_) => InteresseProvider(service: service)),
      ChangeNotifierProvider(create: (_) => ContratacaoProvider(service: service)),
      ChangeNotifierProvider(create: (_) => ChatProvider(service: service)),
      ChangeNotifierProvider(create: (_) => AgendaProvider(service: service)),
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

  /// Candidatura de m1 à oportunidade o1 do dono e1, aceita (conversa i1).
  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('usuarios').doc('e1').set({
      'nome': 'Bar Central',
      'tipoUsuario': 'casaShow',
    });
    await firestore.collection('usuarios').doc('m1').set({
      'nome': 'Guilherme',
      'tipoUsuario': 'musico',
    });
    await gravarCatalogo(
      firestore,
      oportunidades: [
        oportunidadeTeste(id: 'o1', donoId: 'e1').copyWith(
          horaInicio: '21:00',
          horaFim: '23:30',
        ),
      ],
    );
    await firestore.collection('interesses').doc('i1').set(
      Interesse(
        id: 'i1',
        tipo: TipoInteresse.candidatura,
        remetenteId: 'm1',
        remetenteNome: 'Guilherme',
        destinatarioId: 'e1',
        musicoId: 'm1',
        musicoNome: 'Banda',
        oportunidadeId: 'o1',
        oportunidadeTitulo: 'Show de sexta',
        criadoEm: DateTime(2026, 9, 1),
        status: StatusInteresse.aceito,
        conversaId: 'i1',
      ).toMap(),
    );
    await firestore.collection('conversas').doc('i1').set({
      'participantes': ['m1', 'e1'],
      'nomes': {'m1': 'Guilherme', 'e1': 'Bar Central'},
      'interesseId': 'i1',
      'mensagens': [],
    });
  });

  testWidgets('dono vê "Propor show" na conversa do interesse aceito', (tester) async {
    await tester.pumpWidget(
      _app(
        servicoFake(firestore: firestore, uid: 'e1'),
        const ChatScreen(conversaId: 'i1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Propor show'));
    await tester.pumpAndSettle();

    expect(find.text('${AppRoutes.proporContratacao} i1'), findsOneWidget);
  });

  testWidgets('conversa com dois interesses aceitos: "Propor show" pergunta qual', (tester) async {
    await firestore.collection('interesses').doc('i2').set(
      Interesse(
        id: 'i2',
        tipo: TipoInteresse.convite,
        remetenteId: 'e1',
        remetenteNome: 'Bar Central',
        destinatarioId: 'm1',
        musicoId: 'm1',
        musicoNome: 'Banda',
        oportunidadeId: 'o2',
        oportunidadeTitulo: 'Outro show',
        criadoEm: DateTime(2026, 9, 2),
        status: StatusInteresse.aceito,
      ).toMap(),
    );
    await firestore.collection('conversas').doc('i1').update({
      'interesseIds': ['i1', 'i2'],
    });
    await tester.pumpWidget(
      _app(
        servicoFake(firestore: firestore, uid: 'e1'),
        const ChatScreen(conversaId: 'i1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Propor show'));
    await tester.pumpAndSettle();
    expect(find.text('Propor show para qual oportunidade?'), findsOneWidget);
    await tester.tap(find.text('Outro show'));
    await tester.pumpAndSettle();

    expect(find.text('${AppRoutes.proporContratacao} i2'), findsOneWidget);
  });

  testWidgets('músico não vê "Propor show" na mesma conversa', (tester) async {
    await tester.pumpWidget(
      _app(
        servicoFake(firestore: firestore, uid: 'm1'),
        const ChatScreen(conversaId: 'i1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Propor show'), findsNothing);
  });

  testWidgets('proposta vem pré-preenchida da oportunidade e é gravada', (tester) async {
    // Data no futuro para não cair em "a partir de hoje".
    await firestore.collection('oportunidades').doc('o1').update({
      'dataEvento': DateTime(2099, 11, 20),
    });
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'e1'), const SizedBox()),
    );
    await tester.pumpAndSettle();

    // Abre a tela depois dos providers carregarem (como vindo do chat).
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute(
        builder: (_) => const ProporContratacaoScreen(interesseId: 'i1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Show com Banda'), findsOneWidget);
    expect(find.text('Data: 20/11/2099'), findsOneWidget);
    expect(find.text('Início: 21:00'), findsOneWidget);

    await tester.ensureVisible(find.text('Enviar proposta'));
    await tester.tap(find.text('Enviar proposta'));
    await tester.pumpAndSettle();

    final docs = await firestore.collection('contratacoes').get();
    final gravada = Contratacao.fromMap(docs.docs.single.id, docs.docs.single.data());
    expect(gravada.status, StatusContratacao.proposta);
    expect(gravada.dia, '2099-11-20');
    expect(gravada.donoId, 'e1');
    expect(gravada.musicoId, 'm1');
    expect(gravada.horaFim, '23:30');
    expect(gravada.cacheAcordado, 1200);
  });

  testWidgets('enquanto o servidor confirma, a própria proposta não vira "já existe"', (tester) async {
    await firestore.collection('oportunidades').doc('o1').update({
      'dataEvento': DateTime(2099, 11, 20),
    });
    await tester.pumpWidget(
      _app(_ServicoComLatencia(firestore), const Text('Tela anterior')),
    );
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).push(
      MaterialPageRoute(
        builder: (_) => const ProporContratacaoScreen(interesseId: 'i1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Enviar proposta'));
    await tester.tap(find.text('Enviar proposta'));
    await tester.pump(const Duration(milliseconds: 200));

    // Stream já trouxe a proposta; o add ainda não terminou.
    expect(find.textContaining('Já existe uma contratação'), findsNothing);
    expect(find.text('Enviando...'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Tela anterior'), findsOneWidget);
  });

  testWidgets('proposta avisa quando o músico já está ocupado no dia', (tester) async {
    await firestore.collection('oportunidades').doc('o1').update({
      'dataEvento': DateTime(2099, 11, 20),
    });
    await firestore.collection('ocupacoes').doc('m1_2099-11-20').set({
      'musicoId': 'm1',
      'dia': '2099-11-20',
      'contratacaoId': 'outra',
    });
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'e1'), const SizedBox()),
    );
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).push(
      MaterialPageRoute(
        builder: (_) => const ProporContratacaoScreen(interesseId: 'i1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('O músico já tem um show confirmado nesse dia.'),
      findsOneWidget,
    );
  });

  testWidgets('músico confirma a proposta recebida (sem aba de enviadas)', (tester) async {
    await firestore.collection('contratacoes').doc('c1').set(
      Contratacao(
        id: 'c1',
        interesseId: 'i1',
        musicoId: 'm1',
        musicoNome: 'Banda',
        donoId: 'e1',
        donoNome: 'Bar Central',
        titulo: 'Show de sexta',
        dia: '2099-11-20',
        horaInicio: '21:00',
        horaFim: '23:30',
        cacheAcordado: 1200,
        logradouro: 'Rua A',
        numero: '10',
        cidade: 'Franca',
        estado: 'SP',
        criadoEm: DateTime(2026, 9, 29),
      ).toMap(),
    );
    await tester.pumpWidget(
      _app(
        servicoFake(firestore: firestore, uid: 'm1'),
        const ContratacoesScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Músico só recebe propostas: sem abas.
    expect(find.text('Enviadas'), findsNothing);
    expect(find.byType(TabBar), findsNothing);
    expect(find.text('Contratante: Bar Central'), findsOneWidget);

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Show confirmado! A data está na sua agenda.'), findsOneWidget);
    expect(find.text('Confirmada'), findsOneWidget);
    expect(find.text('Cancelar show'), findsOneWidget);
    final ocupacao = await firestore
        .collection('ocupacoes')
        .doc('m1_2099-11-20')
        .get();
    expect(ocupacao.exists, isTrue);
  });

  /// Contratações com dono e1 e músico m1, em situações e datas diferentes.
  Future<void> gravarVarias() async {
    Contratacao c(String id, String titulo, String dia, StatusContratacao status, DateTime criado) =>
        Contratacao(
          id: id,
          interesseId: 'i$id',
          musicoId: 'm1',
          musicoNome: 'Banda',
          donoId: 'e1',
          donoNome: 'Bar Central',
          titulo: titulo,
          dia: dia,
          horaInicio: '21:00',
          horaFim: '23:00',
          cacheAcordado: 1000,
          logradouro: 'Rua A',
          numero: '10',
          cidade: id == 'c3' ? 'Ribeirão Preto' : 'Franca',
          estado: 'SP',
          criadoEm: criado,
          status: status,
        );
    for (final contratacao in [
      c('c1', 'Festa junina', '2099-06-10', StatusContratacao.proposta, DateTime(2026, 9, 1)),
      c('c2', 'Réveillon', '2099-12-31', StatusContratacao.confirmada, DateTime(2026, 9, 3)),
      c('c3', 'Aniversário do bar', '2099-03-01', StatusContratacao.cancelada, DateTime(2026, 9, 2)),
    ]) {
      await firestore.collection('contratacoes').doc(contratacao.id).set(contratacao.toMap());
    }
  }

  /// Tela alta o bastante para a lista inteira ser construída.
  void telaAlta(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  List<String> titulosNaTela(WidgetTester tester) => tester
      .widgetList<ContratacaoCard>(find.byType(ContratacaoCard))
      .map((card) => card.contratacao.titulo)
      .toList();

  testWidgets('dono vê só as enviadas, mais recentes primeiro', (tester) async {
    telaAlta(tester);
    await gravarVarias();
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'e1'), const ContratacoesScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TabBar), findsNothing);
    expect(titulosNaTela(tester), ['Réveillon', 'Aniversário do bar', 'Festa junina']);
    expect(find.text('3 de 3'), findsOneWidget);
  });

  testWidgets('filtro por situação, busca e ordem por data do show', (tester) async {
    telaAlta(tester);
    await gravarVarias();
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'e1'), const ContratacoesScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Encerradas'));
    await tester.pumpAndSettle();
    expect(titulosNaTela(tester), ['Aniversário do bar']);

    await tester.tap(find.text('Todas'));
    await tester.enterText(find.byType(TextField), 'ribeirão');
    await tester.pumpAndSettle();
    expect(titulosNaTela(tester), ['Aniversário do bar']);

    await tester.enterText(find.byType(TextField), 'nada disso');
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma contratação com esses filtros.'), findsOneWidget);

    await tester.tap(find.byTooltip('Limpar busca'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mais recentes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Data do show').last);
    await tester.pumpAndSettle();
    expect(titulosNaTela(tester), ['Aniversário do bar', 'Festa junina', 'Réveillon']);
  });

  testWidgets('admin vê as abas Recebidas e Enviadas', (tester) async {
    await tester.pumpWidget(
      _app(
        servicoFake(firestore: firestore, uid: 'adm', admin: true),
        const ContratacoesScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recebidas'), findsOneWidget);
    expect(find.text('Enviadas'), findsOneWidget);
  });

  testWidgets('show realizado: músico avalia e o card mostra a nota (Plano 17)', (tester) async {
    final ontem = Contratacao.diaDe(DateTime.now().subtract(const Duration(days: 2)));
    await firestore.collection('contratacoes').doc('c9').set(
      Contratacao(
        id: 'c9',
        interesseId: 'i1',
        musicoId: 'm1',
        musicoNome: 'Banda',
        donoId: 'e1',
        donoNome: 'Bar Central',
        titulo: 'Show que já passou',
        dia: ontem,
        horaInicio: '20:00',
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
      _app(servicoFake(firestore: firestore, uid: 'm1'), const ContratacoesScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Realizada'), findsWidgets);
    await tester.tap(find.text('Avaliar'));
    await tester.pumpAndSettle();
    // Sem estrela escolhida não envia.
    expect(
      tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Enviar avaliação')).onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('4 estrelas'));
    await tester.enterText(find.widgetWithText(TextField, 'Comentário (opcional)'), 'Bom palco');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar avaliação'));
    await tester.pumpAndSettle();

    expect(find.text('Avaliação enviada. Obrigado!'), findsOneWidget);
    expect(find.text('Você avaliou: 4'), findsOneWidget);
    expect(find.text('Avaliar'), findsNothing);
    final doc = await firestore.collection('avaliacoes').doc('c9_m1').get();
    expect(doc.data()?['avaliadoId'], 'e1');
    expect(doc.data()?['comentario'], 'Bom palco');
  });

  testWidgets('"Adicionar à agenda" só no show confirmado que ainda vai acontecer (Plano 19)', (tester) async {
    Map<String, dynamic> show(String titulo, int diasAFrente) => Contratacao(
      id: '',
      interesseId: 'i1',
      musicoId: 'm1',
      musicoNome: 'Banda',
      donoId: 'e1',
      donoNome: 'Bar Central',
      titulo: titulo,
      dia: Contratacao.diaDe(DateTime.now().add(Duration(days: diasAFrente))),
      horaInicio: '20:00',
      horaFim: '23:00',
      cacheAcordado: 1500,
      logradouro: 'Rua A',
      numero: '10',
      cidade: 'Franca',
      estado: 'SP',
      criadoEm: DateTime(2026, 9, 1),
      status: StatusContratacao.confirmada,
    ).toMap();
    await firestore.collection('contratacoes').doc('futuro').set(show('Show futuro', 5));
    await firestore.collection('contratacoes').doc('passado').set(show('Show passado', -3));
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'm1'), const ContratacoesScreen()),
    );
    await tester.pumpAndSettle();

    final futuro = find.ancestor(of: find.text('Show futuro'), matching: find.byType(Card));
    final passado = find.ancestor(of: find.text('Show passado'), matching: find.byType(Card));
    expect(
      find.descendant(of: futuro, matching: find.text('Adicionar à agenda')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: passado, matching: find.text('Adicionar à agenda')),
      findsNothing,
    );
  });

  testWidgets('Plano 21: músico contrapropõe e o dono aceita o valor pedido', (tester) async {
    await firestore.collection('contratacoes').doc('c5').set(
      Contratacao(
        id: 'c5',
        interesseId: 'i1',
        musicoId: 'm1',
        musicoNome: 'Banda',
        donoId: 'e1',
        donoNome: 'Bar Central',
        titulo: 'Show negociado',
        dia: '2099-03-01',
        horaInicio: '20:00',
        horaFim: '23:00',
        cacheAcordado: 1500,
        logradouro: 'Rua A',
        numero: '10',
        cidade: 'Franca',
        estado: 'SP',
        criadoEm: DateTime(2026, 9, 1),
      ).toMap(),
    );

    // Músico pede R$ 1800.
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'm1'), const ContratacoesScreen()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contrapropor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um valor maior que zero.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Cachê pedido (R\$)'), '1500');
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um valor diferente do proposto.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Cachê pedido (R\$)'), '1800');
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.text('Contraproposta enviada.'), findsOneWidget);
    expect(find.text('Você pediu R\$ 1800.00 — aguardando o contratante.'), findsOneWidget);
    expect(find.text('Contrapropor'), findsNothing);
    expect(find.text('Confirmar'), findsNothing);

    // Dono aceita.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      _app(servicoFake(firestore: firestore, uid: 'e1'), const ContratacoesScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('O músico pediu R\$ 1800.00.'), findsOneWidget);
    await tester.tap(find.text('Aceitar R\$ 1800.00'));
    await tester.pumpAndSettle();

    final doc = await firestore.collection('contratacoes').doc('c5').get();
    expect(doc.data()?['status'], 'proposta');
    expect(doc.data()?['cacheAcordado'], 1800);
    expect(find.text('Valor ajustado após contraproposta.'), findsOneWidget);
  });
}
