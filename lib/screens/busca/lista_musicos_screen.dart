import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/data_hora.dart';
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
    final livresEm = provider.livresEm;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de músicos'),
        actions: [
          IconButton(
            tooltip: 'Livres em uma data',
            icon: const Icon(Icons.event_available),
            onPressed: () => escolherDiaLivre(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (livresEm != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  avatar: const Icon(Icons.event_available, size: 18),
                  label: Text('Livres em ${formatarData(livresEm)}'),
                  onPressed: () => escolherDiaLivre(context),
                  onDeleted: () => provider.filtrarMusicosLivresEm(null),
                ),
              ),
            ),
          Expanded(
            child: _lista(context, provider, auth, interesses, livresEm),
          ),
        ],
      ),
    );
  }

  Widget _lista(
    BuildContext context,
    OportunidadeProvider provider,
    AuthProvider auth,
    InteresseProvider interesses,
    DateTime? livresEm,
  ) {
    if ((provider.carregandoMusicos && provider.musicos.isEmpty) ||
        provider.carregandoLivres) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.erroMusicos) {
      return const _Mensagem('Erro ao carregar músicos. Verifique sua conexão.');
    }
    final musicos = provider.musicos;
    if (musicos.isEmpty) {
      return _Mensagem(
        livresEm == null
            ? 'Nenhum músico encontrado com os filtros informados.'
            : 'Nenhum músico livre em ${formatarData(livresEm)} com os '
                  'filtros informados.',
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
  }
}

class _Mensagem extends StatelessWidget {
  const _Mensagem(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
