import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'lista_musicos_screen.dart';
import 'lista_oportunidades_screen.dart';

/// Aba "Buscar" (Plano 8, Fase 1): oportunidades e músicos lado a lado. Quem
/// só atua como músico começa em Oportunidades; dono e admin, em Músicos.
class BuscaScreen extends StatelessWidget {
  const BuscaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final comecaEmOportunidades = auth.atuaComoMusico && !auth.atuaComoDono;

    return DefaultTabController(
      // Troca de papel (outra conta) recria o controlador na aba certa.
      key: ValueKey(comecaEmOportunidades),
      length: 2,
      initialIndex: comecaEmOportunidades ? 0 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buscar'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Oportunidades'),
              Tab(text: 'Músicos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ListaOportunidadesScreen(embutida: true),
            ListaMusicosScreen(embutida: true),
          ],
        ),
      ),
    );
  }
}
