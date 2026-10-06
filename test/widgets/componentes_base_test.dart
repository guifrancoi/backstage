import 'package:backstage/core/theme/app_colors.dart';
import 'package:backstage/core/theme/app_theme.dart';
import 'package:backstage/widgets/avatar_iniciais.dart';
import 'package:backstage/widgets/bloco_info.dart';
import 'package:backstage/widgets/cabecalho_perfil.dart';
import 'package:backstage/widgets/link_portfolio.dart';
import 'package:backstage/widgets/campo_pesquisa.dart';
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
    await _montar(tester, const Etiqueta('Recusado', tipo: TipoEtiqueta.erro));

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

  group('CampoPesquisa', () {
    testWidgets('espera um pouco antes de avisar e o "x" limpa', (
      tester,
    ) async {
      final avisos = <String>[];
      await _montar(
        tester,
        CampoPesquisa(valor: '', onChanged: avisos.add, dica: 'Buscar'),
      );

      await tester.enterText(find.byType(TextField), 'ro');
      await tester.enterText(find.byType(TextField), 'rock');
      expect(avisos, isEmpty);
      await tester.pump(const Duration(milliseconds: 350));
      expect(avisos, ['rock']);

      await tester.tap(find.byTooltip('Limpar pesquisa'));
      await tester.pump();
      expect(avisos.last, '');
      expect(find.byTooltip('Limpar pesquisa'), findsNothing);
    });

    testWidgets('acompanha mudança de fora sem apagar espaço digitado', (
      tester,
    ) async {
      Widget campo(String valor) =>
          CampoPesquisa(valor: valor, onChanged: (_) {}, dica: 'Buscar');

      await _montar(tester, campo(''));
      await tester.enterText(find.byType(TextField), 'rock ');
      // Quem guarda o termo tira o espaço: o campo não pode perdê-lo.
      await _montar(tester, campo('rock'));
      expect(find.text('rock '), findsOneWidget);

      // "Limpar filtros" (vindo de fora) zera o campo.
      await _montar(tester, campo(''));
      expect(find.text('rock '), findsNothing);
    });
  });

  group('LinkPortfolio', () {
    test('completa o https e recusa link sem endereço', () {
      expect(
        LinkPortfolio.uriDe('instagram.com/banda').toString(),
        'https://instagram.com/banda',
      );
      expect(
        LinkPortfolio.uriDe('http://site.com').toString(),
        'http://site.com',
      );
      expect(LinkPortfolio.uriDe('   '), isNull);
    });

    test('ícone pelo site', () {
      expect(
        LinkPortfolio.iconeDe('instagram.com/x'),
        Icons.camera_alt_outlined,
      );
      expect(
        LinkPortfolio.iconeDe('https://youtu.be/x'),
        Icons.smart_display_outlined,
      );
      expect(
        LinkPortfolio.iconeDe('open.spotify.com/x'),
        Icons.headphones_outlined,
      );
      expect(LinkPortfolio.iconeDe('meusite.com.br'), Icons.link);
    });
  });

  testWidgets('BlocoInfo em grade e CabecalhoPerfil com iniciais', (
    tester,
  ) async {
    await _montar(
      tester,
      // Esticado, como nas telas de detalhe.
      const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CabecalhoPerfil(nome: 'Ana Vieira'),
          GradeBlocos(
            blocos: [
              BlocoInfo(rotulo: 'Cachê médio', valor: r'R$ 1.200'),
              BlocoInfo(rotulo: 'Avaliação', valor: '4,9'),
            ],
          ),
        ],
      ),
    );

    expect(find.text('AV'), findsOneWidget);
    expect(find.text('Ana Vieira'), findsOneWidget);
    // Avatar e nome centralizados no cabeçalho (largura toda da tela).
    final larguraTela =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(tester.getCenter(find.text('AV')).dx, closeTo(larguraTela / 2, 1));
    expect(
      tester.getCenter(find.text('Ana Vieira')).dx,
      closeTo(larguraTela / 2, 1),
    );
    expect(find.text('CACHÊ MÉDIO'), findsOneWidget);
    expect(find.text(r'R$ 1.200'), findsOneWidget);
    // Lado a lado: mesma altura na grade de 2 colunas.
    expect(
      tester.getTopLeft(find.text('CACHÊ MÉDIO')).dy,
      tester.getTopLeft(find.text('AVALIAÇÃO')).dy,
    );
  });

  testWidgets(
    'GradeBlocos iguala a altura da linha; ímpar fica com meia largura',
    (tester) async {
      await _montar(
        tester,
        const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GradeBlocos(
              blocos: [
                BlocoInfo(
                  rotulo: 'Aceite das candidaturas (nenhuma respondida)',
                  valor: '—',
                ),
                BlocoInfo(rotulo: 'Shows', valor: '3'),
                BlocoInfo(rotulo: 'Sozinho', valor: '1'),
              ],
            ),
          ],
        ),
      );

      final cards = find.byType(Card);
      expect(cards, findsNWidgets(3));
      // Rótulo longo quebra linha, e o vizinho acompanha a altura.
      expect(
        tester.getSize(cards.at(0)).height,
        tester.getSize(cards.at(1)).height,
      );
      // O terceiro, sozinho na linha, não ocupa a largura toda.
      expect(
        tester.getSize(cards.at(2)).width,
        tester.getSize(cards.at(1)).width,
      );
    },
  );
}
