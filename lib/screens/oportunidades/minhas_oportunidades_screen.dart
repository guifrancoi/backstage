import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/oportunidade.dart';
import '../../providers/auth_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/oportunidade_card.dart';
import '../busca/acoes_interesse.dart';

/// Oportunidades publicadas pelo dono de estabelecimento logado, com editar
/// e remover: próximas primeiro, vencidas na seção "Encerradas".
class MinhasOportunidadesScreen extends StatelessWidget {
  const MinhasOportunidadesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final minhas = context.watch<OportunidadeProvider>().minhasOportunidades(
      auth.userId,
    );
    // Vencidas saem da lista pública; aqui o dono ainda as vê, à parte e da
    // mais recente para a mais antiga.
    final proximas = minhas.where((o) => !o.vencida).toList();
    final encerradas = minhas.where((o) => o.vencida).toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas oportunidades')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.novaOportunidade),
        icon: const Icon(Icons.add),
        label: const Text('Nova oportunidade'),
      ),
      body: minhas.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Você ainda não publicou nenhuma oportunidade.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                if (proximas.isNotEmpty) ...[
                  const _Secao('Próximas'),
                  for (final o in proximas) _ItemOportunidade(o),
                ],
                if (encerradas.isNotEmpty) ...[
                  const _Secao('Encerradas'),
                  for (final o in encerradas) _ItemOportunidade(o),
                ],
              ],
            ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao(this.titulo);

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        titulo,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ItemOportunidade extends StatelessWidget {
  const _ItemOportunidade(this.oportunidade);

  final Oportunidade oportunidade;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OportunidadeCard(
          oportunidade: oportunidade,
          onVerDetalhes: () => Navigator.pushNamed(
            context,
            AppRoutes.detalheOportunidade,
            arguments: oportunidade.id,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () => confirmarRemocao(context, oportunidade),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remover'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.editarOportunidade,
                arguments: oportunidade.id,
              ),
              icon: const Icon(Icons.edit),
              label: const Text('Editar'),
            ),
          ],
        ),
      ],
    );
  }
}
