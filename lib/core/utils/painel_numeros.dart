import '../../models/contratacao.dart';
import '../../models/interesse.dart';

/// Painel de números (Plano 20). Tudo derivado das contratações e dos
/// interesses que o app já carrega — nenhuma coleção nova.

/// Shows realizados num mês (barra do gráfico).
class ShowsDoMes {
  const ShowsDoMes(this.mes, this.quantidade);

  /// Primeiro dia do mês.
  final DateTime mes;
  final int quantidade;
}

/// Números de um lado das contratações: como músico (recebe cachê) ou como
/// dono (paga cachê).
class NumerosDoLado {
  const NumerosDoLado({
    required this.realizadosNoMes,
    required this.realizadosNoAno,
    required this.realizadosNoTotal,
    required this.proximos,
    required this.valorNoAno,
    required this.valorNoTotal,
    required this.propostasPendentes,
    required this.porMes,
  });

  final int realizadosNoMes;
  final int realizadosNoAno;
  final int realizadosNoTotal;

  /// Confirmados de hoje em diante.
  final int proximos;

  /// Soma de `cacheAcordado` dos realizados (recebido pelo músico, pago pelo
  /// dono).
  final double valorNoAno;
  final double valorNoTotal;

  /// Propostas ou contrapropostas ainda sem acordo (Plano 21).
  final int propostasPendentes;

  /// Últimos meses, do mais antigo ao atual.
  final List<ShowsDoMes> porMes;
}

/// Calcula os números de [uid] no lado [comoMusico] (músico ou dono), com
/// [meses] barras no gráfico. "Realizado" = confirmado com o dia já passado,
/// como `Contratacao.realizada`, mas relativo a [agora].
NumerosDoLado calcularNumeros(
  Iterable<Contratacao> contratacoes, {
  required String uid,
  required bool comoMusico,
  required DateTime agora,
  int meses = 6,
}) {
  final hoje = DateTime(agora.year, agora.month, agora.day);
  final minhas = contratacoes.where(
    (c) => comoMusico ? c.musicoId == uid : c.donoId == uid,
  );
  final confirmadas = minhas.where(
    (c) => c.status == StatusContratacao.confirmada,
  );
  final realizadas = confirmadas.where((c) => c.data.isBefore(hoje)).toList();

  bool noAno(Contratacao c) => c.data.year == agora.year;
  bool noMes(Contratacao c) => noAno(c) && c.data.month == agora.month;
  double soma(Iterable<Contratacao> lista) =>
      lista.fold(0, (total, c) => total + c.cacheAcordado);

  return NumerosDoLado(
    realizadosNoMes: realizadas.where(noMes).length,
    realizadosNoAno: realizadas.where(noAno).length,
    realizadosNoTotal: realizadas.length,
    proximos: confirmadas.where((c) => !c.data.isBefore(hoje)).length,
    valorNoAno: soma(realizadas.where(noAno)),
    valorNoTotal: soma(realizadas),
    propostasPendentes: minhas.where((c) => c.emNegociacao).length,
    porMes: [
      for (var i = meses - 1; i >= 0; i--)
        _doMes(realizadas, DateTime(agora.year, agora.month - i)),
    ],
  );
}

ShowsDoMes _doMes(List<Contratacao> realizadas, DateTime mes) => ShowsDoMes(
  mes,
  realizadas
      .where((c) => c.data.year == mes.year && c.data.month == mes.month)
      .length,
);

/// Taxa de aceite das candidaturas enviadas: aceitas ÷ respondidas (aceitas
/// + recusadas). `null` enquanto nenhuma foi respondida.
double? taxaDeAceite(Iterable<Interesse> enviados) {
  final candidaturas = enviados.where(
    (i) => i.tipo == TipoInteresse.candidatura,
  );
  final aceitas = candidaturas
      .where((i) => i.status == StatusInteresse.aceito)
      .length;
  final recusadas = candidaturas
      .where((i) => i.status == StatusInteresse.recusado)
      .length;
  final respondidas = aceitas + recusadas;
  return respondidas == 0 ? null : aceitas / respondidas;
}

/// "R$ 18.500" — sem centavos, com ponto de milhar (PT-BR).
String formatarReais(double valor) {
  final inteiro = valor.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < inteiro.length; i++) {
    if (i > 0 && (inteiro.length - i) % 3 == 0) buffer.write('.');
    buffer.write(inteiro[i]);
  }
  return 'R\$ $buffer';
}
