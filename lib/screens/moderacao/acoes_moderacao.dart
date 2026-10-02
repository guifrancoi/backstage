import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/denuncia.dart';
import '../../providers/auth_provider.dart';
import '../../providers/denuncia_provider.dart';
import '../../providers/oportunidade_provider.dart';

/// Denunciar e bloquear (Plano 22): ações usadas no detalhe do músico, no
/// perfil do estabelecimento, na oportunidade, no chat e nas avaliações.

/// Abre a folha de denúncia e envia. Não aparece para o próprio item.
Future<void> abrirDenuncia(
  BuildContext context, {
  required TipoAlvoDenuncia tipo,
  required String alvoId,
  required String alvoUid,
  required String descricao,
}) async {
  final enviado = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _FolhaDenuncia(
      tipo: tipo,
      alvoId: alvoId,
      alvoUid: alvoUid,
      descricao: descricao,
    ),
  );
  if (enviado == null || !context.mounted) return;
  _avisar(
    context,
    enviado
        ? 'Denúncia enviada. Obrigado por avisar.'
        : context.read<DenunciaProvider>().errorMessage ??
              'Não foi possível enviar a denúncia.',
  );
}

/// Pede confirmação, bloqueia [uid] e encerra o que está pendente.
Future<void> confirmarBloqueio(
  BuildContext context, {
  required String uid,
  required String nome,
}) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Bloquear $nome?'),
      content: const Text(
        'Vocês não poderão mais trocar mensagens, convites nem candidaturas, '
        'e a pessoa some das suas listas e sugestões. Interesses pendentes e '
        'propostas em negociação entre vocês serão encerrados; shows já '
        'confirmados continuam. Você pode desbloquear depois.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Voltar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Bloquear'),
        ),
      ],
    ),
  );
  if (confirmar != true || !context.mounted) return;

  final provider = context.read<OportunidadeProvider>();
  final ok = await provider.bloquear(uid, nome);
  if (!context.mounted) return;
  _avisar(
    context,
    provider.errorMessage ?? (ok ? '$nome foi bloqueado.' : 'Não foi possível bloquear.'),
  );
}

Future<void> desbloquear(
  BuildContext context, {
  required String uid,
  required String nome,
}) async {
  final provider = context.read<OportunidadeProvider>();
  final ok = await provider.desbloquear(uid);
  if (!context.mounted) return;
  _avisar(
    context,
    ok ? '$nome foi desbloqueado.' : provider.errorMessage ?? 'Não foi possível desbloquear.',
  );
}

/// Menu "⋮" com Denunciar e Bloquear/Desbloquear. Some quando o alvo é o
/// próprio usuário (ou não tem dono).
class MenuModeracao extends StatelessWidget {
  const MenuModeracao({
    super.key,
    required this.alvoUid,
    required this.nome,
    required this.tipo,
    required this.alvoId,
    required this.descricao,
    this.rotuloDenuncia = 'Denunciar',
  });

  final String alvoUid;
  final String nome;
  final TipoAlvoDenuncia tipo;
  final String alvoId;
  final String descricao;
  final String rotuloDenuncia;

  @override
  Widget build(BuildContext context) {
    final meuUid = context.watch<AuthProvider>().userId;
    if (alvoUid.isEmpty || alvoUid == meuUid) return const SizedBox.shrink();
    final bloqueado = context.watch<OportunidadeProvider>().ehBloqueado(alvoUid);

    return PopupMenuButton<String>(
      tooltip: 'Mais opções',
      onSelected: (acao) => switch (acao) {
        'denunciar' => abrirDenuncia(
          context,
          tipo: tipo,
          alvoId: alvoId,
          alvoUid: alvoUid,
          descricao: descricao,
        ),
        'desbloquear' => desbloquear(context, uid: alvoUid, nome: nome),
        _ => confirmarBloqueio(context, uid: alvoUid, nome: nome),
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'denunciar',
          child: ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(rotuloDenuncia),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: bloqueado ? 'desbloquear' : 'bloquear',
          child: ListTile(
            leading: Icon(bloqueado ? Icons.lock_open : Icons.block),
            title: Text(bloqueado ? 'Desbloquear $nome' : 'Bloquear $nome'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

/// Faixa "Você bloqueou X" com o botão Desbloquear.
class AvisoBloqueado extends StatelessWidget {
  const AvisoBloqueado({super.key, required this.uid, required this.nome});

  final String uid;
  final String nome;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      leading: const Icon(Icons.block, color: Colors.red),
      content: Text('Você bloqueou $nome.'),
      actions: [
        TextButton(
          onPressed: () => desbloquear(context, uid: uid, nome: nome),
          child: const Text('Desbloquear'),
        ),
      ],
    );
  }
}

class _FolhaDenuncia extends StatefulWidget {
  const _FolhaDenuncia({
    required this.tipo,
    required this.alvoId,
    required this.alvoUid,
    required this.descricao,
  });

  final TipoAlvoDenuncia tipo;
  final String alvoId;
  final String alvoUid;
  final String descricao;

  @override
  State<_FolhaDenuncia> createState() => _FolhaDenunciaState();
}

class _FolhaDenunciaState extends State<_FolhaDenuncia> {
  final _texto = TextEditingController();
  MotivoDenuncia? _motivo;
  bool _enviando = false;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    final ok = await context.read<DenunciaProvider>().denunciar(
      autorNome: context.read<AuthProvider>().nomeExibicao,
      tipoAlvo: widget.tipo,
      alvoId: widget.alvoId,
      alvoUid: widget.alvoUid,
      descricaoAlvo: widget.descricao,
      motivo: _motivo!,
      texto: _texto.text,
    );
    if (mounted) Navigator.pop(context, ok);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Denunciar ${widget.tipo.rotulo.toLowerCase()}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.descricao,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            RadioGroup<MotivoDenuncia>(
              groupValue: _motivo,
              onChanged: (m) => setState(() => _motivo = m),
              child: Column(
                children: [
                  for (final m in MotivoDenuncia.values)
                    RadioListTile<MotivoDenuncia>(
                      value: m,
                      contentPadding: EdgeInsets.zero,
                      title: Text(m.rotulo),
                    ),
                ],
              ),
            ),
            TextField(
              controller: _texto,
              maxLines: 3,
              maxLength: Denuncia.tamanhoMaximoTexto,
              decoration: const InputDecoration(
                labelText: 'Detalhes (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _motivo == null || _enviando ? null : _enviar,
              child: Text(_enviando ? 'Enviando...' : 'Enviar denúncia'),
            ),
          ],
        ),
      ),
    );
  }
}

void _avisar(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
}
