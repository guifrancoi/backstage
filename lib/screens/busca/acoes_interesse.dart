import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/agenda_publica.dart';
import '../../models/contratacao.dart';
import '../../models/interesse.dart';
import '../../models/musico.dart';
import '../../models/oportunidade.dart';
import '../../providers/agenda_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../providers/perfil_provider.dart';
import '../../routes/app_routes.dart';
import 'painel_convite.dart';

/// Ações de candidatura/convite compartilhadas pelas telas de lista e de
/// detalhe da busca.

/// Aviso (não bloqueia) sobre o dia na agenda do músico: ocupado por outro
/// show confirmado ou bloqueado por ele. `null` = dia livre ou agenda
/// indisponível (todo dia é livre por padrão).
String? avisoAgenda(AgendaPublica? agenda, DateTime data) {
  if (agenda == null) return null;
  final dia = Contratacao.diaDe(data);
  if (agenda.ocupado(dia)) return 'O músico já tem um show confirmado nesse dia.';
  if (agenda.bloqueado(dia)) return 'O músico bloqueou esse dia na agenda.';
  return null;
}

/// Lê a agenda pública uma vez; `null` se falhar ou demorar (o aviso some,
/// mas a ação continua possível).
Future<AgendaPublica?> carregarAgendaPublica(
  BuildContext context,
  String musicoId,
) async {
  final agenda = context.read<AgendaProvider>().agendaPublica(musicoId);
  try {
    return await agenda.first.timeout(const Duration(seconds: 5));
  } catch (_) {
    return null;
  }
}

/// Escolhe o dia do filtro "livres em" da lista de músicos (Plano 13).
Future<void> escolherDiaLivre(BuildContext context) async {
  final provider = context.read<OportunidadeProvider>();
  final agora = DateTime.now();
  final hoje = DateTime(agora.year, agora.month, agora.day);
  final atual = provider.livresEm;
  final escolhida = await showDatePicker(
    context: context,
    helpText: 'Músicos livres em',
    initialDate: atual != null && !atual.isBefore(hoje) ? atual : hoje,
    firstDate: hoje,
    lastDate: DateTime(hoje.year + 2),
  );
  if (escolhida != null) provider.filtrarMusicosLivresEm(escolhida);
}

/// Músico (ou admin) se candidata a oportunidade de outro dono que ainda não
/// aconteceu (catálogo sem dono e vencida não; as regras também recusam).
bool podeCandidatar(AuthProvider auth, Oportunidade oportunidade) {
  return auth.atuaComoMusico &&
      oportunidade.temDono &&
      !oportunidade.vencida &&
      oportunidade.donoId != auth.userId;
}

/// Dono de estabelecimento (ou admin) convida músico.
bool podeConvidar(AuthProvider auth, Musico musico) {
  return auth.atuaComoDono && musico.id != auth.userId;
}

/// Dono da oportunidade ou admin podem editá-la e removê-la.
bool podeGerenciar(AuthProvider auth, Oportunidade oportunidade) {
  return auth.isAdmin ||
      (oportunidade.temDono && oportunidade.donoId == auth.userId);
}

/// Pede confirmação e remove a oportunidade; devolve se removeu.
Future<bool> confirmarRemocao(
  BuildContext context,
  Oportunidade oportunidade,
) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Remover oportunidade'),
      content: Text(
        'Remover "${oportunidade.titulo}"? Essa ação não pode ser desfeita. '
        'Candidaturas e convites pendentes serão encerrados e os músicos '
        'interessados serão avisados.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Remover'),
        ),
      ],
    ),
  );

  if (confirmar != true || !context.mounted) return false;

  final provider = context.read<OportunidadeProvider>();
  final ok = await provider.removerOportunidade(oportunidade.id);
  if (!context.mounted) return ok;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ok
            ? 'Oportunidade removida.'
            : provider.errorMessage ?? 'Não foi possível remover.',
      ),
    ),
  );
  return ok;
}

Future<void> confirmarCandidatura(
  BuildContext context,
  Oportunidade oportunidade,
) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Candidatar-se'),
      content: Text(
        'Enviar sua candidatura para "${oportunidade.titulo}"? '
        'O contratante poderá aceitar ou recusar.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Enviar'),
        ),
      ],
    ),
  );

  if (confirmar != true || !context.mounted) return;

  final auth = context.read<AuthProvider>();
  final perfil = context.read<PerfilProvider>().perfilMusico;
  final interesses = context.read<InteresseProvider>();

  final ok = await interesses.enviarCandidatura(
    oportunidade: oportunidade,
    remetenteId: auth.userId!,
    remetenteNome: auth.nomeExibicao,
    musicoNome: perfil?.nomeArtistico ?? auth.nomeExibicao,
  );

  if (!context.mounted) return;
  _avisar(
    context,
    ok ? 'Candidatura enviada!' : interesses.errorMessage ?? 'Não foi possível enviar.',
  );
}

/// Texto do botão de convite: sempre ativo; mostra quantos convites ao
/// músico ainda esperam resposta.
String rotuloConvidar(InteresseProvider interesses, String musicoId) {
  final pendentes = interesses.convitesPendentesPara(musicoId);
  return pendentes == 0 ? 'Convidar' : 'Convidar ($pendentes pendente${pendentes == 1 ? '' : 's'})';
}

/// Abre o painel de convite (escolha da oportunidade, com o estado de cada
/// uma) e envia. Se o músico já se candidatou à oportunidade escolhida,
/// `enviarConvite` aceita a candidatura (match).
Future<void> confirmarConvite(BuildContext context, Musico musico) async {
  final auth = context.read<AuthProvider>();
  final interesses = context.read<InteresseProvider>();
  final catalogo = context.read<OportunidadeProvider>();
  // Só oportunidades que ainda vão acontecer (as regras recusam as vencidas).
  final minhas = catalogo
      .minhasOportunidades(auth.userId)
      .where((o) => !o.vencida)
      .toList();
  // Buscando músicos livres num dia: já marca a oportunidade daquele dia.
  final livresEm = catalogo.livresEm;
  final sugerida = livresEm == null
      ? null
      : minhas
            .where(
              (o) =>
                  Contratacao.diaDe(o.dataEvento) ==
                      Contratacao.diaDe(livresEm) &&
                  interesses
                      .situacaoConvite(musico.id, oportunidadeId: o.id)
                      .selecionavel,
            )
            .firstOrNull;

  final agenda = await carregarAgendaPublica(context, musico.id);
  if (!context.mounted) return;

  // Interesse aceito entre os dois = já conversam (uma conversa por par).
  final aceito = interesses.aceitoCom(musico.id);
  final escolha = await abrirPainelConvite(
    context,
    musico: musico,
    oportunidades: minhas,
    agenda: agenda,
    jaConversam: aceito != null,
    marcadaInicial: sugerida?.id,
  );
  if (escolha == null || !context.mounted) return;
  if (escolha.abrirConversa && aceito != null) {
    final conversaId = await interesses.abrirConversa(
      aceito,
      meuUid: auth.userId!,
      meuNome: auth.nomeExibicao,
    );
    if (!context.mounted) return;
    if (conversaId == null) {
      _avisar(context, interesses.errorMessage ?? 'Não foi possível abrir a conversa.');
      return;
    }
    Navigator.pushNamed(context, AppRoutes.chat, arguments: conversaId);
    return;
  }

  final oportunidade = escolha.oportunidade;
  final eraCandidatura =
      interesses.situacaoConvite(musico.id, oportunidadeId: oportunidade?.id) ==
      SituacaoConvite.candidaturaPendente;
  final ok = await interesses.enviarConvite(
    musico: musico,
    remetenteId: auth.userId!,
    remetenteNome: auth.nomeExibicao,
    oportunidade: oportunidade,
  );

  if (!context.mounted) return;
  _avisar(
    context,
    !ok
        ? interesses.errorMessage ?? 'Não foi possível enviar.'
        : eraCandidatura
        ? 'Candidatura aceita! A conversa foi aberta.'
        : 'Convite enviado!',
  );
}

void _avisar(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
}
