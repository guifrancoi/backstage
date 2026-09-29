import 'package:backstage/models/mensagem.dart';
import 'package:backstage/models/musico.dart';
import 'package:backstage/models/oportunidade.dart';
import 'package:backstage/widgets/custom_text_field.dart';
import 'package:backstage/widgets/mensagem_bubble.dart';
import 'package:backstage/widgets/musico_card.dart';
import 'package:backstage/widgets/oportunidade_card.dart';
import 'package:backstage/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

Musico _musico() => Musico(
  id: '1',
  nomeArtistico: 'Banda Eclipse',
  generoMusical: 'Rock',
  cidade: 'Franca',
  descricao: 'Banda de rock.',
  cacheMedio: 1200,
  portfolioLinks: const [],
);

Oportunidade _oportunidade() => Oportunidade(
  id: '1',
  titulo: 'Show de sexta',
  descricao: 'Bar no centro.',
  cidade: 'Ribeirão Preto',
  generoMusical: 'MPB',
  dataEvento: DateTime(2026, 3, 7),
  cacheOferecido: 900,
  contratante: 'Bar Central',
  donoId: 'estabelecimento1',
  logradouro: 'Rua A',
  numero: '1',
  estado: 'SP',
);

ElevatedButton _botao(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.byType(ElevatedButton));

void main() {
  group('MusicoCard', () {
    testWidgets('exibe dados e dispara os callbacks', (tester) async {
      var convites = 0;
      var detalhes = 0;
      await tester.pumpWidget(_app(MusicoCard(
        musico: _musico(),
        onConvidar: () => convites++,
        onVerDetalhes: () => detalhes++,
      )));

      expect(find.text('Banda Eclipse'), findsOneWidget);
      expect(find.text('Rock • Franca'), findsOneWidget);
      expect(find.text('R\$ 1200'), findsOneWidget);

      await tester.tap(find.text('Convidar'));
      await tester.tap(find.text('Ver detalhes'));

      expect(convites, 1);
      expect(detalhes, 1);
    });

    testWidgets('desabilita o botão com o status do convite enviado', (tester) async {
      await tester.pumpWidget(_app(MusicoCard(
        musico: _musico(),
        onConvidar: () => fail('não deveria ser chamado'),
        statusConvite: 'Convite enviado',
        onVerDetalhes: () {},
      )));

      expect(find.text('Convite enviado'), findsOneWidget);
      expect(_botao(tester).onPressed, isNull);
    });

    testWidgets('sem onConvidar nem status, o botão some', (tester) async {
      await tester.pumpWidget(_app(MusicoCard(
        musico: _musico(),
        onVerDetalhes: () {},
      )));

      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text('Ver detalhes'), findsOneWidget);
    });
  });

  group('OportunidadeCard', () {
    testWidgets('formata data dd/MM/yyyy e cachê com centavos', (tester) async {
      await tester.pumpWidget(_app(OportunidadeCard(
        oportunidade: _oportunidade(),
        onCandidatar: () {},
        onVerDetalhes: () {},
      )));

      expect(find.text('Data: 07/03/2026'), findsOneWidget);
      expect(find.text('Cachê: R\$ 900.00'), findsOneWidget);
      expect(find.text('Contratante: Bar Central'), findsOneWidget);
      expect(find.text('Candidatar-se'), findsOneWidget);
    });

    testWidgets('desabilita o botão com o status da candidatura', (tester) async {
      await tester.pumpWidget(_app(OportunidadeCard(
        oportunidade: _oportunidade(),
        onCandidatar: () {},
        statusCandidatura: 'Recusado',
        onVerDetalhes: () {},
      )));

      expect(find.text('Recusado'), findsOneWidget);
      expect(_botao(tester).onPressed, isNull);
    });

    testWidgets('sem onCandidatar nem status, o botão some', (tester) async {
      await tester.pumpWidget(_app(OportunidadeCard(
        oportunidade: _oportunidade(),
        onVerDetalhes: () {},
      )));

      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  group('PrimaryButton', () {
    testWidgets('fica desabilitado com onPressed nulo', (tester) async {
      await tester.pumpWidget(_app(const PrimaryButton(text: 'Salvar', onPressed: null)));

      final botao = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(botao.onPressed, isNull);
      expect(find.text('Salvar'), findsOneWidget);
    });

    testWidgets('ocupa a largura toda e chama onPressed', (tester) async {
      var cliques = 0;
      await tester.pumpWidget(_app(PrimaryButton(text: 'Salvar', onPressed: () => cliques++)));

      await tester.tap(find.byType(ElevatedButton));

      expect(cliques, 1);
      expect(tester.getSize(find.byType(ElevatedButton)).width, 800);
    });
  });

  group('CustomTextField', () {
    testWidgets('mostra o label, oculta senha e aplica o validador', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(_app(Form(
        key: formKey,
        child: CustomTextField(
          controller: TextEditingController(),
          label: 'Senha',
          obscureText: true,
          validator: (v) => (v ?? '').isEmpty ? 'Obrigatório' : null,
        ),
      )));

      expect(find.text('Senha'), findsOneWidget);
      final campo = tester.widget<EditableText>(find.byType(EditableText));
      expect(campo.obscureText, isTrue);

      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text('Obrigatório'), findsOneWidget);
    });
  });

  group('MensagemBubble', () {
    final mensagem = Mensagem(
      id: '1',
      remetenteId: 'u1',
      texto: 'Olá',
      dataHora: DateTime(2026),
    );

    testWidgets('alinha à direita as mensagens enviadas por mim', (tester) async {
      await tester.pumpWidget(
        _app(MensagemBubble(mensagem: mensagem, enviadaPorMim: true)),
      );

      final coluna = tester.widget<Column>(find.byType(Column).first);
      expect(coluna.crossAxisAlignment, CrossAxisAlignment.end);
    });

    testWidgets('alinha à esquerda as mensagens recebidas', (tester) async {
      await tester.pumpWidget(
        _app(MensagemBubble(mensagem: mensagem, enviadaPorMim: false)),
      );

      final coluna = tester.widget<Column>(find.byType(Column).first);
      expect(coluna.crossAxisAlignment, CrossAxisAlignment.start);
    });
  });
}
