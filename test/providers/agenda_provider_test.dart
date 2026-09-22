import 'package:backstage/providers/agenda_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AgendaProvider provider;

  setUp(() => provider = AgendaProvider());
  tearDown(() => provider.dispose());

  test('inicia com as datas locais de exemplo em ordem', () {
    final datas = provider.datasDisponiveis;

    expect(datas, isNotEmpty);
    expect(datas, [...datas]..sort());
  });

  test('adicionarData normaliza o horário e mantém a lista ordenada', () async {
    await provider.adicionarData(DateTime(2026, 1, 5, 18, 30));

    expect(provider.datasDisponiveis.first, DateTime(2026, 1, 5));
    final datas = provider.datasDisponiveis;
    expect(datas, [...datas]..sort());
  });

  test('adicionarData ignora dia já existente, mesmo com outro horário', () async {
    final total = provider.datasDisponiveis.length;
    final existente = provider.datasDisponiveis.first;

    await provider.adicionarData(existente.add(const Duration(hours: 22)));

    expect(provider.datasDisponiveis, hasLength(total));
  });

  test('removerData remove pelo dia, ignorando o horário', () async {
    await provider.adicionarData(DateTime(2026, 7, 10));

    await provider.removerData(DateTime(2026, 7, 10, 23, 59));

    expect(provider.datasDisponiveis, isNot(contains(DateTime(2026, 7, 10))));
  });

  test('carregarDatas não altera nada no modo mock', () async {
    final antes = [...provider.datasDisponiveis];

    await provider.carregarDatas();

    expect(provider.datasDisponiveis, antes);
  });

  test('datasDisponiveis não pode ser alterada de fora', () {
    expect(
      () => provider.datasDisponiveis.add(DateTime(2030)),
      throwsUnsupportedError,
    );
  });
}
