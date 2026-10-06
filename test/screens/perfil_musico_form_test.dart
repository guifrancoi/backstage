import 'package:backstage/models/musico.dart';
import 'package:backstage/screens/perfil/perfil_musico_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// PNG 1×1 válido, em base64 (o que a galeria "devolveria").
const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

final _inicial = Musico(
  id: 'u1',
  nomeArtistico: 'Banda',
  generoMusical: 'Rock',
  cidade: 'Franca',
  descricao: 'Rock autoral',
  cacheMedio: 1000,
  portfolioLinks: const [],
);

void main() {
  late Musico? salvo;

  Widget app({Musico? inicial, Future<String?> Function()? escolherFoto}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PerfilMusicoForm(
            inicial: inicial ?? _inicial,
            onSalvar: (perfil) async => salvo = perfil,
            escolherFoto: escolherFoto ?? () async => _png,
          ),
        ),
      ),
    );
  }

  Future<void> tocar(WidgetTester tester, String texto) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.ensureVisible(find.text(texto).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(texto).last);
    await tester.pumpAndSettle();
  }

  setUp(() => salvo = null);

  testWidgets('escolhe foto e preenche os dados do show', (tester) async {
    await tester.pumpWidget(app());

    await tocar(tester, 'Escolher foto');
    expect(find.text('Alterar foto'), findsOneWidget);
    expect(find.text('Remover foto'), findsOneWidget);

    // Integrantes só aparece para banda.
    expect(
      find.widgetWithText(TextFormField, 'Número de integrantes'),
      findsNothing,
    );
    await tocar(tester, 'Banda');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Número de integrantes'),
      '5',
    );
    await tocar(tester, 'Tenho equipamento próprio');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Duração do show (minutos)'),
      '120',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Repertório'),
      'Autoral',
    );
    await tocar(tester, 'Salvar');

    expect(salvo?.foto, _png);
    expect(salvo?.formacao, Formacao.banda);
    expect(salvo?.integrantes, 5);
    expect(salvo?.equipamentoProprio, isTrue);
    expect(salvo?.duracaoShowMin, 120);
    expect(salvo?.repertorio, 'Autoral');
  });

  testWidgets('sem dados do show salva como antes (todos opcionais)', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    await tocar(tester, 'Salvar');

    expect(salvo, isNotNull);
    expect(salvo?.foto, isNull);
    expect(salvo?.formacao, isNull);
    expect(salvo?.duracaoShowMin, isNull);
    expect(salvo?.repertorio, isNull);
  });

  testWidgets('duração fora do intervalo não salva', (tester) async {
    await tester.pumpWidget(app());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Duração do show (minutos)'),
      '5',
    );
    await tocar(tester, 'Salvar');

    expect(salvo, isNull);
    expect(find.text('Informe uma duração entre 10 e 600.'), findsOneWidget);
  });

  testWidgets('trocar banda por trio descarta os integrantes', (tester) async {
    await tester.pumpWidget(
      app(inicial: _inicial.copyWith(formacao: Formacao.banda, integrantes: 6)),
    );

    await tocar(tester, 'Banda');
    await tocar(tester, 'Trio');
    await tocar(tester, 'Salvar');

    expect(salvo?.formacao, Formacao.trio);
    expect(salvo?.integrantes, isNull);
  });

  testWidgets('remover foto salva sem foto', (tester) async {
    await tester.pumpWidget(app(inicial: _inicial.copyWith(foto: _png)));

    await tocar(tester, 'Remover foto');
    await tocar(tester, 'Salvar');

    expect(salvo?.foto, isNull);
  });

  testWidgets('foto grande demais é recusada com aviso', (tester) async {
    final enorme = 'a' * (Musico.tamanhoMaximoFoto + 1);
    await tester.pumpWidget(app(escolherFoto: () async => enorme));

    await tocar(tester, 'Escolher foto');

    expect(
      find.text('Foto muito grande. Escolha uma imagem JPG ou PNG.'),
      findsOneWidget,
    );
    expect(find.text('Remover foto'), findsNothing);
  });

  testWidgets('cachê inteiro aparece sem casas decimais', (tester) async {
    await tester.pumpWidget(app());
    expect(find.widgetWithText(TextFormField, '1000'), findsOneWidget);
  });

  testWidgets('cachê com centavos mantém as casas', (tester) async {
    await tester.pumpWidget(
      app(inicial: _inicial.copyWith(cacheMedio: 1275.5)),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, '1275.50'), findsOneWidget);
  });
}
