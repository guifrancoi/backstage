import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/musico_card.dart';
import 'acoes_interesse.dart';

class ListaMusicosScreen extends StatelessWidget {
  const ListaMusicosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OportunidadeProvider>();
    final auth = context.watch<AuthProvider>();
    final interesses = context.watch<InteresseProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Lista de músicos')),
      body: Builder(
        builder: (context) {
          if (provider.carregandoMusicos && provider.musicos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.erroMusicos) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Erro ao carregar músicos. Verifique sua conexão.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }
          final musicos = provider.musicos;
          if (musicos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhum músico encontrado com os filtros informados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: musicos.length,
            itemBuilder: (context, index) {
              final musico = musicos[index];
              final pode = podeConvidar(auth, musico);
              return MusicoCard(
                musico: musico,
                onConvidar: pode ? () => confirmarConvite(context, musico) : null,
                rotuloConvidar: rotuloConvidar(interesses, musico.id),
                onVerDetalhes: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.detalheMusico,
                    arguments: musico.id,
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
