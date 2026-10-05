import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';
import '../agenda/agenda_screen.dart';
import '../busca/busca_screen.dart';
import '../chat/conversas_screen.dart';
import '../perfil/perfil_screen.dart';
import 'abas.dart';
import 'home_screen.dart';

/// Estrutura do app logado (Plano 8, Fase 1): barra inferior com Início,
/// Buscar, Agenda, Conversas e Perfil. Cada aba é montada na primeira visita
/// e depois mantida (estado e rolagem preservados). O resto do app abre por
/// rotas nomeadas por cima do shell, como antes.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key, this.abaInicial = AbaPrincipal.inicio});

  final AbaPrincipal abaInicial;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  late AbaPrincipal _atual = widget.abaInicial;
  late final Set<AbaPrincipal> _visitadas = {widget.abaInicial};

  void _irPara(AbaPrincipal aba) {
    if (aba == _atual) return;
    setState(() {
      _atual = aba;
      _visitadas.add(aba);
    });
  }

  Widget _tela(AbaPrincipal aba) {
    if (!_visitadas.contains(aba)) return const SizedBox.shrink();
    return switch (aba) {
      AbaPrincipal.inicio => const HomeScreen(),
      AbaPrincipal.buscar => const BuscaScreen(),
      AbaPrincipal.agenda => const AgendaScreen(),
      AbaPrincipal.conversas => const ConversasScreen(),
      AbaPrincipal.perfil => const PerfilScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final naoLidas = context.watch<ChatProvider>().totalNaoLidas;

    return PopScope(
      // Voltar fora do Início volta para o Início antes de sair do app.
      canPop: _atual == AbaPrincipal.inicio,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _irPara(AbaPrincipal.inicio);
      },
      child: NavegacaoAbas(
        atual: _atual,
        irPara: _irPara,
        child: Scaffold(
          body: IndexedStack(
            index: _atual.index,
            children: [for (final aba in AbaPrincipal.values) _tela(aba)],
          ),
          bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _atual.index,
              onDestinationSelected: (i) => _irPara(AbaPrincipal.values[i]),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Início',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.search),
                  selectedIcon: Icon(Icons.search_rounded),
                  label: 'Buscar',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: 'Agenda',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: naoLidas > 0,
                    label: Text('$naoLidas'),
                    child: const Icon(Icons.chat_bubble_outline),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: naoLidas > 0,
                    label: Text('$naoLidas'),
                    child: const Icon(Icons.chat_bubble),
                  ),
                  label: 'Conversas',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
