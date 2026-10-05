import 'package:backstage/core/utils/texto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizarTexto tira acento, maiúsculas e espaços das pontas', () {
    expect(normalizarTexto('  São JOÃO da Boa Vista '), 'sao joao da boa vista');
    expect(normalizarTexto('Forró Pé de Serra'), 'forro pe de serra');
  });

  test('contemTermo procura em qualquer campo; termo vazio casa tudo', () {
    expect(contemTermo('acustico', ['Duo Acústico Sol', 'MPB']), isTrue);
    expect(contemTermo('franca', ['Banda', 'Franca']), isTrue);
    expect(contemTermo('jazz', ['Banda', 'Rock']), isFalse);
    expect(contemTermo('   ', ['qualquer']), isTrue);
  });
}
