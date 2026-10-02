import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/data_hora.dart';
import '../../models/contratacao.dart';
import '../../providers/auth_provider.dart';
import '../../providers/avaliacao_provider.dart';
import '../../providers/contratacao_provider.dart';
import '../../routes/app_routes.dart';
import 'avaliar_show.dart';

/// Contratações do usuário, conforme o papel: o músico vê as propostas que
/// recebeu (confirmar/recusar); o dono, as que enviou (retirar). Só a conta
/// admin, que atua nos dois papéis, vê as duas abas. Busca, filtro por
/// situação e ordem (mais recentes primeiro, por padrão).
class ContratacoesScreen extends StatelessWidget {
  const ContratacoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<ContratacaoProvider>();

    const vazioMusico = 'Nenhuma proposta de show recebida ainda.';
    const vazioDono =
        'Você ainda não propôs contratações. Proponha pela conversa de um '
        'interesse aceito.';

    if (auth.isAdmin) {
      final pendentes = provider.propostasPendentes;
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Contratações'),
            bottom: TabBar(
              tabs: [
                Tab(
                  text: pendentes > 0 ? 'Recebidas ($pendentes)' : 'Recebidas',
                ),
                const Tab(text: 'Enviadas'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _ListaFiltravel(
                contratacoes: provider.recebidas,
                souMusico: true,
                vazio: vazioMusico,
              ),
              _ListaFiltravel(
                contratacoes: provider.enviadas,
                souMusico: false,
                vazio: vazioDono,
              ),
            ],
          ),
        ),
      );
    }

    final souMusico = auth.atuaComoMusico;
    return Scaffold(
      appBar: AppBar(title: const Text('Contratações')),
      body: _ListaFiltravel(
        contratacoes: souMusico ? provider.recebidas : provider.enviadas,
        souMusico: souMusico,
        vazio: souMusico ? vazioMusico : vazioDono,
      ),
    );
  }
}

/// Busca + filtro por situação + ordem sobre uma lista de contratações. O
/// estado dos filtros é efêmero da tela (`setState`).
class _ListaFiltravel extends StatefulWidget {
  const _ListaFiltravel({
    required this.contratacoes,
    required this.souMusico,
    required this.vazio,
  });

  final List<Contratacao> contratacoes;
  final bool souMusico;
  final String vazio;

  @override
  State<_ListaFiltravel> createState() => _ListaFiltravelState();
}

class _ListaFiltravelState extends State<_ListaFiltravel> {
  final _buscaController = TextEditingController();
  FiltroContratacao _filtro = FiltroContratacao.todas;
  OrdemContratacao _ordem = OrdemContratacao.maisRecentes;

  static const _rotulosFiltro = {
    FiltroContratacao.todas: 'Todas',
    FiltroContratacao.propostas: 'Propostas',
    FiltroContratacao.confirmadas: 'Confirmadas',
    FiltroContratacao.encerradas: 'Encerradas',
  };

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.contratacoes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(widget.vazio, textAlign: TextAlign.center),
        ),
      );
    }

    final lista = context.read<ContratacaoProvider>().filtrar(
      widget.contratacoes,
      filtro: _filtro,
      termo: _buscaController.text,
      ordem: _ordem,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _buscaController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: widget.souMusico
                  ? 'Buscar por título, contratante ou cidade'
                  : 'Buscar por título, artista ou cidade',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _buscaController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Limpar busca',
                      onPressed: () => setState(_buscaController.clear),
                    ),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              for (final filtro in FiltroContratacao.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_rotulosFiltro[filtro]!),
                    selected: _filtro == filtro,
                    onSelected: (_) => setState(() => _filtro = filtro),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${lista.length} de ${widget.contratacoes.length}',
                style: const TextStyle(color: Colors.grey),
              ),
              const Spacer(),
              DropdownButton<OrdemContratacao>(
                value: _ordem,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: OrdemContratacao.maisRecentes,
                    child: Text('Mais recentes'),
                  ),
                  DropdownMenuItem(
                    value: OrdemContratacao.dataDoShow,
                    child: Text('Data do show'),
                  ),
                ],
                onChanged: (ordem) {
                  if (ordem != null) setState(() => _ordem = ordem);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: lista.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nenhuma contratação com esses filtros.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: lista.length,
                  itemBuilder: (context, index) => ContratacaoCard(
                    contratacao: lista[index],
                    souMusico: widget.souMusico,
                  ),
                ),
        ),
      ],
    );
  }
}

/// Card de contratação com as ações que cabem a quem está vendo. Usado aqui
/// e na lista do dia da agenda.
class ContratacaoCard extends StatelessWidget {
  const ContratacaoCard({
    super.key,
    required this.contratacao,
    required this.souMusico,
  });

  final Contratacao contratacao;
  final bool souMusico;

  Color get _corStatus {
    if (contratacao.realizada) return Colors.grey;
    return switch (contratacao.status) {
      StatusContratacao.proposta => Colors.orange,
      StatusContratacao.confirmada => Colors.deepPurple,
      StatusContratacao.recusada || StatusContratacao.cancelada => Colors.red,
    };
  }

  Future<void> _executar(
    BuildContext context,
    Future<bool> Function(ContratacaoProvider) acao,
    String sucesso,
  ) async {
    final provider = context.read<ContratacaoProvider>();
    final ok = await acao(provider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? sucesso : provider.errorMessage ?? 'Não foi possível concluir.',
        ),
      ),
    );
  }

  Future<void> _cancelar(BuildContext context) async {
    final motivoController = TextEditingController();
    final confirmada = contratacao.status == StatusContratacao.confirmada;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(confirmada ? 'Cancelar show' : 'Retirar proposta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              confirmada
                  ? 'O show de ${formatarData(contratacao.data)} será cancelado '
                        'e a data liberada.'
                  : 'A proposta deixará de valer.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motivoController,
              decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmada ? 'Cancelar show' : 'Retirar'),
          ),
        ],
      ),
    );
    final motivo = motivoController.text;
    motivoController.dispose();
    if (confirmar != true || !context.mounted) return;

    await _executar(
      context,
      (p) => p.cancelar(contratacao, motivo: motivo),
      confirmada ? 'Show cancelado.' : 'Proposta retirada.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = contratacao;
    final outraParte = souMusico ? c.donoNome : c.musicoNome;
    final proposta = c.status == StatusContratacao.proposta;
    final confirmada = c.status == StatusContratacao.confirmada;
    // Plano 17: avaliação do show realizado (uma por parte, até 30 dias).
    final avaliacoes = context.watch<AvaliacaoProvider>();
    final minha = avaliacoes.minhaAvaliacao(c.id);
    final podeAvaliar =
        minha == null && c.podeAvaliarEm(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text(c.rotuloStatus),
                  backgroundColor: _corStatus.withValues(alpha: 0.15),
                  side: BorderSide(color: _corStatus),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            Text(souMusico ? 'Contratante: $outraParte' : 'Artista: $outraParte'),
            const SizedBox(height: 4),
            Text(
              '${formatarData(c.data)}, ${c.horaInicio} às ${c.horaFim}',
            ),
            Text('Cachê: R\$ ${c.cacheAcordado.toStringAsFixed(2)}'),
            Text(c.endereco),
            if (c.motivoCancelamento != null) ...[
              const SizedBox(height: 4),
              Text(
                'Motivo: ${c.motivoCancelamento}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                // Plano 16: perfil público de quem contrata.
                if (souMusico)
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.detalheEstabelecimento,
                      arguments: c.donoId,
                    ),
                    child: const Text('Ver estabelecimento'),
                  ),
                if (proposta && souMusico) ...[
                  OutlinedButton(
                    onPressed: () => _executar(
                      context,
                      (p) => p.recusar(c),
                      'Proposta recusada.',
                    ),
                    child: const Text('Recusar'),
                  ),
                  ElevatedButton(
                    onPressed: () => _executar(
                      context,
                      (p) => p.confirmar(c),
                      'Show confirmado! A data está na sua agenda.',
                    ),
                    child: const Text('Confirmar'),
                  ),
                ],
                if (proposta && !souMusico)
                  OutlinedButton(
                    onPressed: () => _cancelar(context),
                    child: const Text('Retirar proposta'),
                  ),
                if (confirmada && !c.realizada)
                  OutlinedButton(
                    onPressed: () => _cancelar(context),
                    child: const Text('Cancelar show'),
                  ),
                if (podeAvaliar)
                  ElevatedButton.icon(
                    onPressed: () => avaliarShow(context, c),
                    icon: const Icon(Icons.star_outline),
                    label: const Text('Avaliar'),
                  ),
                if (minha != null)
                  Chip(
                    avatar: const Icon(Icons.star, color: Colors.amber, size: 18),
                    label: Text('Você avaliou: ${minha.nota}'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
