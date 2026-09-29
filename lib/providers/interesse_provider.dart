import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/interesse.dart';
import '../models/musico.dart';
import '../models/oportunidade.dart';
import '../services/firebase_data_service.dart';

/// Interesses enviados e recebidos pelo usuário logado: candidatura
/// (músico → oportunidade) e convite (dono → músico), com resposta do
/// destinatário. Aceitar abre uma conversa entre os dois.
class InteresseProvider extends ChangeNotifier {
  InteresseProvider({FirebaseDataService? service})
    : _service = service ?? FirebaseDataService() {
    if (_service.isEnabled) {
      _authSubscription = _service.authUserIds.listen(_escutar);
    }
  }

  final FirebaseDataService _service;
  StreamSubscription<String?>? _authSubscription;
  StreamSubscription<List<Interesse>>? _enviadosSubscription;
  StreamSubscription<List<Interesse>>? _recebidosSubscription;

  List<Interesse> _enviados = [];
  List<Interesse> _recebidos = [];
  String? _errorMessage;

  List<Interesse> get enviados => _maisRecentesPrimeiro(_enviados);
  List<Interesse> get recebidos => _maisRecentesPrimeiro(_recebidos);
  int get pendentesRecebidos => _recebidos.where((i) => i.pendente).length;
  String? get errorMessage => _errorMessage;

  void _escutar(String? uid) {
    _enviadosSubscription?.cancel();
    _recebidosSubscription?.cancel();
    _enviados = [];
    _recebidos = [];
    notifyListeners();
    if (uid == null) return;

    _enviadosSubscription = _service.streamInteressesEnviados(uid).listen((
      lista,
    ) {
      _enviados = lista;
      notifyListeners();
    });
    _recebidosSubscription = _service.streamInteressesRecebidos(uid).listen((
      lista,
    ) {
      _recebidos = lista;
      notifyListeners();
    });
  }

  /// Candidatura já enviada (em qualquer status) para a oportunidade.
  Interesse? candidaturaPara(String oportunidadeId) {
    for (final interesse in _enviados) {
      if (interesse.tipo == TipoInteresse.candidatura &&
          interesse.oportunidadeId == oportunidadeId) {
        return interesse;
      }
    }
    return null;
  }

  /// Convite mais recente já enviado ao músico (qualquer oportunidade).
  Interesse? convitePara(String musicoId) {
    for (final interesse in enviados) {
      if (interesse.tipo == TipoInteresse.convite &&
          interesse.musicoId == musicoId) {
        return interesse;
      }
    }
    return null;
  }

  Future<bool> enviarCandidatura({
    required Oportunidade oportunidade,
    required String remetenteId,
    required String remetenteNome,
    required String musicoNome,
  }) async {
    // Match: o dono já convidou este músico para a mesma oportunidade.
    final conviteRecebido = _pendenteRecebido(
      (i) =>
          i.tipo == TipoInteresse.convite &&
          i.oportunidadeId == oportunidade.id,
    );
    if (conviteRecebido != null) {
      final conversaId = await aceitar(
        conviteRecebido,
        nomeDestinatario: remetenteNome,
      );
      return conversaId != null;
    }

    return _enviar(
      Interesse(
        id: Interesse.idCandidatura(remetenteId, oportunidade.id),
        tipo: TipoInteresse.candidatura,
        remetenteId: remetenteId,
        remetenteNome: remetenteNome,
        destinatarioId: oportunidade.donoId,
        musicoId: remetenteId,
        musicoNome: musicoNome,
        oportunidadeId: oportunidade.id,
        oportunidadeTitulo: oportunidade.titulo,
        criadoEm: DateTime.now(),
      ),
    );
  }

  Future<bool> enviarConvite({
    required Musico musico,
    required String remetenteId,
    required String remetenteNome,
    Oportunidade? oportunidade,
  }) async {
    // Match: o músico já se candidatou a esta oportunidade.
    if (oportunidade != null) {
      final candidaturaRecebida = _pendenteRecebido(
        (i) =>
            i.tipo == TipoInteresse.candidatura &&
            i.oportunidadeId == oportunidade.id &&
            i.musicoId == musico.id,
      );
      if (candidaturaRecebida != null) {
        final conversaId = await aceitar(
          candidaturaRecebida,
          nomeDestinatario: remetenteNome,
        );
        return conversaId != null;
      }
    }

    return _enviar(
      Interesse(
        id: Interesse.idConvite(
          remetenteId,
          musico.id,
          oportunidadeId: oportunidade?.id,
        ),
        tipo: TipoInteresse.convite,
        remetenteId: remetenteId,
        remetenteNome: remetenteNome,
        destinatarioId: musico.id,
        musicoId: musico.id,
        musicoNome: musico.nomeArtistico,
        oportunidadeId: oportunidade?.id,
        oportunidadeTitulo: oportunidade?.titulo,
        criadoEm: DateTime.now(),
      ),
    );
  }

  /// Devolve o id da conversa aberta, ou `null` em caso de erro.
  Future<String?> aceitar(
    Interesse interesse, {
    required String nomeDestinatario,
  }) async {
    return _executar<String?>(
      firebase: () => _service.aceitarInteresse(
        interesse,
        nomeDestinatario: nomeDestinatario,
      ),
      mock: () {
        _substituirRecebido(
          interesse.copyWith(
            status: StatusInteresse.aceito,
            respondidoEm: DateTime.now(),
          ),
        );
        return interesse.id;
      },
    );
  }

  Future<bool> recusar(Interesse interesse) async {
    final ok = await _executar<bool>(
      firebase: () async {
        await _service.recusarInteresse(interesse.id);
        return true;
      },
      mock: () {
        _substituirRecebido(
          interesse.copyWith(
            status: StatusInteresse.recusado,
            respondidoEm: DateTime.now(),
          ),
        );
        return true;
      },
    );
    return ok ?? false;
  }

  Future<bool> cancelar(Interesse interesse) async {
    final ok = await _executar<bool>(
      firebase: () async {
        await _service.cancelarInteresse(interesse.id);
        return true;
      },
      mock: () {
        _enviados = _enviados.where((i) => i.id != interesse.id).toList();
        return true;
      },
    );
    return ok ?? false;
  }

  Future<bool> _enviar(Interesse interesse) async {
    final ok = await _executar<bool>(
      firebase: () async {
        await _service.enviarInteresse(interesse);
        return true;
      },
      mock: () {
        _enviados = [
          ..._enviados.where((i) => i.id != interesse.id),
          interesse,
        ];
        return true;
      },
    );
    return ok ?? false;
  }

  /// Com Firebase, os streams trazem o resultado de volta; no mock, [mock]
  /// altera as listas em memória.
  Future<T?> _executar<T>({
    required Future<T> Function() firebase,
    required T Function() mock,
  }) async {
    _errorMessage = null;
    try {
      if (_service.isEnabled) return await firebase();
      final resultado = mock();
      notifyListeners();
      return resultado;
    } on FirebaseException catch (error) {
      _errorMessage = _mensagemErro(error);
      notifyListeners();
      return null;
    }
  }

  Interesse? _pendenteRecebido(bool Function(Interesse) criterio) {
    for (final interesse in _recebidos) {
      if (interesse.pendente && criterio(interesse)) return interesse;
    }
    return null;
  }

  void _substituirRecebido(Interesse atualizado) {
    _recebidos = [
      for (final item in _recebidos) item.id == atualizado.id ? atualizado : item,
    ];
  }

  List<Interesse> _maisRecentesPrimeiro(List<Interesse> lista) {
    return [...lista]..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _enviadosSubscription?.cancel();
    _recebidosSubscription?.cancel();
    super.dispose();
  }
}

String _mensagemErro(FirebaseException error) {
  return switch (error.code) {
    'permission-denied' =>
      'Sem permissão para essa ação. Confira se seu perfil está completo.',
    'not-found' => 'Esse interesse não existe mais.',
    'unavailable' || 'deadline-exceeded' =>
      'O Firebase está indisponível. Tente novamente.',
    _ => 'Não foi possível concluir a ação.',
  };
}
