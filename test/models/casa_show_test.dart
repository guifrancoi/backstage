import 'package:backstage/models/casa_show.dart';
import 'package:flutter_test/flutter_test.dart';

CasaShow _casaShow() => CasaShow(
  id: 'e1',
  nome: 'Bar Central',
  cidade: 'Ribeirão Preto',
  capacidade: 120,
  estilosDesejados: ['Rock', 'MPB'],
  descricao: 'Bar com música ao vivo aos finais de semana.',
  contato: '16999999999',
  cnpj: '12.345.678/0001-90',
);

void main() {
  group('CasaShow', () {
    test('toMap e fromMap preservam todos os campos (id fora do mapa)', () {
      final original = _casaShow();

      final map = original.toMap();
      final copia = CasaShow.fromMap('e1', map);

      expect(map.containsKey('id'), isFalse);
      expect(copia.id, 'e1');
      expect(copia.nome, original.nome);
      expect(copia.cidade, original.cidade);
      expect(copia.capacidade, original.capacidade);
      expect(copia.estilosDesejados, original.estilosDesejados);
      expect(copia.descricao, original.descricao);
      expect(copia.contato, original.contato);
      expect(copia.cnpj, original.cnpj);
    });

    test('fromMap aplica valores padrão para campos ausentes', () {
      final casaShow = CasaShow.fromMap('x', {});

      expect(casaShow.nome, '');
      expect(casaShow.cidade, '');
      expect(casaShow.capacidade, 0);
      expect(casaShow.estilosDesejados, isEmpty);
      expect(casaShow.descricao, '');
      expect(casaShow.contato, '');
      expect(casaShow.cnpj, '');
    });

    test('fromMap converte capacidade double para int', () {
      final casaShow = CasaShow.fromMap('x', {'capacidade': 80.0});

      expect(casaShow.capacidade, 80);
    });

    test('copyWith altera só os campos informados', () {
      final original = _casaShow();

      final alterado = original.copyWith(cidade: 'Franca', capacidade: 200);

      expect(alterado.cidade, 'Franca');
      expect(alterado.capacidade, 200);
      expect(alterado.nome, original.nome);
      expect(original.cidade, 'Ribeirão Preto');
    });

    test('endereço, cep e oculto fazem ida e volta no mapa', () {
      final original = _casaShow().copyWith(
        logradouro: 'Rua A',
        numero: '10',
        estado: 'SP',
        cep: '14400-000',
        oculto: true,
      );

      final copia = CasaShow.fromMap('e1', original.toMap());

      expect(copia.logradouro, 'Rua A');
      expect(copia.numero, '10');
      expect(copia.estado, 'SP');
      expect(copia.cep, '14400-000');
      expect(copia.oculto, isTrue);
      expect(_casaShow().toMap().containsKey('cep'), isFalse);
      expect(CasaShow.fromMap('x', {}).oculto, isFalse);
    });

    test('completo exige nome, cidade, endereço e contato', () {
      final semEndereco = _casaShow();
      final completo = semEndereco.copyWith(
        logradouro: 'Rua A',
        numero: '10',
        estado: 'SP',
      );

      expect(semEndereco.completo, isFalse);
      expect(completo.completo, isTrue);
      expect(completo.copyWith(contato: ' ').completo, isFalse);
      // Opcionais vazios não atrapalham.
      expect(
        completo.copyWith(cnpj: '', descricao: '', estilosDesejados: []).completo,
        isTrue,
      );
    });
  });
}
