import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/data_hora.dart';
import '../../core/utils/lembrete_show.dart';
import '../../core/utils/painel_numeros.dart';
import '../../models/contratacao.dart';
import '../../providers/auth_provider.dart';
import '../../providers/avaliacao_provider.dart';
import '../../providers/contratacao_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/estados.dart';
import '../../widgets/etiqueta.dart';
import '../../widgets/musico_card.dart' show InfoComIcone;
import '../../widgets/texto_valor.dart';
import 'avaliar_show.dart';
import 'status_contratacao.dart';

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
      return EstadoVazio(
        icone: Icons.handshake_outlined,
        titulo: 'Nenhuma contratação',
        mensagem: widget.vazio,
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
                style: Theme.of(context).textTheme.bodySmall,
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
              ? const EstadoVazio(
                  icone: Icons.search_off,
                  titulo: 'Nada encontrado',
                  mensagem: 'Nenhuma contratação com esses filtros.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xxs,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
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

  /// Abre o Google Agenda com o show preenchido (Plano 19).
  Future<void> _adicionarAgenda(BuildContext context) async {
    final uri = linkGoogleAgenda(contratacao, souMusico: souMusico);
    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abriu && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a agenda.')),
      );
    }
  }

  /// Plano 21: o músico pede outro cachê (uma rodada só).
  Future<void> _contrapropor(BuildContext context) async {
    final valor = await showDialog<double>(
      context: context,
      builder: (_) => _DialogoContraproposta(atual: contratacao.cacheAcordado),
    );
    if (valor == null || !context.mounted) return;
    await _executar(
      context,
      (p) => p.contrapropor(contratacao, valor),
      'Contraproposta enviada.',
    );
  }

  /// Plano 21: o dono recusa a contraproposta (encerra a contratação).
  Future<void> _recusarContraproposta(BuildContext context) async {
    final motivoController = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recusar contraproposta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A contratação será encerrada. Para combinar outro valor, '
              'converse com o músico e faça uma nova proposta.',
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
            child: const Text('Recusar'),
          ),
        ],
      ),
    );
    final motivo = motivoController.text;
    motivoController.dispose();
    if (confirmar != true || !context.mounted) return;
    await _executar(
      context,
      (p) => p.recusarContraproposta(contratacao, motivo: motivo),
      'Contraproposta recusada.',
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
    final contraproposta = c.status == StatusContratacao.contraproposta;
    final confirmada = c.status == StatusContratacao.confirmada;
    final pedido = c.cacheContraproposto;
    // Plano 17: avaliação do show realizado (uma por parte, até 30 dias).
    final avaliacoes = context.watch<AvaliacaoProvider>();
    final minha = avaliacoes.minhaAvaliacao(c.id);
    final podeAvaliar = minha == null && c.podeAvaliarEm(DateTime.now());

    final texto = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.titulo, style: texto.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        souMusico
                            ? 'Contratante: $outraParte'
                            : 'Artista: $outraParte',
                        style: texto.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Etiqueta(c.rotuloStatus, tipo: tipoEtiquetaContratacao(c)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            InfoComIcone(
              Icons.calendar_today_outlined,
              '${formatarData(c.data)} · ${c.horaInicio} às ${c.horaFim}',
            ),
            const SizedBox(height: AppSpacing.xxs),
            InfoComIcone(Icons.place_outlined, c.endereco),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Text('Cachê ', style: texto.bodySmall),
                TextoValor(c.cacheAcordado, centavos: true),
              ],
            ),
            // Plano 21: o valor pedido pelo músico, enquanto o dono decide.
            if (contraproposta && pedido != null)
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.xs),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primariaContainer,
                  borderRadius: AppRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.swap_horiz,
                      size: 18,
                      color: AppColors.primariaTexto,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        souMusico
                            ? 'Você pediu ${formatarReais(pedido, centavos: true)} — '
                                  'aguardando o contratante.'
                            : 'O músico pediu ${formatarReais(pedido, centavos: true)}.',
                        style: texto.bodyMedium?.copyWith(
                          color: AppColors.primariaTexto,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (proposta && c.houveContraproposta)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxs),
                child: Text(
                  'Valor ajustado após contraproposta.',
                  style: texto.bodySmall,
                ),
              ),
            if (c.motivoCancelamento != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Motivo: ${c.motivoCancelamento}', style: texto.bodySmall),
            ],
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
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
                  if (c.podeContrapropor)
                    OutlinedButton(
                      onPressed: () => _contrapropor(context),
                      child: const Text('Contrapropor'),
                    ),
                ],
                if (contraproposta && !souMusico) ...[
                  OutlinedButton(
                    onPressed: () => _recusarContraproposta(context),
                    child: const Text('Recusar'),
                  ),
                  ElevatedButton(
                    onPressed: () => _executar(
                      context,
                      (p) => p.aceitarContraproposta(c),
                      'Contraproposta aceita. Agora o músico confirma.',
                    ),
                    child: Text(
                      'Aceitar ${formatarReais(pedido ?? 0, centavos: true)}',
                    ),
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
                // Plano 19: leva o show para o Google Agenda do celular.
                if (confirmada && !c.realizada)
                  OutlinedButton.icon(
                    onPressed: () => _adicionarAgenda(context),
                    icon: const Icon(Icons.event),
                    label: const Text('Adicionar à agenda'),
                  ),
                if (podeAvaliar)
                  ElevatedButton.icon(
                    onPressed: () => avaliarShow(context, c),
                    icon: const Icon(Icons.star_outline),
                    label: const Text('Avaliar'),
                  ),
                if (minha != null)
                  Etiqueta(
                    'Você avaliou: ${minha.nota}',
                    tipo: TipoEtiqueta.aviso,
                    icone: Icons.star_rounded,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Plano 21: pede o novo cachê (número > 0 e diferente do proposto).
class _DialogoContraproposta extends StatefulWidget {
  const _DialogoContraproposta({required this.atual});

  final double atual;

  @override
  State<_DialogoContraproposta> createState() => _DialogoContrapropostaState();
}

class _DialogoContrapropostaState extends State<_DialogoContraproposta> {
  final _formKey = GlobalKey<FormState>();
  final _valor = TextEditingController();

  @override
  void dispose() {
    _valor.dispose();
    super.dispose();
  }

  double? get _lido => double.tryParse(_valor.text.trim().replaceAll(',', '.'));

  String? _validar(String? _) {
    final valor = _lido;
    if (valor == null || valor <= 0) return 'Informe um valor maior que zero.';
    if (valor == widget.atual) return 'Informe um valor diferente do proposto.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Contrapropor cachê'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Proposta atual: ${formatarReais(widget.atual, centavos: true)}. '
              'Você só pode contrapropor uma vez.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _valor,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Cachê pedido (R\$)',
              ),
              validator: _validar,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Voltar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _lido);
            }
          },
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}
