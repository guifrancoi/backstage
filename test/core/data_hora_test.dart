import 'package:backstage/core/utils/data_hora.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatarDataCurta: dia, mês abreviado e ano', () {
    expect(formatarDataCurta(DateTime(2026, 6, 28)), '28 jun 2026');
    expect(formatarDataCurta(DateTime(2027, 1, 5)), '5 jan 2027');
  });

  test('formatarDataCurta omite o ano corrente', () {
    final hoje = DateTime(2026, 10, 5);
    expect(formatarDataCurta(DateTime(2026, 12, 1), hoje: hoje), '1 dez');
    expect(formatarDataCurta(DateTime(2027, 3, 1), hoje: hoje), '1 mar 2027');
  });

  test('mesAbreviado cobre os 12 meses', () {
    expect(
      [for (var m = 1; m <= 12; m++) mesAbreviado(DateTime(2026, m))],
      ['jan', 'fev', 'mar', 'abr', 'mai', 'jun',
        'jul', 'ago', 'set', 'out', 'nov', 'dez'],
    );
  });
}
