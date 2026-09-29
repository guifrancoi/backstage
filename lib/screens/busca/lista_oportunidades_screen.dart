import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/oportunidade_card.dart';
import 'acoes_interesse.dart';

class ListaOportunidadesScreen extends StatelessWidget {
  const ListaOportunidadesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OportunidadeProvider>();
    final auth = context.watch<AuthProvider>();
    final interesses = context.watch<InteresseProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Lista de oportunidades')),
      body: Builder(
        builder: (context) {
          if (provider.carregandoOportunidades &&
              provider.oportunidades.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.erroOportunidades) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Erro ao carregar oportunidades. Verifique sua conexão.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }
          final oportunidades = provider.oportunidades;
          if (oportunidades.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhuma oportunidade encontrada.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: oportunidades.length,
            itemBuilder: (context, index) {
              final oportunidade = oportunidades[index];
              final pode = podeCandidatar(auth, oportunidade);
              return OportunidadeCard(
                oportunidade: oportunidade,
                onCandidatar: pode
                    ? () => confirmarCandidatura(context, oportunidade)
                    : null,
                statusCandidatura: pode
                    ? interesses.candidaturaPara(oportunidade.id)?.rotuloStatus
                    : null,
                onVerDetalhes: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.detalheOportunidade,
                    arguments: oportunidade.id,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
