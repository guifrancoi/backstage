import 'contratacao.dart';
import 'oportunidade.dart';

/// Critérios da lista de oportunidades (Plano 12). Imutável: a tela monta um
/// novo com `copyWith` e o `OportunidadeProvider` o aplica com [aplicar].
/// Não é persistido.
class FiltroOportunidades {
  const FiltroOportunidades({
    this.genero,
    this.cidade,
    this.cacheMinimo,
    this.de,
    this.ate,
    this.soDiasLivres = false,
  });

  final String? genero;
  final String? cidade;
  final double? cacheMinimo;

  /// Período do evento (dias, inclusive).
  final DateTime? de;
  final DateTime? ate;

  /// Só do músico: dias em que ele está livre — sem show confirmado
  /// (`ocupacoes`) e sem bloqueio (`bloqueios`).
  final bool soDiasLivres;

  /// Quantos critérios estão ligados (contador do botão "Filtrar").
  int get ativos => [
    genero != null && genero!.isNotEmpty,
    cidade != null && cidade!.trim().isNotEmpty,
    cacheMinimo != null,
    de != null,
    ate != null,
    soDiasLivres,
  ].where((ligado) => ligado).length;

  bool get vazio => ativos == 0;

  /// `copyWith` com `limpar*` para desligar um critério opcional (null).
  FiltroOportunidades copyWith({
    String? genero,
    String? cidade,
    double? cacheMinimo,
    DateTime? de,
    DateTime? ate,
    bool? soDiasLivres,
    bool limparGenero = false,
    bool limparCidade = false,
    bool limparCacheMinimo = false,
    bool limparDe = false,
    bool limparAte = false,
  }) {
    return FiltroOportunidades(
      genero: limparGenero ? null : (genero ?? this.genero),
      cidade: limparCidade ? null : (cidade ?? this.cidade),
      cacheMinimo: limparCacheMinimo ? null : (cacheMinimo ?? this.cacheMinimo),
      de: limparDe ? null : (de ?? this.de),
      ate: limparAte ? null : (ate ?? this.ate),
      soDiasLivres: soDiasLivres ?? this.soDiasLivres,
    );
  }

  /// Aplica o filtro: tira as vencidas (antes de [hoje]), aplica os
  /// critérios e ordena da mais próxima para a mais distante. [bloqueados] e
  /// [ocupados] são dias `yyyy-MM-dd` da agenda do próprio músico.
  List<Oportunidade> aplicar(
    Iterable<Oportunidade> oportunidades, {
    required DateTime hoje,
    Set<String> bloqueados = const {},
    Set<String> ocupados = const {},
  }) {
    final cidadeBusca = cidade?.trim().toLowerCase() ?? '';
    final inicio = de == null ? null : _dia(de!);
    final fim = ate == null ? null : _dia(ate!);

    return oportunidades.where((o) {
      final diaEvento = _dia(o.dataEvento);
      if (o.vencidaEm(hoje)) return false;
      if (genero != null && genero!.isNotEmpty && o.generoMusical != genero) {
        return false;
      }
      if (cidadeBusca.isNotEmpty &&
          !o.cidade.toLowerCase().contains(cidadeBusca)) {
        return false;
      }
      if (cacheMinimo != null && o.cacheOferecido < cacheMinimo!) return false;
      if (inicio != null && diaEvento.isBefore(inicio)) return false;
      if (fim != null && diaEvento.isAfter(fim)) return false;
      final chave = Contratacao.diaDe(o.dataEvento);
      if (soDiasLivres &&
          (bloqueados.contains(chave) || ocupados.contains(chave))) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) => a.dataEvento.compareTo(b.dataEvento));
  }

  static DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);
}
