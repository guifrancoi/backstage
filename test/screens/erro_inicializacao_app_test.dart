import 'package:backstage/screens/erro/erro_inicializacao_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra o erro e "Tentar novamente" chama a nova tentativa', (tester) async {
    var tentativas = 0;
    await tester.pumpWidget(
      ErroInicializacaoApp(
        onTentarNovamente: () async {
          tentativas++;
          await Future<void>.delayed(const Duration(milliseconds: 100));
        },
      ),
    );

    expect(find.text('Não foi possível conectar ao Backstage'), findsOneWidget);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();

    expect(tentativas, 1);
    expect(find.text('Conectando...'), findsOneWidget);
    // Botão desabilitado enquanto tenta: outro toque não dispara de novo.
    await tester.tap(find.text('Conectando...'));
    expect(tentativas, 1);

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
