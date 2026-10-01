import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/data_hora.dart';
import '../../models/agenda_publica.dart';
import '../../models/interesse.dart';
import '../../models/musico.dart';
import '../../models/oportunidade.dart';
import '../../providers/interesse_provider.dart';
import '../../routes/app_routes.dart';
import 'acoes_interesse.dart' show avisoAgenda;

/// Escolha do painel: convite para [oportunidade] (`null` = sem oportunidade
/// específica) ou, se os dois já conversam, só abrir a conversa.
typedef EscolhaConvite = ({Oportunidade? oportunidade, bool abrirConversa});

/// Abre o painel de convite ao [musico] com as oportunidades futuras do dono
/// ([oportunidades]). Cada linha mostra o estado do convite **naquela**
/// oportunidade; as já resolvidas aparecem desabilitadas, com o motivo.
/// Devolve a escolha, ou `null` se o dono fechou sem enviar.
Future<EscolhaConvite?> abrirPainelConvite(
  BuildContext context, {
  required Musico musico,
  required List<Oportunidade> oportunidades,
  required AgendaPublica? agenda,
  bool jaConversam = false,
}) {
  return showModalBottomSheet<EscolhaConvite>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PainelConvite(
      musico: musico,
      oportunidades: oportunidades,
      agenda: agenda,
      jaConversam: jaConversam,
    ),
  );
}

class _PainelConvite extends StatefulWidget {
  const _PainelConvite({
    required this.musico,
    required this.oportunidades,
    required this.agenda,
    required this.jaConversam,
  });

  final Musico musico;
  final bool jaConversam;
  final List<Oportunidade> oportunidades;
  final AgendaPublica? agenda;

  @override
  State<_PainelConvite> createState() => _PainelConviteState();
}

class _PainelConviteState extends State<_PainelConvite> {
  /// Opção marcada: `''` = sem oportunidade; senão o id da oportunidade.
  String? _marcada;

  SituacaoConvite _situacao(InteresseProvider interesses, String? opId) =>
      interesses.situacaoConvite(widget.musico.id, oportunidadeId: opId);

  @override
  Widget build(BuildContext context) {
    final interesses = context.watch<InteresseProvider>();
    final semOportunidade = _situacao(interesses, null);
    final marcadaOp = _marcada == null || _marcada == ''
        ? null
        : widget.oportunidades.where((o) => o.id == _marcada).firstOrNull;
    final situacaoMarcada = _marcada == null
        ? null
        : _situacao(interesses, marcadaOp?.id);
    final podeEnviar = situacaoMarcada?.selecionavel ?? false;

    Widget opcao({
      required String valor,
      required String titulo,
      String? subtitulo,
      required SituacaoConvite situacao,
      String? aviso,
    }) {
      final habilitada = situacao.selecionavel;
      return RadioListTile<String>(
        value: valor,
        enabled: habilitada,
        contentPadding: EdgeInsets.zero,
        title: Text(titulo),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitulo != null) Text(subtitulo),
            if (situacao != SituacaoConvite.livre)
              Text(
                situacao.rotulo,
                style: TextStyle(
                  color: habilitada ? Colors.deepPurple : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (aviso != null && habilitada)
              Text(aviso, style: const TextStyle(color: Colors.orange)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Convidar ${widget.musico.nomeArtistico}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Para qual oportunidade?',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: RadioGroup<String>(
              groupValue: _marcada,
              onChanged: (valor) => setState(() => _marcada = valor),
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Convite "só para conversar" não faz sentido com quem já
                  // conversa: vira um atalho para a conversa do par.
                  if (widget.jaConversam)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.chat_bubble_outline),
                      title: const Text('Abrir conversa'),
                      subtitle: const Text('Vocês já conversam'),
                      onTap: () => Navigator.pop(
                        context,
                        (oportunidade: null, abrirConversa: true),
                      ),
                    )
                  else
                    opcao(
                      valor: '',
                      titulo: 'Sem oportunidade específica',
                      subtitulo: 'Só para abrir uma conversa',
                      situacao: semOportunidade,
                    ),
                  for (final o in widget.oportunidades)
                    opcao(
                      valor: o.id,
                      titulo: o.titulo,
                      subtitulo: o.horario.isEmpty
                          ? formatarData(o.dataEvento)
                          : '${formatarData(o.dataEvento)}, ${o.horario}',
                      situacao: _situacao(interesses, o.id),
                      aviso: avisoAgenda(widget.agenda, o.dataEvento),
                    ),
                ],
              ),
            ),
          ),
          if (widget.oportunidades.isEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Você não tem oportunidades futuras. Crie uma para convidar '
              'para um show.',
              style: TextStyle(color: Colors.grey),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.novaOportunidade);
              },
              icon: const Icon(Icons.add),
              label: const Text('Nova oportunidade'),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: podeEnviar
                ? () => Navigator.pop(
                    context,
                    (oportunidade: marcadaOp, abrirConversa: false),
                  )
                : null,
            child: Text(
              situacaoMarcada == SituacaoConvite.candidaturaPendente
                  ? 'Aceitar candidatura'
                  : 'Enviar convite',
            ),
          ),
        ],
      ),
    );
  }
}
