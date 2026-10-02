import 'package:backstage/core/utils/compatibilidade.dart';
import 'package:backstage/models/musico.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/firebase_fake.dart';

final _hoje = DateTime(2099, 1, 1);

/// Rock, Franca, cachê 1000 x oportunidade Rock, Franca, cachê 1000 (2099).
Compatibilidade? _avaliar({
  Musico? musico,
  String genero = 'Rock',
  String cidade = 'Franca',
  double cache = 1000,
  String donoId = 'e1',
  bool ocupado = false,
  bool bloqueado = false,
  bool agendaConhecida = true,
  bool jaTemInteresse = false,
}) {
  return avaliarCompatibilidade(
    musico: musico ?? musicoTeste(),
    oportunidade: oportunidadeTeste(
      generoMusical: genero,
      cidade: cidade,
      donoId: donoId,
    ).copyWith(cacheOferecido: cache),
    hoje: _hoje,
    ocupado: ocupado,
    bloqueado: bloqueado,
    agendaConhecida: agendaConhecida,
    jaTemInteresse: jaTemInteresse,
  );
}

void main() {
  group('avaliarCompatibilidade', () {
    test('tudo bate (sem dados do Plano 14): 90, motivos na ordem dos pesos', () {
      final c = _avaliar()!;

      expect(c.nota, 90);
      expect(c.motivos, [
        'Mesmo gênero',
        'Mesma cidade',
        'Cachê dentro do oferecido',
        'Livre no dia',
      ]);
      expect(c.sugerivel, isTrue);
    });

    test('formação e equipamento completam os 100', () {
      final musico = musicoTeste().copyWith(
        formacao: Formacao.trio,
        equipamentoProprio: true,
      );

      final c = _avaliar(musico: musico)!;

      expect(c.nota, 100);
      expect(c.motivos, containsAll(['Trio', 'Equipamento próprio']));
    });

    test('cada critério soma o seu peso', () {
      expect(_avaliar(genero: 'MPB')!.nota, 90 - PesosCompatibilidade.genero);
      expect(_avaliar(cidade: 'Ribeirão Preto')!.nota, 90 - PesosCompatibilidade.cidade);
      expect(_avaliar(cache: 999)!.nota, 90 - PesosCompatibilidade.cache);
      expect(
        _avaliar(agendaConhecida: false)!.nota,
        90 - PesosCompatibilidade.livreNoDia,
      );
    });

    test('cidade compara sem maiúsculas, espaços nem acentos', () {
      final musico = musicoTeste(cidade: ' ribeirao preto ');

      expect(
        _avaliar(musico: musico, cidade: 'Ribeirão Preto')!.motivos,
        contains('Mesma cidade'),
      );
    });

    test('nota mínima: abaixo de 50 não é sugerível', () {
      // Só cachê + livre no dia = 30.
      final c = _avaliar(genero: 'MPB', cidade: 'Outra')!;

      expect(c.nota, 30);
      expect(c.sugerivel, isFalse);
    });

    test('eliminatórios devolvem null', () {
      expect(_avaliar(ocupado: true), isNull);
      expect(_avaliar(bloqueado: true), isNull);
      expect(_avaliar(jaTemInteresse: true), isNull);
      expect(_avaliar(donoId: ''), isNull, reason: 'catálogo sem dono');
      expect(_avaliar(donoId: 'm1'), isNull, reason: 'oportunidade do próprio músico');
      expect(
        _avaliar(musico: musicoTeste().copyWith(oculto: true)),
        isNull,
      );
      expect(
        avaliarCompatibilidade(
          musico: musicoTeste(),
          oportunidade: oportunidadeTeste().copyWith(dataEvento: DateTime(2098)),
          hoje: _hoje,
        ),
        isNull,
        reason: 'vencida',
      );
    });
  });

  group('ordenarSugestoes', () {
    Sugestao<String> s(String nome, int nota, {bool assinante = false}) =>
        Sugestao(nome, Compatibilidade(nota, const []), assinante: assinante);

    test('maior nota primeiro; assinante só desempata; tira as abaixo do mínimo', () {
      final ordenadas = ordenarSugestoes(
        [
          s('B', 70),
          s('A', 70),
          s('Assinante', 70, assinante: true),
          s('Top', 90),
          s('Assinante fraco', 60, assinante: true),
          s('Baixa', 40, assinante: true),
        ],
        desempate: (a, b) => a.compareTo(b),
      );

      expect(ordenadas.map((x) => x.item), [
        'Top',
        'Assinante',
        'A',
        'B',
        'Assinante fraco',
      ]);
    });

    test('respeita o limite', () {
      final ordenadas = ordenarSugestoes(
        [s('A', 90), s('B', 80), s('C', 70)],
        desempate: (a, b) => a.compareTo(b),
        limite: 2,
      );

      expect(ordenadas.map((x) => x.item), ['A', 'B']);
    });
  });

  test('assinantesPrimeiro mantém a ordem de cada grupo', () {
    expect(
      assinantesPrimeiro(['a', 'B', 'c', 'D', 'e'], (x) => x == x.toUpperCase()),
      ['B', 'D', 'a', 'c', 'e'],
    );
  });
}
