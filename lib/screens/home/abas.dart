import 'package:flutter/widgets.dart';

import '../../routes/app_routes.dart';

/// Abas da barra inferior (Plano 8, Fase 1), na ordem em que aparecem.
enum AbaPrincipal { inicio, buscar, agenda, conversas, perfil }

/// Deixa as telas dentro do `ShellScreen` trocarem de aba (ex.: o campo de
/// busca da Home abre "Buscar") sem conhecer o shell.
class NavegacaoAbas extends InheritedWidget {
  const NavegacaoAbas({
    super.key,
    required this.atual,
    required this.irPara,
    required super.child,
  });

  final AbaPrincipal atual;
  final void Function(AbaPrincipal aba) irPara;

  static NavegacaoAbas? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NavegacaoAbas>();

  @override
  bool updateShouldNotify(NavegacaoAbas oldWidget) => atual != oldWidget.atual;
}

/// Vai para [aba] do shell; fora dele (tela aberta sozinha, testes) abre a
/// rota equivalente por cima.
void irParaAba(BuildContext context, AbaPrincipal aba) {
  final navegacao = NavegacaoAbas.maybeOf(context);
  if (navegacao != null) {
    navegacao.irPara(aba);
    return;
  }
  final rota = switch (aba) {
    AbaPrincipal.inicio => null,
    AbaPrincipal.buscar => AppRoutes.listaOportunidades,
    AbaPrincipal.agenda => AppRoutes.agenda,
    AbaPrincipal.conversas => AppRoutes.conversas,
    AbaPrincipal.perfil => AppRoutes.perfil,
  };
  if (rota != null) Navigator.pushNamed(context, rota);
}
