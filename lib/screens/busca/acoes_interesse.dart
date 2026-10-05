import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/logging/app_logger.dart';
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
  } catch (erro, stack) {
    AppLogger.falha(_origem, 'Falha ao ler agenda pública', erro, stack);
    return null;
  }
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

/// Plano 18: o dono (ou admin) favorita músicos.
bool podeFavoritarMusico(AuthProvider auth, Musico musico) =>
    auth.atuaComoDono && musico.id != auth.userId;

/// Plano 18: o músico (ou admin) favorita oportunidades de outros donos.
bool podeFavoritarOportunidade(AuthProvider auth, Oportunidade oportunidade) =>
    auth.atuaComoMusico &&
    oportunidade.temDono &&
    oportunidade.donoId != auth.userId;

/// Liga/desliga o favorito e avisa só se falhar.
Future<void> alternarFavorito(
  BuildContext context,
  Future<bool> Function(OportunidadeProvider) alternar,
) async {
  final provider = context.read<OportunidadeProvider>();
  final ok = await alternar(provider);
  if (!ok && context.mounted) {
    _avisar(context, provider.errorMessage ?? 'Não foi possível favoritar.');
  }
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
///
/// [oportunidade]: já vem marcada no painel (ex.: "Músicos sugeridos" no
/// detalhe da oportunidade, Plano 15).
Future<void> confirmarConvite(
  BuildContext context,
  Musico musico, {
  Oportunidade? oportunidade,
}) async {
  final auth = context.read<AuthProvider>();
  final interesses = context.read<InteresseProvider>();
  final catalogo = context.read<OportunidadeProvider>();
  // Só oportunidades que ainda vão acontecer (as regras recusam as vencidas).
  final minhas = catalogo
      .minhasOportunidades(auth.userId)
      .where((o) => !o.vencida)
      .toList();
  bool selecionavel(Oportunidade o) => interesses
      .situacaoConvite(musico.id, oportunidadeId: o.id)
      .selecionavel;
  // A oportunidade pedida; senão, buscando músicos livres num dia, a
  // oportunidade daquele dia.
  final livresEm = catalogo.livresEm;
  final sugerida = oportunidade != null
      ? minhas
            .where((o) => o.id == oportunidade.id && selecionavel(o))
            .firstOrNull
      : livresEm == null
      ? null
      : minhas
            .where(
              (o) =>
                  Contratacao.diaDe(o.dataEvento) ==
                      Contratacao.diaDe(livresEm) &&
                  selecionavel(o),
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

  final escolhida = escolha.oportunidade;
  final eraCandidatura =
      interesses.situacaoConvite(musico.id, oportunidadeId: escolhida?.id) ==
      SituacaoConvite.candidaturaPendente;
  final ok = await interesses.enviarConvite(
    musico: musico,
    remetenteId: auth.userId!,
    remetenteNome: auth.nomeExibicao,
    oportunidade: escolhida,
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

const _origem = 'acoes_interesse';
