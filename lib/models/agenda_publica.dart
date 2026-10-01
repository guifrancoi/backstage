/// O que qualquer usuário logado vê da agenda de um músico. Todo dia é
/// **livre por padrão**; só deixa de ser se o músico o bloqueou (`bloqueios`)
/// ou se há show confirmado nele (`ocupacoes`). Dias no formato `yyyy-MM-dd`
/// (`Contratacao.diaDe`). Não expõe cachê, local nem motivo do bloqueio.
class AgendaPublica {
  const AgendaPublica({this.bloqueados = const {}, this.ocupados = const {}});

  final Set<String> bloqueados;
  final Set<String> ocupados;

  bool ocupado(String dia) => ocupados.contains(dia);

  bool bloqueado(String dia) => bloqueados.contains(dia);

  bool livre(String dia) => !ocupado(dia) && !bloqueado(dia);

  AgendaPublica copyWith({Set<String>? bloqueados, Set<String>? ocupados}) {
    return AgendaPublica(
      bloqueados: bloqueados ?? this.bloqueados,
      ocupados: ocupados ?? this.ocupados,
    );
  }
}
