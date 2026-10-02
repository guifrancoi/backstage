import 'package:backstage/core/utils/painel_numeros.dart';
import 'package:backstage/models/contratacao.dart';
import 'package:backstage/models/interesse.dart';
import 'package:flutter_test/flutter_test.dart';

final _agora = DateTime(2026, 10, 15, 12);

Contratacao _show(
  String dia, {
  double cache = 1000,
  StatusContratacao status = StatusContratacao.confirmada,
  String musicoId = 'm1',
  String donoId = 'e1',
}) => Contratacao(
  id: dia,
  interesseId: 'i1',
  musicoId: musicoId,
  musicoNome: 'Banda',
  donoId: donoId,
  donoNome: 'Bar',
  titulo: 'Show',
  dia: dia,
  horaInicio: '20:00',
  horaFim: '23:00',
  cacheAcordado: cache,
  logradouro: 'Rua A',
  numero: '1',
  cidade: 'Franca',
  estado: 'SP',
  criadoEm: DateTime(2026, 1, 1),
  status: status,
);

Interesse _candidatura(String id, StatusInteresse status) => Interesse(
  id: id,
  tipo: TipoInteresse.candidatura,
  remetenteId: 'm1',
  remetenteNome: 'Banda',
  destinatarioId: 'e1',
  musicoId: 'm1',
  musicoNome: 'Banda',
  criadoEm: DateTime(2026, 9, 1),
  status: status,
);

void main() {
  final lista = [
    _show('2026-10-03', cache: 1500), // realizado no mês
    _show('2026-09-20', cache: 1000), // realizado no ano
    _show('2026-05-10', cache: 500), // realizado, fora dos 6 meses do gráfico
    _show('2025-12-01', cache: 2000), // ano passado
    _show('2026-10-15'), // hoje: ainda não realizado → próximo
    _show('2026-11-01'), // próximo
    _show('2026-10-20', status: StatusContratacao.proposta),
    _show('2026-10-01', status: StatusContratacao.cancelada),
    _show('2026-10-02', musicoId: 'outro', donoId: 'outro'),
  ];

  group('calcularNumeros', () {
    test('como músico: realizados, próximos, valor e propostas', () {
      final n = calcularNumeros(lista, uid: 'm1', comoMusico: true, agora: _agora);

      expect(n.realizadosNoMes, 1);
      expect(n.realizadosNoAno, 3);
      expect(n.realizadosNoTotal, 4);
      expect(n.proximos, 2);
      expect(n.valorNoAno, 3000);
      expect(n.valorNoTotal, 5000);
      expect(n.propostasPendentes, 1);
    });

    test('como dono conta o mesmo show pelo outro lado', () {
      final n = calcularNumeros(lista, uid: 'e1', comoMusico: false, agora: _agora);
      expect(n.realizadosNoAno, 3);
      expect(calcularNumeros(lista, uid: 'e1', comoMusico: true, agora: _agora).realizadosNoTotal, 0);
    });

    test('gráfico: 6 meses do mais antigo ao atual, atravessando o ano', () {
      final n = calcularNumeros(
        [..._lista2025()],
        uid: 'm1',
        comoMusico: true,
        agora: DateTime(2026, 2, 10),
      );

      expect(n.porMes.map((m) => '${m.mes.year}-${m.mes.month}'), [
        '2025-9', '2025-10', '2025-11', '2025-12', '2026-1', '2026-2',
      ]);
      expect(n.porMes.map((m) => m.quantidade), [0, 0, 0, 2, 1, 0]);
    });
  });

  group('taxaDeAceite', () {
    test('aceitas ÷ respondidas; pendentes e convites não contam', () {
      final taxa = taxaDeAceite([
        _candidatura('a', StatusInteresse.aceito),
        _candidatura('b', StatusInteresse.aceito),
        _candidatura('c', StatusInteresse.aceito),
        _candidatura('d', StatusInteresse.recusado),
        _candidatura('e', StatusInteresse.pendente),
      ]);
      expect(taxa, 0.75);
    });

    test('sem resposta ainda: null', () {
      expect(taxaDeAceite([_candidatura('e', StatusInteresse.pendente)]), isNull);
      expect(taxaDeAceite(const []), isNull);
    });
  });

  test('formatarReais: ponto de milhar e sem centavos', () {
    expect(formatarReais(0), 'R\$ 0');
    expect(formatarReais(950), 'R\$ 950');
    expect(formatarReais(18500), 'R\$ 18.500');
    expect(formatarReais(1234567.6), 'R\$ 1.234.568');
  });
}

List<Contratacao> _lista2025() => [
  _show('2025-12-05'),
  _show('2025-12-20'),
  _show('2026-01-10'),
];
