import 'dart:async';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/conversa.dart';
import '../models/mensagem.dart';
import '../services/firebase_data_service.dart';

/// Conversas do usuário logado. Uma conversa nasce quando um interesse é
/// aceito (`InteresseProvider.aceitar`); aqui só se lê e se envia mensagem.
class ChatProvider extends ChangeNotifier {
  ChatProvider({FirebaseDataService? service})
    : _service = service ?? FirebaseDataService() {
    if (_service.isEnabled) {
      _conversas = [];
      _authSubscription = _service.authUserIds.listen(_escutar);
    }
  }

  final FirebaseDataService _service;
  StreamSubscription<String?>? _authSubscription;
  StreamSubscription<List<Conversa>>? _conversasSubscription;

  List<Conversa> _conversas = [...MockData.conversas];
  String? _uid;

  /// Mais recentes primeiro.
  List<Conversa> get conversas {
    final lista = [..._conversas];
    lista.sort((a, b) {
      final dataA = a.atualizadoEm ?? DateTime(0);
      final dataB = b.atualizadoEm ?? DateTime(0);
      return dataB.compareTo(dataA);
    });
    return lista;
  }

  String? get meuUid => _service.isEnabled ? _uid : MockData.usuarioMockId;

  void _escutar(String? uid) {
    _conversasSubscription?.cancel();
    _uid = uid;
    _conversas = [];
    notifyListeners();
    if (uid == null) return;

    _conversasSubscription = _service.streamConversas(uid).listen((lista) {
      _conversas = lista;
      notifyListeners();
    });
  }

  Conversa? buscarConversaPorId(String id) {
    for (final conversa in _conversas) {
      if (conversa.id == id) return conversa;
    }
    return null;
  }

  Future<void> enviarMensagem(String conversaId, String texto) async {
    final remetenteId = meuUid;
    final conversa = buscarConversaPorId(conversaId);
    if (conversa == null || remetenteId == null) return;

    final mensagem = Mensagem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      remetenteId: remetenteId,
      texto: texto,
      dataHora: DateTime.now(),
    );

    if (_service.isEnabled) {
      // O stream traz a mensagem de volta; não duplica localmente.
      await _service.enviarMensagem(conversaId, mensagem);
      return;
    }

    _conversas = [
      for (final item in _conversas)
        item.id == conversaId
            ? item.copyWith(
                mensagens: [...item.mensagens, mensagem],
                atualizadoEm: mensagem.dataHora,
              )
            : item,
    ];
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _conversasSubscription?.cancel();
    super.dispose();
  }
}
