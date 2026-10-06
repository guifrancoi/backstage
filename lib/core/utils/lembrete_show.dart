import '../../models/contratacao.dart';
import 'painel_numeros.dart';

/// Lembrete de show e "Adicionar à agenda" (Plano 19). Funções puras: nada
/// é gravado — o lembrete sai das contratações confirmadas que o
/// `ContratacaoProvider` já tem.

/// Um show confirmado de hoje ou de amanhã, do ponto de vista de [uid].
class LembreteShow {
  const LembreteShow(this.contratacao, {required this.hoje, required this.uid});

  final Contratacao contratacao;

  /// `true` = hoje; `false` = amanhã.
  final bool hoje;
  final String uid;

  bool get souMusico => uid == contratacao.musicoId;

  /// "Seu show é hoje às 21:00 em Bar Central" (músico) ou "Show de Banda X
  /// amanhã às 21:00" (dono).
  String get titulo {
    final quando = '${hoje ? 'hoje' : 'amanhã'} às ${contratacao.horaInicio}';
    return souMusico
        ? 'Seu show é $quando em ${contratacao.donoNome}'
        : 'Show de ${contratacao.musicoNome} $quando';
  }

  /// "Show de sexta · Rua A, 10 — Franca/SP".
  String get detalhe => '${contratacao.titulo} · ${contratacao.endereco}';
}

/// Shows confirmados de [uid] hoje ou amanhã, em ordem de dia e horário.
List<LembreteShow> lembretesDeShow(
  Iterable<Contratacao> contratacoes, {
  required String uid,
  required DateTime agora,
}) {
  final hoje = Contratacao.diaDe(agora);
  final amanha = Contratacao.diaDe(
    DateTime(agora.year, agora.month, agora.day + 1),
  );
  final lembretes = [
    for (final c in contratacoes)
      if (c.status == StatusContratacao.confirmada &&
          (c.musicoId == uid || c.donoId == uid) &&
          (c.dia == hoje || c.dia == amanha))
        LembreteShow(c, hoje: c.dia == hoje, uid: uid),
  ];
  return lembretes..sort(
    (a, b) => '${a.contratacao.dia} ${a.contratacao.horaInicio}'.compareTo(
      '${b.contratacao.dia} ${b.contratacao.horaInicio}',
    ),
  );
}

/// Link que abre o Google Agenda com o evento preenchido (título, horário no
/// fuso de Brasília, local e detalhes). Show que termina depois da
/// meia-noite (fim ≤ início) termina no dia seguinte.
Uri linkGoogleAgenda(Contratacao c, {required bool souMusico}) {
  final inicio = _dataHora(c.data, c.horaInicio);
  var fim = _dataHora(c.data, c.horaFim);
  if (!fim.isAfter(inicio)) fim = fim.add(const Duration(days: 1));

  final titulo = souMusico
      ? 'Show: ${c.titulo} (${c.donoNome})'
      : 'Show: ${c.titulo} (${c.musicoNome})';
  final detalhes = souMusico
      ? 'Contratante: ${c.donoNome}. Cachê: ${formatarReais(c.cacheAcordado, centavos: true)}.'
      : 'Artista: ${c.musicoNome}. Cachê: ${formatarReais(c.cacheAcordado, centavos: true)}.';

  final parametros = {
    'action': 'TEMPLATE',
    'text': titulo,
    'dates': '${_formato(inicio)}/${_formato(fim)}',
    'ctz': 'America/Sao_Paulo',
    'location': c.endereco,
    'details': detalhes,
  };
  final query = parametros.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');
  return Uri.parse('https://calendar.google.com/calendar/render?$query');
}

DateTime _dataHora(DateTime dia, String hora) {
  final partes = hora.split(':');
  return DateTime(
    dia.year,
    dia.month,
    dia.day,
    int.tryParse(partes.first) ?? 0,
    partes.length > 1 ? int.tryParse(partes[1]) ?? 0 : 0,
  );
}

/// `20261120T210000` (hora local, interpretada pelo `ctz`).
String _formato(DateTime d) {
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${d.year}${dois(d.month)}${dois(d.day)}T'
      '${dois(d.hour)}${dois(d.minute)}00';
}
