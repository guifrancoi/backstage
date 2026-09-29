/// O que qualquer usuário logado vê da agenda de um músico: dias marcados
/// como disponíveis (`disponibilidades`) e dias ocupados (`ocupacoes`, uma por
/// contratação confirmada). Dias no formato `yyyy-MM-dd`
/// (`Contratacao.diaDe`). Não expõe cachê nem local.
class AgendaPublica {
  const AgendaPublica({this.disponiveis = const {}, this.ocupados = const {}});

  final Set<String> disponiveis;
  final Set<String> ocupados;

  bool ocupado(String dia) => ocupados.contains(dia);

  bool disponivel(String dia) => disponiveis.contains(dia) && !ocupado(dia);

  AgendaPublica copyWith({Set<String>? disponiveis, Set<String>? ocupados}) {
    return AgendaPublica(
      disponiveis: disponiveis ?? this.disponiveis,
      ocupados: ocupados ?? this.ocupados,
    );
  }
}
