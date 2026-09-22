import 'package:backstage/data/mock_data.dart';
import 'package:backstage/providers/oportunidade_provider.dart';
import 'package:backstage/routes/app_routes.dart';
import 'package:backstage/screens/busca/lista_musicos_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _app(OportunidadeProvider provider) {
  return ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp(
      home: const ListaMusicosScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.detalheMusico) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(body: Text('Detalhe ${settings.arguments}')),
          );
        }
        return null;
      },
    ),
  );
}

void main() {
  late OportunidadeProvider provider;

  setUp(() => provider = OportunidadeProvider());
  tearDown(() => provider.dispose());

  testWidgets('lista os músicos do provider', (tester) async {
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    for (final musico in MockData.musicos) {
      expect(find.text(musico.nomeArtistico), findsOneWidget);
    }
  });

  testWidgets('mostra mensagem quando o filtro não encontra ninguém', (tester) async {
    provider.pesquisarMusicos('inexistente');
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhum músico encontrado com os filtros informados.'),
      findsOneWidget,
    );
  });

  testWidgets('confirmar interesse marca o card e mostra SnackBar', (tester) async {
    provider.pesquisarMusicos('Eclipse');
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Interessar-se'));
    await tester.pumpAndSettle();
    expect(find.text('Deseja demonstrar interesse neste artista?'), findsOneWidget);

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Interesse enviado'), findsOneWidget);
    expect(find.text('Interesse no artista enviado com sucesso!'), findsOneWidget);
    expect(provider.musicosComInteresse.map((m) => m.id), ['1']);
  });

  testWidgets('cancelar o diálogo não registra interesse', (tester) async {
    provider.pesquisarMusicos('Eclipse');
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Interessar-se'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Interessar-se'), findsOneWidget);
    expect(provider.musicosComInteresse, isEmpty);
  });

  testWidgets('Ver detalhes navega passando o id do músico', (tester) async {
    provider.pesquisarMusicos('Eclipse');
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver detalhes'));
    await tester.pumpAndSettle();

    expect(find.text('Detalhe 1'), findsOneWidget);
  });
}
