import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/interesse.dart';
import '../../providers/auth_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../routes/app_routes.dart';

/// Interesses recebidos (aceitar/recusar) e enviados (cancelar).
class InteressesScreen extends StatelessWidget {
  const InteressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InteresseProvider>();
    final pendentes = provider.pendentesRecebidos;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Interesses'),
          bottom: TabBar(
            tabs: [
              Tab(text: pendentes > 0 ? 'Recebidos ($pendentes)' : 'Recebidos'),
              const Tab(text: 'Enviados'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ListaInteresses(
              interesses: provider.recebidos,
              recebidos: true,
              vazio: 'Ninguém demonstrou interesse em você ainda.',
            ),
            _ListaInteresses(
              interesses: provider.enviados,
              recebidos: false,
              vazio: 'Você ainda não enviou candidaturas ou convites.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaInteresses extends StatelessWidget {
  final List<Interesse> interesses;
  final bool recebidos;
  final String vazio;

  const _ListaInteresses({
    required this.interesses,
    required this.recebidos,
    required this.vazio,
  });

  @override
  Widget build(BuildContext context) {
    if (interesses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(vazio, textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: interesses.length,
      itemBuilder: (context, index) =>
          _InteresseCard(interesse: interesses[index], recebido: recebidos),
    );
  }
}

class _InteresseCard extends StatelessWidget {
  final Interesse interesse;
  final bool recebido;

  const _InteresseCard({required this.interesse, required this.recebido});

  String get _titulo {
    final titulo = interesse.oportunidadeTitulo;
    final paraOportunidade = titulo == null ? '' : ' para "$titulo"';

    if (recebido) {
      if (interesse.tipo == TipoInteresse.convite) {
        return '${interesse.remetenteNome} convidou você$paraOportunidade';
      }
      // Nome artístico pode repetir entre contas; mostra também quem enviou.
      final artista = interesse.musicoNome;
      final conta = interesse.remetenteNome;
      final quem = conta.isNotEmpty && conta != artista ? '$artista ($conta)' : artista;
      return '$quem quer tocar$paraOportunidade';
    }
    return interesse.tipo == TipoInteresse.candidatura
        ? 'Candidatura$paraOportunidade'
        : 'Convite a ${interesse.musicoNome}$paraOportunidade';
  }

  String get _status {
    final data = interesse.criadoEm;
    final dia =
        '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
    final status = switch (interesse.status) {
      StatusInteresse.pendente => recebido ? 'Aguardando sua resposta' : 'Aguardando resposta',
      StatusInteresse.aceito => 'Aceito',
      StatusInteresse.recusado => 'Recusado',
    };
    return '$status • $dia';
  }

  Future<void> _aceitar(BuildContext context) async {
    final provider = context.read<InteresseProvider>();
    final conversaId = await provider.aceitar(
      interesse,
      nomeDestinatario: context.read<AuthProvider>().nomeExibicao,
    );
    if (!context.mounted) return;

    if (conversaId == null) {
      _avisar(context, provider.errorMessage ?? 'Não foi possível aceitar.');
      return;
    }
    _avisar(context, 'Interesse aceito! A conversa foi aberta.');
    Navigator.pushNamed(context, AppRoutes.chat, arguments: conversaId);
  }

  Future<void> _recusar(BuildContext context) async {
    final provider = context.read<InteresseProvider>();
    final ok = await provider.recusar(interesse);
    if (!context.mounted) return;
    _avisar(
      context,
      ok ? 'Interesse recusado.' : provider.errorMessage ?? 'Não foi possível recusar.',
    );
  }

  Future<void> _cancelar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar envio'),
        content: const Text('Deseja cancelar este interesse?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancelar envio'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    final provider = context.read<InteresseProvider>();
    final ok = await provider.cancelar(interesse);
    if (!context.mounted) return;
    _avisar(
      context,
      ok ? 'Interesse cancelado.' : provider.errorMessage ?? 'Não foi possível cancelar.',
    );
  }

  void _avisar(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    final conversaId = interesse.conversaId;
    final verPerfil = recebido && interesse.tipo == TipoInteresse.candidatura;
    final oportunidadeId = interesse.oportunidadeId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _titulo,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(_status),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (verPerfil)
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.detalheMusico,
                      arguments: interesse.musicoId,
                    ),
                    child: const Text('Ver perfil'),
                  ),
                if (!verPerfil && oportunidadeId != null)
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.detalheOportunidade,
                      arguments: oportunidadeId,
                    ),
                    child: const Text('Ver oportunidade'),
                  ),
                if (recebido && interesse.pendente) ...[
                  OutlinedButton(
                    onPressed: () => _recusar(context),
                    child: const Text('Recusar'),
                  ),
                  ElevatedButton(
                    onPressed: () => _aceitar(context),
                    child: const Text('Aceitar'),
                  ),
                ],
                if (!recebido && interesse.pendente)
                  OutlinedButton(
                    onPressed: () => _cancelar(context),
                    child: const Text('Cancelar'),
                  ),
                if (conversaId != null)
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.chat,
                      arguments: conversaId,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Abrir conversa'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
