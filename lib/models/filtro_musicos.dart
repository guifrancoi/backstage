import 'musico.dart';

/// Critérios da lista de músicos (não persistido), editados no painel
/// "Filtrar" da própria lista. A aplicação fica no `OportunidadeProvider`
/// (o "livres em" depende de uma consulta ao Firestore).
class FiltroMusicos {
  const FiltroMusicos({
    this.termo = '',
    this.genero,
    this.cidade,
    this.formacao,
    this.soEquipamentoProprio = false,
    this.livresEm,
    this.soFavoritos = false,
    this.ordenacao = ordenacaoPadrao,
  });

  static const ordenacaoPadrao = 'nome_asc';

  /// Pesquisa por nome artístico ou descrição.
  final String termo;
  final String? genero;
  final String? cidade;
  final Formacao? formacao;
  final bool soEquipamentoProprio;
  final DateTime? livresEm;

  /// Só do dono (Plano 18): só os músicos que ele favoritou.
  final bool soFavoritos;

  /// `nome_asc`, `nome_desc`, `cache_maior` ou `cache_menor` (não conta como
  /// critério: só muda a ordem).
  final String ordenacao;

  /// Quantos critérios estão ligados (o número do botão "Filtrar (n)").
  int get ativos => [
    termo.trim().isNotEmpty,
    genero != null && genero!.isNotEmpty,
    cidade != null && cidade!.trim().isNotEmpty,
    formacao != null,
    soEquipamentoProprio,
    livresEm != null,
    soFavoritos,
  ].where((ligado) => ligado).length;

  bool get vazio => ativos == 0;

  FiltroMusicos copyWith({
    String? termo,
    String? genero,
    String? cidade,
    Formacao? formacao,
    bool? soEquipamentoProprio,
    DateTime? livresEm,
    bool? soFavoritos,
    String? ordenacao,
    bool limparGenero = false,
    bool limparCidade = false,
    bool limparFormacao = false,
    bool limparLivresEm = false,
  }) {
    return FiltroMusicos(
      termo: termo ?? this.termo,
      genero: limparGenero ? null : (genero ?? this.genero),
      cidade: limparCidade ? null : (cidade ?? this.cidade),
      formacao: limparFormacao ? null : (formacao ?? this.formacao),
      soEquipamentoProprio: soEquipamentoProprio ?? this.soEquipamentoProprio,
      livresEm: limparLivresEm ? null : (livresEm ?? this.livresEm),
      soFavoritos: soFavoritos ?? this.soFavoritos,
      ordenacao: ordenacao ?? this.ordenacao,
    );
  }
}
