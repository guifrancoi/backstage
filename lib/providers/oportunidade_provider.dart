import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/logging/app_logger.dart';
import '../core/utils/compatibilidade.dart';
import '../core/utils/texto.dart';
import '../models/agenda_publica.dart';
import '../models/contratacao.dart';
import '../models/denuncia.dart';
import '../models/filtro_musicos.dart';
import '../models/filtro_oportunidades.dart';
import '../models/interesse.dart';
import '../models/musico.dart';
import '../models/notificacao.dart';
import '../models/oportunidade.dart';
import '../services/firebase_data_service.dart';

/// Catálogo de músicos e oportunidades (busca, filtros, ordenação) e as
/// oportunidades criadas pelo dono logado. Interesses ficam no
/// `InteresseProvider`.
class OportunidadeProvider extends ChangeNotifier {
  OportunidadeProvider({FirebaseDataService? service})
    : _service = service ?? FirebaseDataService() {
    _authSubscription = _service.authUserIds.listen(_escutar);
  }

  final FirebaseDataService _service;
  StreamSubscription<String?>? _authSubscription;
  StreamSubscription<List<Musico>>? _musicosSubscription;
  StreamSubscription<List<Oportunidade>>? _oportunidadesSubscription;
  StreamSubscription<AgendaPublica>? _minhaAgendaSubscription;
  StreamSubscription<Set<String>>? _indisponiveisSubscription;
  StreamSubscription<Set<String>>? _assinantesSubscription;
  StreamSubscription<({Set<String> musicos, Set<String> oportunidades})>?
  _favoritosSubscription;

  /// Favoritos do usuário logado (Plano 18): o dono guarda músicos e o
  /// músico guarda oportunidades.
  StreamSubscription<List<UsuarioBloqueado>>? _bloqueadosSubscription;

  /// Quem o usuário logado bloqueou (Plano 22): some das listas, das
  /// sugestões e dos favoritos.
  List<UsuarioBloqueado> _bloqueados = [];
  Set<String> _uidsBloqueados = {};

  Set<String> _musicosFavoritos = {};
  Set<String> _oportunidadesFavoritas = {};
  bool _soFavoritos = false;

  /// Uids com assinatura válida (Plano 7): vêm primeiro nas listas e
  /// desempatam as sugestões.
  Set<String> _assinantes = {};

  /// Filtro "livres em [dia]" da lista de músicos (Plano 13): sai quem
  /// bloqueou o dia ou já tem show confirmado nele.
  DateTime? _livresEm;
  Set<String> _indisponiveis = {};
  bool _carregandoLivres = false;

  /// Agenda do próprio usuário: base do filtro "só dias em que estou livre"
  /// (Plano 12).
  AgendaPublica _minhaAgenda = const AgendaPublica();

  List<Musico> _todosMusicos = [];
  List<Oportunidade> _todasOportunidades = [];
  List<Musico> _musicos = [];
  List<Oportunidade> _oportunidades = [];

  bool _carregandoMusicos = false;
  bool _carregandoOportunidades = false;
  bool _erroMusicos = false;
  bool _erroOportunidades = false;

  /// Admin enxerga os itens `oculto` (criados por ele); os outros não.
  bool _isAdmin = false;

  bool get carregandoMusicos => _carregandoMusicos;
  bool get carregandoOportunidades => _carregandoOportunidades;
  bool get erroMusicos => _erroMusicos;
  bool get erroOportunidades => _erroOportunidades;

  /// As regras exigem login para ler o catálogo: no logout o Firestore
  /// encerra os listeners, e sem reassinar a lista ficaria congelada no
  /// próximo login. Por isso reassina a cada troca de conta.
  void _escutar(String? uid) {
    _assinarLivresEm();
    _musicosSubscription?.cancel();
    _oportunidadesSubscription?.cancel();
    _minhaAgendaSubscription?.cancel();
    _assinantesSubscription?.cancel();
    _assinantesSubscription = null;
    _assinantes = {};
    _favoritosSubscription?.cancel();
    _favoritosSubscription = null;
    _bloqueadosSubscription?.cancel();
    _bloqueadosSubscription = null;
    _bloqueados = [];
    _uidsBloqueados = {};
    _musicosFavoritos = {};
    _oportunidadesFavoritas = {};
    _musicosSubscription = null;
    _oportunidadesSubscription = null;
    _minhaAgendaSubscription = null;
    _minhaAgenda = const AgendaPublica();
    _todosMusicos = [];
    _todasOportunidades = [];
    _erroMusicos = false;
    _erroOportunidades = false;
    _carregandoMusicos = uid != null;
    _carregandoOportunidades = uid != null;
    _isAdmin = false;
    _aplicarFiltrosAtuais();
    notifyListeners();
    if (uid == null) return;

    _service.ehAdmin().then((admin) {
      if (!admin || _service.currentUserId != uid) return;
      _isAdmin = true;
      _aplicarFiltrosAtuais();
      notifyListeners();
    }, onError: AppLogger.aoFalhar(_origem, 'Falha ao conferir admin'));

    _musicosSubscription = _service.streamMusicos().listen(
      (lista) {
        _todosMusicos = lista;
        _carregandoMusicos = false;
        _aplicarFiltrosAtuais();
        notifyListeners();
      },
      onError: (Object e, StackTrace s) {
        AppLogger.falha(_origem, 'Falha no stream de músicos', e, s);
        _carregandoMusicos = false;
        _erroMusicos = true;
        notifyListeners();
      },
    );
    _minhaAgendaSubscription = _service.streamAgendaPublica(uid).listen((
      agenda,
    ) {
      _minhaAgenda = agenda;
      _aplicarFiltrosAtuais();
      notifyListeners();
    }, onError: AppLogger.aoFalhar(_origem, 'Falha na minha agenda'));
    _bloqueadosSubscription = _service.streamBloqueados(uid).listen((lista) {
      _bloqueados = [...lista]
        ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
      _uidsBloqueados = {for (final b in lista) b.uid};
      _aplicarFiltrosAtuais();
      notifyListeners();
    }, onError: AppLogger.aoFalhar(_origem, 'Falha nos bloqueados'));
    _favoritosSubscription = _service.streamFavoritos(uid).listen((favoritos) {
      _musicosFavoritos = favoritos.musicos;
      _oportunidadesFavoritas = favoritos.oportunidades;
      _aplicarFiltrosAtuais();
      notifyListeners();
    }, onError: AppLogger.aoFalhar(_origem, 'Falha nos favoritos'));
    _assinantesSubscription = _service.streamAssinantes().listen((uids) {
      _assinantes = uids;
      _aplicarFiltrosAtuais();
      notifyListeners();
    }, onError: AppLogger.aoFalhar(_origem, 'Falha nos assinantes'));
    _oportunidadesSubscription = _service.streamOportunidades().listen(
      (lista) {
        _todasOportunidades = lista;
        _carregandoOportunidades = false;
        _aplicarFiltrosAtuais();
        notifyListeners();
      },
      onError: (Object e, StackTrace s) {
        AppLogger.falha(_origem, 'Falha no stream de oportunidades', e, s);
        _carregandoOportunidades = false;
        _erroOportunidades = true;
        notifyListeners();
      },
    );
  }

  String? _generoSelecionadoMusicos;
  String? _cidadeFiltroMusicos;
  Formacao? _formacaoFiltro;
  bool _soEquipamentoProprio = false;
  String _termoPesquisa = '';
  String _tipoOrdenacao = 'nome_asc';

  FiltroOportunidades _filtroOportunidades = const FiltroOportunidades();

  String? _errorMessage;

  List<Musico> get musicos => _musicos;
  List<Oportunidade> get oportunidades => _oportunidades;

  String? get generoSelecionadoMusicos => _generoSelecionadoMusicos;
  String? get cidadeFiltroMusicos => _cidadeFiltroMusicos;
  Formacao? get formacaoFiltro => _formacaoFiltro;
  bool get soEquipamentoProprio => _soEquipamentoProprio;

  /// Todos os critérios atuais da lista de músicos (painel "Filtrar").
  FiltroMusicos get filtroMusicos => FiltroMusicos(
    termo: _termoPesquisa,
    genero: _generoSelecionadoMusicos,
    cidade: _cidadeFiltroMusicos,
    formacao: _formacaoFiltro,
    soEquipamentoProprio: _soEquipamentoProprio,
    livresEm: _livresEm,
    soFavoritos: _soFavoritos,
    ordenacao: _tipoOrdenacao,
  );

  /// Troca todos os critérios de uma vez (painel e chips da lista). Só
  /// refaz a consulta do "livres em" se o dia mudou.
  void aplicarFiltroMusicos(FiltroMusicos filtro) {
    _termoPesquisa = filtro.termo.trim();
    _generoSelecionadoMusicos = filtro.genero;
    _cidadeFiltroMusicos = filtro.cidade;
    _formacaoFiltro = filtro.formacao;
    _soEquipamentoProprio = filtro.soEquipamentoProprio;
    _soFavoritos = filtro.soFavoritos;
    _tipoOrdenacao = filtro.ordenacao;
    final dia = filtro.livresEm;
    final mesmoDia = dia == null
        ? _livresEm == null
        : _livresEm != null &&
              Contratacao.diaDe(dia) == Contratacao.diaDe(_livresEm!);
    if (mesmoDia) {
      _aplicarFiltrosAtuais();
      notifyListeners();
    } else {
      filtrarMusicosLivresEm(dia);
    }
  }

  /// Dia do filtro "livres em" (`null` = sem filtro de data).
  DateTime? get livresEm => _livresEm;

  /// A consulta do dia ainda não respondeu: a lista não é confiável.
  bool get carregandoLivres => _carregandoLivres;
  String get termoPesquisa => _termoPesquisa;
  String get tipoOrdenacao => _tipoOrdenacao;
  String? get errorMessage => _errorMessage;
  FiltroOportunidades get filtroOportunidades => _filtroOportunidades;

  /// Oportunidades do dono [donoId], da mais próxima para a mais distante.
  List<Oportunidade> minhasOportunidades(String? donoId) {
    if (donoId == null) return [];
    return _todasOportunidades.where((o) => o.donoId == donoId).toList()
      ..sort((a, b) => a.dataEvento.compareTo(b.dataEvento));
  }

  /// Grava a oportunidade com `donoId` = [donoId]; o stream traz o documento
  /// de volta. O que a conta admin cria sai `oculto`.
  Future<bool> criarOportunidade(Oportunidade oportunidade, String donoId) async {
    final comDono = oportunidade.copyWith(donoId: donoId, oculto: _isAdmin);
    return _gravar(() => _service.criarOportunidade(comDono), acao: 'criar');
  }

  /// Edita uma oportunidade existente (dono ou admin, pelas regras). Mantém
  /// `donoId` e `oculto` originais. Se mudou data, horário, cachê ou local,
  /// avisa os músicos com interesse pendente ou aceito nela.
  Future<bool> atualizarOportunidade(Oportunidade oportunidade) async {
    final original = buscarOportunidadePorId(oportunidade.id);
    final editada = oportunidade.copyWith(
      donoId: original?.donoId,
      oculto: original?.oculto,
    );
    final ok = await _gravar(
      () => _service.atualizarOportunidade(editada),
      acao: 'editar',
    );
    final uid = _service.currentUserId;
    // Admin editando a de outro dono não lê os interesses alheios.
    if (ok &&
        original != null &&
        uid == original.donoId &&
        Notificacao.mudancas(original, editada).isNotEmpty) {
      final interessados = await _interessadosSemFalhar(uid!, editada.id);
      await _service.tentarNotificar([
        for (final interesse in interessados)
          ?Notificacao.oportunidadeAlterada(
            interesse,
            antes: original,
            depois: editada,
            nomeDono: editada.contratante,
          ),
      ]);
    }
    return ok;
  }

  /// Remove a oportunidade. Do próprio dono: bloqueia se houver contratação
  /// em andamento; senão encerra os interesses pendentes (candidatura →
  /// recusada, convite → cancelado) no mesmo batch e avisa os interessados.
  /// Admin removendo a de outro dono só apaga (não lê interesses alheios).
  Future<bool> removerOportunidade(String oportunidadeId) async {
    final original = buscarOportunidadePorId(oportunidadeId);
    final uid = _service.currentUserId;
    if (original == null || uid == null || original.donoId != uid) {
      return _gravar(
        () => _service.removerOportunidade(oportunidadeId),
        acao: 'remover',
      );
    }

    var bloqueada = false;
    var interessados = <Interesse>[];
    final ok = await _gravar(() async {
      final ativas = await _service.contratacoesAtivasDaOportunidade(
        uid,
        oportunidadeId,
      );
      if (ativas.isNotEmpty) {
        bloqueada = true;
        return;
      }
      interessados = (await _service.interessesDaOportunidade(
        uid,
        oportunidadeId,
      )).where(_ativo).toList();
      await _service.encerrarOportunidade(oportunidadeId, interessados);
    }, acao: 'remover');

    if (bloqueada) {
      _errorMessage =
          'Há contratação em andamento para esta oportunidade. '
          'Cancele-a antes de remover.';
      notifyListeners();
      return false;
    }
    if (ok) {
      await _service.tentarNotificar([
        for (final interesse in interessados)
          Notificacao.oportunidadeRemovida(
            interesse,
            tituloOportunidade: original.titulo,
            nomeDono: original.contratante,
          ),
      ]);
    }
    return ok;
  }

  /// Interesse que ainda importa ao músico: pendente ou aceito.
  static bool _ativo(Interesse i) =>
      i.status == StatusInteresse.pendente || i.status == StatusInteresse.aceito;

  Future<List<Interesse>> _interessadosSemFalhar(
    String uid,
    String oportunidadeId,
  ) async {
    try {
      final lista = await _service.interessesDaOportunidade(uid, oportunidadeId);
      return lista.where(_ativo).toList();
    } catch (erro, stack) {
      AppLogger.falha(_origem, 'Falha ao ler interessados', erro, stack);
      return [];
    }
  }

  /// Grava no Firestore; o stream traz o resultado de volta.
  Future<bool> _gravar(
    Future<void> Function() gravacao, {
    required String acao,
  }) async {
    _errorMessage = null;
    try {
      await gravacao();
      return true;
    } on FirebaseException catch (error, stack) {
      AppLogger.falha(_origem, 'Falha ao gravar oportunidade', error, stack);
      _errorMessage = error.code == 'permission-denied'
          ? 'Sem permissão para $acao esta oportunidade.'
          : 'Não foi possível $acao a oportunidade.';
      notifyListeners();
      return false;
    }
  }

  /// Troca os critérios de perfil (o que não vier fica sem filtro).
  /// Formação e equipamento próprio são do Plano 14.
  void filtrarMusicos({
    String? genero,
    String? cidade,
    Formacao? formacao,
    bool soEquipamentoProprio = false,
  }) {
    _generoSelecionadoMusicos = genero;
    _cidadeFiltroMusicos = cidade;
    _formacaoFiltro = formacao;
    _soEquipamentoProprio = soEquipamentoProprio;
    _aplicarFiltrosAtuais();
    notifyListeners();
  }

  /// Mostra só os músicos livres no [dia] (sem bloqueio e sem show
  /// confirmado); `null` tira o filtro. Combina com gênero, cidade,
  /// pesquisa e ordem.
  void filtrarMusicosLivresEm(DateTime? dia) {
    _pararLivresEm();
    if (dia != null) {
      _livresEm = DateTime(dia.year, dia.month, dia.day);
      _assinarLivresEm();
    }
    _aplicarFiltrosAtuais();
    notifyListeners();
  }

  /// Assina a consulta do dia de [_livresEm]. Como o catálogo, é refeita a
  /// cada troca de conta (o listener morre no logout).
  void _assinarLivresEm() {
    final dia = _livresEm;
    _indisponiveisSubscription?.cancel();
    _indisponiveis = {};
    _carregandoLivres = dia != null && _service.currentUserId != null;
    if (!_carregandoLivres) return;
    _indisponiveisSubscription = _service
        .streamIndisponiveisNoDia(Contratacao.diaDe(dia!))
        .listen(
          (uids) {
            _indisponiveis = uids;
            _carregandoLivres = false;
            _aplicarFiltrosAtuais();
            notifyListeners();
          },
          onError: (Object e, StackTrace s) {
            AppLogger.falha(_origem, 'Falha nos livres do dia', e, s);
            // Sem a consulta não dá para saber quem está livre: tira o
            // filtro em vez de mostrar todos como livres.
            _pararLivresEm();
            _errorMessage = 'Não foi possível consultar a agenda do dia.';
            _aplicarFiltrosAtuais();
            notifyListeners();
          },
        );
  }

  void _pararLivresEm() {
    _indisponiveisSubscription?.cancel();
    _indisponiveisSubscription = null;
    _livresEm = null;
    _indisponiveis = {};
    _carregandoLivres = false;
  }

  void resetarFiltroMusicos() {
    _pararLivresEm();
    _generoSelecionadoMusicos = null;
    _cidadeFiltroMusicos = null;
    _formacaoFiltro = null;
    _soEquipamentoProprio = false;
    _soFavoritos = false;
    _termoPesquisa = '';
    _tipoOrdenacao = 'nome_asc';
    _aplicarFiltrosAtuais();
    notifyListeners();
  }

  void pesquisarMusicos(String termo) {
    _termoPesquisa = termo;
    _aplicarFiltrosAtuais();
    notifyListeners();
  }

  void ordenarMusicos(String tipo) {
    _tipoOrdenacao = tipo;
    _aplicarFiltrosAtuais();
    notifyListeners();
  }

  /// Troca o filtro da lista pública de oportunidades (Plano 12).
  void filtrarOportunidades(FiltroOportunidades filtro) {
    _filtroOportunidades = filtro;
    _aplicarFiltrosAtuais();
    notifyListeners();
  }

  void resetarFiltroOportunidades() =>
      filtrarOportunidades(const FiltroOportunidades());

  Musico? buscarMusicoPorId(String id) {
    for (final musico in _todosMusicos) {
      if (musico.id == id) return musico;
    }
    return null;
  }

  Oportunidade? buscarOportunidadePorId(String id) {
    for (final oportunidade in _todasOportunidades) {
      if (oportunidade.id == id) return oportunidade;
    }
    return null;
  }

  void _aplicarFiltrosAtuais() {
    _musicos = _todosMusicos.where((m) {
      if (m.oculto && !_isAdmin) return false;
      if (ehBloqueado(m.id)) return false;
      if (_livresEm != null && _indisponiveis.contains(m.id)) return false;
      if (_formacaoFiltro != null && m.formacao != _formacaoFiltro) {
        return false;
      }
      if (_soEquipamentoProprio && !m.equipamentoProprio) return false;
      if (_soFavoritos && !_musicosFavoritos.contains(m.id)) return false;
      final genero = _generoSelecionadoMusicos;
      final cidade = _cidadeFiltroMusicos;

      final generoValido =
          genero == null || genero.isEmpty || m.generoMusical == genero;

      final cidadeValida =
          cidade == null ||
          cidade.isEmpty ||
          m.cidade.toLowerCase().contains(cidade.toLowerCase());

      final pesquisaValida = contemTermo(_termoPesquisa, [
        m.nomeArtistico,
        m.descricao,
        m.generoMusical,
        m.cidade,
      ]);

      return generoValido && cidadeValida && pesquisaValida;
    }).toList();

    _aplicarOrdenacao();
    // Plano 7: depois dos filtros e da ordem escolhida, assinantes no topo.
    _musicos = assinantesPrimeiro(_musicos, (m) => ehAssinante(m.id));

    // Lista pública: sem ocultas (exceto para o admin) e sem vencidas;
    // oportunidades de dono assinante primeiro.
    _oportunidades = assinantesPrimeiro(
      _filtroOportunidades.aplicar(
        _todasOportunidades.where(
          (o) => (!o.oculto || _isAdmin) && !ehBloqueado(o.donoId),
        ),
        hoje: DateTime.now(),
        bloqueados: _minhaAgenda.bloqueados,
        ocupados: _minhaAgenda.ocupados,
        favoritas: _oportunidadesFavoritas,
      ),
      (o) => ehAssinante(o.donoId),
    );
  }

  bool ehAssinante(String uid) => _assinantes.contains(uid);

  /// Plano 22: o usuário logado bloqueou [uid].
  bool ehBloqueado(String uid) => _uidsBloqueados.contains(uid);

  /// Bloqueados, em ordem de nome (tela "Usuários bloqueados").
  List<UsuarioBloqueado> get bloqueados => _bloqueados;

  /// Bloqueia [uid] e encerra o que está pendente entre os dois (interesses
  /// e negociações; shows confirmados ficam). Devolve se bloqueou — se só o
  /// encerramento falhar, bloqueia mesmo assim e avisa em [errorMessage].
  Future<bool> bloquear(String uid, String nome) async {
    final meuUid = _service.currentUserId;
    if (meuUid == null || uid == meuUid) return false;
    _errorMessage = null;
    try {
      await _service.bloquearUsuario(
        meuUid,
        UsuarioBloqueado(uid: uid, nome: nome, criadoEm: DateTime.now()),
      );
    } on FirebaseException catch (erro, stack) {
      AppLogger.falha(_origem, 'Falha ao bloquear', erro, stack);
      _errorMessage = 'Não foi possível bloquear.';
      notifyListeners();
      return false;
    }
    try {
      await _service.encerrarPendentesCom(meuUid, uid);
    } on FirebaseException catch (erro, stack) {
      AppLogger.falha(_origem, 'Falha ao encerrar pendentes', erro, stack);
      _errorMessage =
          'Bloqueado, mas algum pendente não pôde ser encerrado. '
          'Confira Interesses e Contratações.';
      notifyListeners();
    }
    return true;
  }

  Future<bool> desbloquear(String uid) async {
    final meuUid = _service.currentUserId;
    if (meuUid == null) return false;
    _errorMessage = null;
    try {
      await _service.desbloquearUsuario(meuUid, uid);
      return true;
    } on FirebaseException catch (erro, stack) {
      AppLogger.falha(_origem, 'Falha ao desbloquear', erro, stack);
      _errorMessage = 'Não foi possível desbloquear.';
      notifyListeners();
      return false;
    }
  }

  bool ehMusicoFavorito(String musicoId) =>
      _musicosFavoritos.contains(musicoId);

  bool ehOportunidadeFavorita(String oportunidadeId) =>
      _oportunidadesFavoritas.contains(oportunidadeId);

  /// Marca/desmarca o músico como favorito (Plano 18). O stream traz o
  /// resultado de volta; devolve se gravou.
  Future<bool> alternarMusicoFavorito(String musicoId) => _alternarFavorito(
    'musico',
    musicoId,
    favorito: ehMusicoFavorito(musicoId),
  );

  Future<bool> alternarOportunidadeFavorita(String oportunidadeId) =>
      _alternarFavorito(
        'oportunidade',
        oportunidadeId,
        favorito: ehOportunidadeFavorita(oportunidadeId),
      );

  Future<bool> _alternarFavorito(
    String tipo,
    String alvoId, {
    required bool favorito,
  }) async {
    final uid = _service.currentUserId;
    if (uid == null) return false;
    _errorMessage = null;
    try {
      if (favorito) {
        await _service.desfavoritar(uid, tipo, alvoId);
      } else {
        await _service.favoritar(uid, tipo, alvoId);
      }
      return true;
    } on FirebaseException catch (erro, stack) {
      AppLogger.falha(_origem, 'Falha ao alternar favorito', erro, stack);
      _errorMessage = 'Não foi possível atualizar os favoritos.';
      notifyListeners();
      return false;
    }
  }

  /// Uids indisponíveis no dia (bloqueio ou show), para as sugestões do
  /// dono (Plano 15) — mesma consulta do filtro "livres em".
  Stream<Set<String>> indisponiveisNoDia(DateTime dia) =>
      _service.streamIndisponiveisNoDia(Contratacao.diaDe(dia));

  /// Plano 15, lado do dono: músicos mais compatíveis com [oportunidade].
  /// [indisponiveis] `null` = agenda do dia desconhecida (não elimina, mas
  /// ninguém ganha "livre no dia"). [comInteresse]: músicos que já têm
  /// convite ou candidatura nessa oportunidade.
  List<Sugestao<Musico>> musicosSugeridos(
    Oportunidade oportunidade, {
    required Set<String>? indisponiveis,
    required Set<String> comInteresse,
    int limite = 5,
  }) {
    final hoje = DateTime.now();
    return ordenarSugestoes(
      [
        for (final musico in _todosMusicos.where((m) => !ehBloqueado(m.id)))
          if (avaliarCompatibilidade(
                musico: musico,
                oportunidade: oportunidade,
                hoje: hoje,
                ocupado: indisponiveis?.contains(musico.id) ?? false,
                agendaConhecida: indisponiveis != null,
                jaTemInteresse: comInteresse.contains(musico.id),
              )
              case final avaliacao?)
            Sugestao(musico, avaliacao, assinante: ehAssinante(musico.id)),
      ],
      desempate: (a, b) => a.nomeArtistico.toLowerCase().compareTo(
        b.nomeArtistico.toLowerCase(),
      ),
      limite: limite,
    );
  }

  /// Plano 15, lado do músico: oportunidades futuras mais compatíveis com o
  /// perfil [musico] (o do usuário logado), usando a própria agenda.
  /// [comInteresse]: oportunidades em que já há candidatura ou convite.
  List<Sugestao<Oportunidade>> oportunidadesSugeridas(
    Musico musico, {
    required Set<String> comInteresse,
    int limite = 3,
  }) {
    final hoje = DateTime.now();
    return ordenarSugestoes(
      [
        for (final oportunidade in _todasOportunidades.where(
          (o) => !ehBloqueado(o.donoId),
        ))
          if (avaliarCompatibilidade(
                musico: musico,
                oportunidade: oportunidade,
                hoje: hoje,
                ocupado: _minhaAgenda.ocupado(
                  Contratacao.diaDe(oportunidade.dataEvento),
                ),
                bloqueado: _minhaAgenda.bloqueado(
                  Contratacao.diaDe(oportunidade.dataEvento),
                ),
                jaTemInteresse: comInteresse.contains(oportunidade.id),
              )
              case final avaliacao?)
            Sugestao(
              oportunidade,
              avaliacao,
              assinante: ehAssinante(oportunidade.donoId),
            ),
      ],
      desempate: (a, b) => a.dataEvento.compareTo(b.dataEvento),
      limite: limite,
    );
  }

  void _aplicarOrdenacao() {
    switch (_tipoOrdenacao) {
      case 'nome_asc':
        _musicos.sort(
          (a, b) => a.nomeArtistico.toLowerCase().compareTo(
            b.nomeArtistico.toLowerCase(),
          ),
        );
        break;
      case 'nome_desc':
        _musicos.sort(
          (a, b) => b.nomeArtistico.toLowerCase().compareTo(
            a.nomeArtistico.toLowerCase(),
          ),
        );
        break;
      case 'cache_maior':
        _musicos.sort((a, b) => b.cacheMedio.compareTo(a.cacheMedio));
        break;
      case 'cache_menor':
        _musicos.sort((a, b) => a.cacheMedio.compareTo(b.cacheMedio));
        break;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _musicosSubscription?.cancel();
    _oportunidadesSubscription?.cancel();
    _minhaAgendaSubscription?.cancel();
    _indisponiveisSubscription?.cancel();
    _assinantesSubscription?.cancel();
    _favoritosSubscription?.cancel();
    _bloqueadosSubscription?.cancel();
    super.dispose();
  }
}

const _origem = 'OportunidadeProvider';
