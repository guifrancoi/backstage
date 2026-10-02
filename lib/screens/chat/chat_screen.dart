import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/denuncia.dart';
import '../../models/interesse.dart';
import '../../providers/chat_provider.dart';
import '../../providers/contratacao_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/mensagem_bubble.dart';
import '../moderacao/acoes_moderacao.dart';

class ChatScreen extends StatefulWidget {
  final String conversaId;

  const ChatScreen({super.key, required this.conversaId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _mensagemController = TextEditingController();

  /// Um interesse: vai direto. Vários: o dono escolhe de qual oportunidade.
  Future<void> _proporShow(BuildContext context, List<Interesse> opcoes) async {
    final escolhido = opcoes.length == 1
        ? opcoes.single
        : await showModalBottomSheet<Interesse>(
            context: context,
            showDragHandle: true,
            builder: (sheetContext) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Text(
                      'Propor show para qual oportunidade?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  for (final i in opcoes)
                    ListTile(
                      leading: const Icon(Icons.event),
                      title: Text(
                        i.oportunidadeTitulo ?? 'Sem oportunidade específica',
                      ),
                      onTap: () => Navigator.pop(sheetContext, i),
                    ),
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
        body: const Center(child: Text('Carregando conversa...')),
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
    final paraPropor = [
      for (final id in conversa.interesseIds)
        ?interesses.buscarPorId(id),
    ].where(
      (i) =>
          i.status == StatusInteresse.aceito &&
          i.donoId == meuUid &&
          contratacoes.ativaParaInteresse(i.id) == null,
    ).toList();

    // Plano 22: a outra parte do par, para denunciar/bloquear.
    final outroUid = conversa.participantes.firstWhere(
      (p) => p != meuUid,
      orElse: () => '',
    );
    final nomeOutro = conversa.nomeContato(meuUid);
    final bloqueado = context.watch<OportunidadeProvider>().ehBloqueado(outroUid);

    return Scaffold(
      appBar: AppBar(
        title: Text(nomeOutro),
        actions: [
          if (paraPropor.isNotEmpty && !bloqueado)
            TextButton.icon(
              onPressed: () => _proporShow(context, paraPropor),
              icon: const Icon(Icons.handshake_outlined),
              label: const Text('Propor show'),
            ),
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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: conversa.mensagens.length,
              itemBuilder: (context, index) {
                final mensagem = conversa.mensagens[index];
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensagemController,
                    enabled: !bloqueado,
                    decoration: InputDecoration(
                      hintText: bloqueado
                          ? 'Desbloqueie para conversar'
                          : 'Digite sua mensagem',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: bloqueado
                      ? null
                      : () async {
                          final texto = _mensagemController.text.trim();
                          if (texto.isEmpty) return;

                          final ok = await provider.enviarMensagem(
                            widget.conversaId,
                            texto,
                          );
                          if (ok) _mensagemController.clear();

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Mensagem enviada.'
                                    : provider.errorMessage ??
                                          'Não foi possível enviar.',
                              ),
                            ),
                          );
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
