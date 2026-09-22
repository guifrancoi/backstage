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

Musico _musico({bool interesseEnviado = false}) => Musico(
  id: '1',
  nomeArtistico: 'Banda Eclipse',
  generoMusical: 'Rock',
  cidade: 'Franca',
  descricao: 'Banda de rock.',
  cacheMedio: 1200,
  portfolioLinks: const [],
  datasDisponiveis: const [],
  interesseEnviado: interesseEnviado,
);

Oportunidade _oportunidade({bool interesseEnviado = false}) => Oportunidade(
  id: '1',
  titulo: 'Show de sexta',
  descricao: 'Bar no centro.',
  cidade: 'Ribeirão Preto',
  generoMusical: 'MPB',
  dataEvento: DateTime(2026, 3, 7),
  cacheOferecido: 900,
  contratante: 'Bar Central',
  logradouro: 'Rua A',
  numero: '1',
  estado: 'SP',
  interesseEnviado: interesseEnviado,
);

ElevatedButton _botaoInteresse(WidgetTester tester) => tester.widget(
  find.ancestor(
    of: find.textContaining('Interess'),
    matching: find.byType(ElevatedButton),
  ),
);

void main() {
  group('MusicoCard', () {
    testWidgets('exibe dados e dispara os callbacks', (tester) async {
      var interesse = 0;
      var detalhes = 0;
      await tester.pumpWidget(_app(MusicoCard(
        musico: _musico(),
        onDemonstrarInteresse: () => interesse++,
        onVerDetalhes: () => detalhes++,
      )));

      expect(find.text('Banda Eclipse'), findsOneWidget);
      expect(find.text('Rock • Franca'), findsOneWidget);
      expect(find.text('R\$ 1200'), findsOneWidget);

      await tester.tap(find.text('Interessar-se'));
      await tester.tap(find.text('Ver detalhes'));

      expect(interesse, 1);
      expect(detalhes, 1);
    });

    testWidgets('desabilita o botão quando o interesse já foi enviado', (tester) async {
      await tester.pumpWidget(_app(MusicoCard(
        musico: _musico(interesseEnviado: true),
        onDemonstrarInteresse: () => fail('não deveria ser chamado'),
        onVerDetalhes: () {},
      )));

      expect(find.text('Interesse enviado'), findsOneWidget);
      expect(_botaoInteresse(tester).onPressed, isNull);
    });
  });

  group('OportunidadeCard', () {
    testWidgets('formata data dd/MM/yyyy e cachê com centavos', (tester) async {
      await tester.pumpWidget(_app(OportunidadeCard(
        oportunidade: _oportunidade(),
        onDemonstrarInteresse: () {},
        onVerDetalhes: () {},
      )));

      expect(find.text('Data: 07/03/2026'), findsOneWidget);
      expect(find.text('Cachê: R\$ 900.00'), findsOneWidget);
      expect(find.text('Contratante: Bar Central'), findsOneWidget);
    });

    testWidgets('desabilita o botão quando o interesse já foi enviado', (tester) async {
      await tester.pumpWidget(_app(OportunidadeCard(
        oportunidade: _oportunidade(interesseEnviado: true),
        onDemonstrarInteresse: () {},
        onVerDetalhes: () {},
      )));

      expect(find.text('Interesse enviado'), findsOneWidget);
      expect(_botaoInteresse(tester).onPressed, isNull);
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
    Mensagem mensagem({required bool minha}) => Mensagem(
      id: '1',
      remetenteId: 'u1',
      texto: 'Olá',
      dataHora: DateTime(2026),
      enviadaPorMim: minha,
    );

    testWidgets('alinha à direita as mensagens enviadas por mim', (tester) async {
      await tester.pumpWidget(_app(MensagemBubble(mensagem: mensagem(minha: true))));

      final coluna = tester.widget<Column>(find.byType(Column).first);
      expect(coluna.crossAxisAlignment, CrossAxisAlignment.end);
    });

    testWidgets('alinha à esquerda as mensagens recebidas', (tester) async {
      await tester.pumpWidget(_app(MensagemBubble(mensagem: mensagem(minha: false))));

      final coluna = tester.widget<Column>(find.byType(Column).first);
      expect(coluna.crossAxisAlignment, CrossAxisAlignment.start);
    });
  });
}
