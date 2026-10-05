import 'package:backstage/core/theme/app_colors.dart';
import 'package:backstage/core/theme/app_theme.dart';
import 'package:backstage/widgets/avatar_iniciais.dart';
import 'package:backstage/widgets/estados.dart';
import 'package:backstage/widgets/etiqueta.dart';
import 'package:backstage/widgets/primary_button.dart';
import 'package:backstage/widgets/texto_valor.dart';
import 'package:backstage/widgets/titulo_secao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Componentes base do Plano 8, montados com o tema do app.
Future<void> _montar(WidgetTester tester, Widget filho) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.escuro,
      home: Scaffold(body: filho),
    ),
  );
}

void main() {
  group('AvatarIniciais', () {
    test('iniciais da primeira e da última palavra', () {
      expect(AvatarIniciais.iniciaisDe('Ana Vieira'), 'AV');
      expect(AvatarIniciais.iniciaisDe('banda do trovão azul'), 'BA');
      expect(AvatarIniciais.iniciaisDe('  luna  '), 'L');
      expect(AvatarIniciais.iniciaisDe(''), '?');
    });

    testWidgets('sem foto mostra as iniciais', (tester) async {
      await _montar(tester, const AvatarIniciais(nome: 'Rafa Cunha'));

      expect(find.text('RC'), findsOneWidget);
      expect(find.bySemanticsLabel('Foto de Rafa Cunha'), findsOneWidget);
    });
  });

  testWidgets('Etiqueta usa a cor do tipo', (tester) async {
    await _montar(
      tester,
      const Etiqueta('Recusado', tipo: TipoEtiqueta.erro),
    );

    final texto = tester.widget<Text>(find.text('Recusado'));
    expect(texto.style?.color, AppColors.erro);
  });

  testWidgets('TextoValor formata em reais no verde', (tester) async {
    await _montar(tester, const TextoValor(3500));

    final texto = tester.widget<Text>(find.text('R\$ 3.500'));
    expect(texto.style?.color, AppColors.sucesso);
  });

  testWidgets('TituloSecao mostra a ação só com callback', (tester) async {
    var tocou = false;
    await _montar(
      tester,
      Column(
        children: [
          TituloSecao(
            'Em destaque',
            rotuloAcao: 'Ver mais',
            onAcao: () => tocou = true,
          ),
          const TituloSecao('Sem ação', rotuloAcao: 'Ver todos'),
        ],
      ),
    );

    expect(find.text('Ver todos'), findsNothing);
    await tester.tap(find.text('Ver mais'));
    expect(tocou, isTrue);
  });

  testWidgets('EstadoVazio e EstadoErro com ação', (tester) async {
    var tentou = false;
    await _montar(
      tester,
      Column(
        children: [
          const Expanded(
            child: EstadoVazio(
              icone: Icons.music_off,
              titulo: 'Nenhum músico',
              mensagem: 'Tente outro filtro.',
            ),
          ),
          Expanded(
            child: EstadoErro(
              mensagem: 'Sem conexão.',
              onTentarNovamente: () => tentou = true,
            ),
          ),
        ],
      ),
    );

    expect(find.text('Nenhum músico'), findsOneWidget);
    expect(find.text('Tente outro filtro.'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    expect(tentou, isTrue);
  });

  group('PrimaryButton', () {
    testWidgets('carregando desabilita e troca o texto', (tester) async {
      await _montar(
        tester,
        PrimaryButton(text: 'Entrar', onPressed: () {}, carregando: true),
      );

      final botao = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(botao.onPressed, isNull);
      expect(find.text('Entrar'), findsNothing);
      expect(find.bySemanticsLabel('Carregando'), findsOneWidget);
    });

    testWidgets('com ícone e habilitado', (tester) async {
      var tocou = false;
      await _montar(
        tester,
        PrimaryButton(
          text: 'Salvar',
          icone: Icons.check,
          onPressed: () => tocou = true,
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar'));
      expect(tocou, isTrue);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
