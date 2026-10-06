import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/data_hora.dart';
import '../../models/denuncia.dart';
import '../../models/interesse.dart';
import '../../models/mensagem.dart';
import '../../providers/chat_provider.dart';
import '../../providers/contratacao_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/avatar_iniciais.dart';
import '../../widgets/estados.dart';
import '../../widgets/mensagem_bubble.dart';
import '../moderacao/acoes_moderacao.dart';

/// "Hoje", "Ontem" ou a data, para separar as mensagens por dia.
String rotuloDia(DateTime data, {DateTime? agora}) {
  final hoje = agora ?? DateTime.now();
  final dia = DateTime(data.year, data.month, data.day);
  final dias = DateTime(hoje.year, hoje.month, hoje.day).difference(dia).inDays;
  if (dias == 0) return 'Hoje';
  if (dias == 1) return 'Ontem';
  return formatarDataCurta(data, hoje: hoje);
}

/// Conversa do par (Plano 8): avatar e nome no topo, faixa "Propor show"
/// para o dono, mensagens por dia (abre no fim) e campo em pílula.
class ChatScreen extends StatefulWidget {
  final String conversaId;

  const ChatScreen({super.key, required this.conversaId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _mensagemController = TextEditingController();
  bool _enviando = false;

  /// Um interesse: vai direto. Vários: o dono escolhe de qual oportunidade.
  Future<void> _proporShow(BuildContext context, List<Interesse> opcoes) async {
    final escolhido = opcoes.length == 1
        ? opcoes.single
        : await showModalBottomSheet<Interesse>(
            context: context,
            builder: (sheetContext) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xs,
                    ),
                    child: Text(
                      'Propor show para qual oportunidade?',
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                  ),
                  for (final i in opcoes)
                    ListTile(
                      leading: const Icon(Icons.event_outlined),
                      title: Text(
                        i.oportunidadeTitulo ?? 'Sem oportunidade específica',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pop(sheetContext, i),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          );
    if (escolhido == null || !context.mounted) return;
    Navigator.pushNamed(
      context,
      AppRoutes.proporContratacao,
      arguments: escolhido.id,
    );
  }

  Future<void> _enviar(ChatProvider provider) async {
    final texto = _mensagemController.text.trim();
    if (texto.isEmpty || _enviando) return;

    setState(() => _enviando = true);
    final ok = await provider.enviarMensagem(widget.conversaId, texto);
    if (!mounted) return;
    setState(() => _enviando = false);
    if (ok) {
      _mensagemController.clear();
      return;
    }
    // Plano 8: só avisa na falha (a mensagem enviada aparece na conversa).
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(provider.errorMessage ?? 'Não foi possível enviar.'),
      ),
    );
  }

  @override
  void dispose() {
    _mensagemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final conversa = provider.buscarConversaPorId(widget.conversaId);

    // Logo após aceitar um interesse a conversa ainda pode estar chegando
    // pelo stream; a tela se atualiza sozinha quando ela aparecer.
    if (conversa == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const EstadoCarregando(mensagem: 'Carregando conversa...'),
      );
    }

    final meuUid = provider.meuUid;
    // Tela aberta = conversa lida (também quando chega mensagem nova). O
    // provider só grava se houver não lidas.
    if (provider.naoLidas(conversa) > 0) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => provider.marcarComoLida(widget.conversaId),
      );
    }
    // O dono formaliza o show daqui: interesses aceitos desta conversa (uma
    // por par) em que ele é o dono e que ainda não têm contratação ativa.
    final interesses = context.watch<InteresseProvider>();
    final contratacoes = context.watch<ContratacaoProvider>();
    final paraPropor =
        [for (final id in conversa.interesseIds) ?interesses.buscarPorId(id)]
            .where(
              (i) =>
                  i.status == StatusInteresse.aceito &&
                  i.donoId == meuUid &&
                  contratacoes.ativaParaInteresse(i.id) == null,
            )
            .toList();

    // Plano 22: a outra parte do par, para denunciar/bloquear.
    final outroUid = conversa.participantes.firstWhere(
      (p) => p != meuUid,
      orElse: () => '',
    );
    final nomeOutro = conversa.nomeContato(meuUid);
    final bloqueado = context.watch<OportunidadeProvider>().ehBloqueado(
      outroUid,
    );
    // Mais recentes embaixo, com a lista invertida (abre no fim).
    final itens = _itensComDias(conversa.mensagens).reversed.toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AvatarIniciais(nome: nomeOutro, tamanho: 36, circular: true),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                nomeOutro,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          MenuModeracao(
            alvoUid: outroUid,
            nome: nomeOutro,
            tipo: TipoAlvoDenuncia.perfil,
            alvoId: outroUid,
            descricao: nomeOutro,
            rotuloDenuncia: 'Denunciar usuário',
          ),
        ],
      ),
      body: Column(
        children: [
          if (bloqueado) AvisoBloqueado(uid: outroUid, nome: nomeOutro),
          if (paraPropor.isNotEmpty && !bloqueado)
            _FaixaProporShow(onPropor: () => _proporShow(context, paraPropor)),
          Expanded(
            child: conversa.mensagens.isEmpty
                ? const EstadoVazio(
                    icone: Icons.waving_hand_outlined,
                    titulo: 'Diga oi!',
                    mensagem: 'Combine os detalhes do show por aqui.',
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: itens.length,
                    itemBuilder: (context, index) {
                      final item = itens[index];
                      if (item is String) return _SeparadorDia(item);
                      final mensagem = item as Mensagem;
                      final minha = mensagem.remetenteId == meuUid;
                      final bolha = MensagemBubble(
                        mensagem: mensagem,
                        enviadaPorMim: minha,
                      );
                      if (minha || mensagem.sistema) return bolha;
                      // Plano 22: segurar a mensagem do outro para denunciar.
                      return GestureDetector(
                        onLongPress: () => abrirDenuncia(
                          context,
                          tipo: TipoAlvoDenuncia.mensagem,
                          alvoId: mensagem.id,
                          alvoUid: mensagem.remetenteId,
                          descricao: mensagem.texto,
                        ),
                        child: bolha,
                      );
                    },
                  ),
          ),
          _CampoMensagem(
            controller: _mensagemController,
            bloqueado: bloqueado,
            enviando: _enviando,
            onEnviar: () => _enviar(provider),
          ),
        ],
      ),
    );
  }

  /// Mensagens em ordem com o rótulo do dia (String) antes de cada dia novo.
  static List<Object> _itensComDias(List<Mensagem> mensagens) {
    final itens = <Object>[];
    String? diaAnterior;
    for (final m in mensagens) {
      final dia = rotuloDia(m.dataHora);
      if (dia != diaAnterior) {
        itens.add(dia);
        diaAnterior = dia;
      }
      itens.add(m);
    }
    return itens;
  }
}

class _SeparadorDia extends StatelessWidget {
  const _SeparadorDia(this.rotulo);

  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(rotulo, style: Theme.of(context).textTheme.labelSmall),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

/// Faixa do dono para formalizar o show (Plano 9B).
class _FaixaProporShow extends StatelessWidget {
  const _FaixaProporShow({required this.onPropor});

  final VoidCallback onPropor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primariaContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xxs,
          AppSpacing.xs,
          AppSpacing.xxs,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.handshake_outlined,
              size: 20,
              color: AppColors.primariaTexto,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Já combinaram? Formalize o show.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.texto),
              ),
            ),
            TextButton(onPressed: onPropor, child: const Text('Propor show')),
          ],
        ),
      ),
    );
  }
}

/// Campo em pílula + botão de enviar (desabilitado com bloqueio).
class _CampoMensagem extends StatelessWidget {
  const _CampoMensagem({
    required this.controller,
    required this.bloqueado,
    required this.enviando,
    required this.onEnviar,
  });

  final TextEditingController controller;
  final bool bloqueado;
  final bool enviando;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    final pilula = OutlineInputBorder(
      borderRadius: AppRadius.circular(AppRadius.xl),
      borderSide: const BorderSide(color: AppColors.borda),
    );
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs,
        ),
        decoration: const BoxDecoration(
          color: AppColors.superficie,
          border: Border(top: BorderSide(color: AppColors.borda)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !bloqueado,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: bloqueado
                      ? 'Desbloqueie para conversar'
                      : 'Digite sua mensagem',
                  border: pilula,
                  enabledBorder: pilula,
                  disabledBorder: pilula,
                  focusedBorder: pilula.copyWith(
                    borderSide: const BorderSide(color: AppColors.primaria),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton.filled(
              tooltip: 'Enviar',
              onPressed: bloqueado || enviando ? null : onEnviar,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
