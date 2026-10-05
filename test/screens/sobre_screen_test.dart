import 'package:backstage/core/theme/app_theme.dart';
import 'package:backstage/screens/sobre/sobre_screen.dart';
import 'package:backstage/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Sobre mostra o logo e o objetivo com os espaços certos', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.escuro, home: const SobreScreen()),
    );

    final logo = tester.widget<Image>(
      find.descendant(of: find.byType(AppLogo), matching: find.byType(Image)),
    );
    expect((logo.image as AssetImage).assetName, AppLogo.imagem);

    // Antes os trechos eram colados sem espaço ("casas deshow").
    final objetivo = find.textContaining('casas de show de forma eficiente');
    expect(objetivo, findsOneWidget);
    final texto = tester.widget<Text>(objetivo).data!;
    expect(texto, isNot(contains('deshow')));
    expect(texto, isNot(contains('filtros erecomendação')));
    await tester.scrollUntilVisible(find.text('• Victor Vicentini'), 200);
    expect(find.text('• Victor Vicentini'), findsOneWidget);
  });
}
