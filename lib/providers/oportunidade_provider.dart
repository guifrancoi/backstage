import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/mock_data.dart';
import '../models/musico.dart';
import '../models/oportunidade.dart';
import '../services/firebase_data_service.dart';

/// Catálogo de músicos e oportunidades (busca, filtros, ordenação) e as
/// oportunidades criadas pelo dono logado. Interesses ficam no
/// `InteresseProvider`.
class OportunidadeProvider extends ChangeNotifier {
  OportunidadeProvider({FirebaseDataService? service})
    : _service = service ?? FirebaseDataService() {
    if (_service.isEnabled) {
      // Com Firebase nunca mostrar o catálogo de demonstração do MockData:
      // começa vazio e é preenchido pelo Firestore.
      _todosMusicos = [];
      _todasOportunidades = [];
      _aplicarFiltrosAtuais();
      _authSubscription = _service.authUserIds.listen(_escutar);
    }
  }

  final FirebaseDataService _service;
  StreamSubscription<String?>? _authSubscription;
  StreamSubscription<List<Musico>>? _musicosSubscription;
  StreamSubscription<List<Oportunidade>>? _oportunidadesSubscription;

  List<Musico> _todosMusicos = [...MockData.musicos];
  List<Oportunidade> _todasOportunidades = [...MockData.oportunidades];
  List<Musico> _musicos = [...MockData.musicos];
  List<Oportunidade> _oportunidades = [...MockData.oportunidades];

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
    _musicosSubscription = null;
    _oportunidadesSubscription = null;
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
    _service.seedDadosIniciais().catchError((_) {});
  }

  String? _generoSelecionadoMusicos;
  String? _cidadeFiltroMusicos;
  String _termoPesquisa = '';
  String _tipoOrdenacao = 'nome_asc';

  String? _generoFiltroOportunidades;
  String? _cidadeFiltroOportunidades;

  String? _errorMessage;

  List<Musico> get musicos => _musicos;
  List<Oportunidade> get oportunidades => _oportunidades;

  String? get generoSelecionadoMusicos => _generoSelecionadoMusicos;
  String? get cidadeFiltroMusicos => _cidadeFiltroMusicos;
  String get termoPesquisa => _termoPesquisa;
  String get tipoOrdenacao => _tipoOrdenacao;
  String? get errorMessage => _errorMessage;

  /// Oportunidades do dono [donoId], da mais próxima para a mais distante.
  List<Oportunidade> minhasOportunidades(String? donoId) {
    if (donoId == null) return [];
    return _todasOportunidades.where((o) => o.donoId == donoId).toList()
      ..sort((a, b) => a.dataEvento.compareTo(b.dataEvento));
  }

  /// Grava a oportunidade com `donoId` = [donoId]. Com Firebase, o stream traz
  /// o documento de volta; no mock, entra direto na lista. O que a conta admin
  /// cria sai `oculto`.
  Future<bool> criarOportunidade(Oportunidade oportunidade, String donoId) async {
    final comDono = oportunidade.copyWith(donoId: donoId, oculto: _isAdmin);
    _errorMessage = null;

    if (!_service.isEnabled) {
      _todasOportunidades = [
        ..._todasOportunidades,
        comDono.copyWith(id: 'mock-${DateTime.now().millisecondsSinceEpoch}'),
      ];
      _aplicarFiltrosAtuais();
      notifyListeners();
      return true;
    }

    try {
      await _service.criarOportunidade(comDono);
      return true;
    } on FirebaseException catch (error) {
      _errorMessage = error.code == 'permission-denied'
          ? 'Sem permissão para criar oportunidade.'
          : 'Não foi possível salvar a oportunidade.';
      notifyListeners();
      return false;
    }
  }

  /// Edita uma oportunidade existente (dono ou admin, pelas regras). Mantém
  /// `donoId` e `oculto` originais.
  Future<bool> atualizarOportunidade(Oportunidade oportunidade) async {
    final original = buscarOportunidadePorId(oportunidade.id);
    final editada = oportunidade.copyWith(
      donoId: original?.donoId,
      oculto: original?.oculto,
    );
    return _alterar(
      firebase: () => _service.atualizarOportunidade(editada),
      mock: () => [
        for (final o in _todasOportunidades) o.id == editada.id ? editada : o,
      ],
      acao: 'editar',
    );
  }

  Future<bool> removerOportunidade(String oportunidadeId) {
    return _alterar(
      firebase: () => _service.removerOportunidade(oportunidadeId),
      mock: () =>
          _todasOportunidades.where((o) => o.id != oportunidadeId).toList(),
      acao: 'remover',
    );
  }

  Future<bool> _alterar({
    required Future<void> Function() firebase,
    required List<Oportunidade> Function() mock,
    required String acao,
  }) async {
    _errorMessage = null;

    if (!_service.isEnabled) {
      _todasOportunidades = mock();
      _aplicarFiltrosAtuais();
      notifyListeners();
      return true;
    }

    try {
      await firebase();
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

  void filtrarOportunidades({String? genero, String? cidade}) {
    _generoFiltroOportunidades = genero;
    _cidadeFiltroOportunidades = cidade;
    _aplicarFiltrosAtuais();
    notifyListeners();
  }

  void resetarFiltroOportunidades() {
    _generoFiltroOportunidades = null;
    _cidadeFiltroOportunidades = null;
    _aplicarFiltrosAtuais();
    notifyListeners();
  }

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

    _oportunidades = _todasOportunidades.where((o) {
      if (o.oculto && !_isAdmin) return false;
      final genero = _generoFiltroOportunidades;
      final cidade = _cidadeFiltroOportunidades;

      final generoValido =
          genero == null || genero.isEmpty || o.generoMusical == genero;

      final cidadeValida =
          cidade == null ||
          cidade.isEmpty ||
          o.cidade.toLowerCase().contains(cidade.toLowerCase());

      return generoValido && cidadeValida;
    }).toList();
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
    super.dispose();
  }
}
