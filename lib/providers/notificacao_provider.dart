import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/logging/app_logger.dart';
import '../models/notificacao.dart';
import '../services/firebase_data_service.dart';

/// Notificações recebidas pelo usuário logado (sino da Home). Quem as cria
/// são os outros providers, depois de cada ação (`FirebaseDataService.notificar`).
class NotificacaoProvider extends ChangeNotifier {
  NotificacaoProvider({FirebaseDataService? service})
    : _service = service ?? FirebaseDataService() {
    _authSubscription = _service.authUserIds.listen(_escutar);
  }

  final FirebaseDataService _service;
  StreamSubscription<String?>? _authSubscription;
  StreamSubscription<List<Notificacao>>? _notificacoesSubscription;

  List<Notificacao> _notificacoes = [];
  String? _errorMessage;

  /// Mais recentes primeiro.
  List<Notificacao> get notificacoes => _notificacoes;
  int get naoLidas => _notificacoes.where((n) => !n.lida).length;
  String? get errorMessage => _errorMessage;

  void _escutar(String? uid) {
    _notificacoesSubscription?.cancel();
    _notificacoes = [];
    notifyListeners();
    if (uid == null) return;

    _notificacoesSubscription = _service.streamNotificacoes(uid).listen((
      lista,
    ) {
      _notificacoes = [...lista]
        ..sort((a, b) => b.criadaEm.compareTo(a.criadaEm));
      notifyListeners();
    }, onError: AppLogger.aoFalhar(_origem, 'Falha nas notificações'));
  }

  Future<bool> marcarComoLida(Notificacao notificacao) {
    if (notificacao.lida) return Future.value(true);
    return _executar(() => _service.marcarNotificacoesLidas([notificacao.id]));
  }

  Future<bool> marcarTodasComoLidas() {
    final ids = [
      for (final n in _notificacoes)
        if (!n.lida) n.id,
    ];
    if (ids.isEmpty) return Future.value(true);
    return _executar(() => _service.marcarNotificacoesLidas(ids));
  }

  Future<bool> remover(Notificacao notificacao) =>
      _executar(() => _service.removerNotificacao(notificacao.id));

  /// Grava no Firestore; o stream traz o resultado de volta.
  Future<bool> _executar(Future<void> Function() acao) async {
    _errorMessage = null;
    try {
      await acao();
      return true;
    } on FirebaseException catch (erro, stack) {
      AppLogger.falha(_origem, 'Falha ao atualizar notificação', erro, stack);
      _errorMessage = 'Não foi possível atualizar as notificações.';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _notificacoesSubscription?.cancel();
    super.dispose();
  }
}

const _origem = 'NotificacaoProvider';
