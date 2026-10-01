import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/agenda_publica.dart';
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
    _musicosSubscription?.cancel();
    _oportunidadesSubscription?.cancel();
    _minhaAgendaSubscription?.cancel();
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
    }, onError: (_) {});

    _musicosSubscription = _service.streamMusicos().listen(
      (lista) {
        _todosMusicos = lista;
        _carregandoMusicos = false;
        _aplicarFiltrosAtuais();
        notifyListeners();
      },
      onError: (_) {
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
    }, onError: (_) {});
    _oportunidadesSubscription = _service.streamOportunidades().listen(
      (lista) {
        _todasOportunidades = lista;
        _carregandoOportunidades = false;
        _aplicarFiltrosAtuais();
        notifyListeners();
      },
      onError: (_) {
        _carregandoOportunidades = false;
        _erroOportunidades = true;
        notifyListeners();
      },
    );
  }

  String? _generoSelecionadoMusicos;
  String? _cidadeFiltroMusicos;
  String _termoPesquisa = '';
  String _tipoOrdenacao = 'nome_asc';

  FiltroOportunidades _filtroOportunidades = const FiltroOportunidades();

  String? _errorMessage;

  List<Musico> get musicos => _musicos;
  List<Oportunidade> get oportunidades => _oportunidades;

  String? get generoSelecionadoMusicos => _generoSelecionadoMusicos;
  String? get cidadeFiltroMusicos => _cidadeFiltroMusicos;
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
    } catch (_) {
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
    } on FirebaseException catch (error) {
      _errorMessage = error.code == 'permission-denied'
          ? 'Sem permissão para $acao esta oportunidade.'
          : 'Não foi possível $acao a oportunidade.';
      notifyListeners();
      return false;
    }
  }

  void filtrarMusicos({String? genero, String? cidade}) {
    _generoSelecionadoMusicos = genero;
    _cidadeFiltroMusicos = cidade;
    _aplicarFiltrosAtuais();
    notifyListeners();
  }

  void resetarFiltroMusicos() {
    _generoSelecionadoMusicos = null;
    _cidadeFiltroMusicos = null;
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
      final genero = _generoSelecionadoMusicos;
      final cidade = _cidadeFiltroMusicos;

      final generoValido =
          genero == null || genero.isEmpty || m.generoMusical == genero;

      final cidadeValida =
          cidade == null ||
          cidade.isEmpty ||
          m.cidade.toLowerCase().contains(cidade.toLowerCase());

      final pesquisaValida =
          _termoPesquisa.isEmpty ||
          m.nomeArtistico.toLowerCase().contains(_termoPesquisa.toLowerCase()) ||
          m.descricao.toLowerCase().contains(_termoPesquisa.toLowerCase());

      return generoValido && cidadeValida && pesquisaValida;
    }).toList();

    _aplicarOrdenacao();

    // Lista pública: sem ocultas (exceto para o admin) e sem vencidas.
    _oportunidades = _filtroOportunidades.aplicar(
      _todasOportunidades.where((o) => !o.oculto || _isAdmin),
      hoje: DateTime.now(),
      bloqueados: _minhaAgenda.bloqueados,
      ocupados: _minhaAgenda.ocupados,
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
    super.dispose();
  }
}
