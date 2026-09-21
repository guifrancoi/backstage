import 'dart:async';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/conversa.dart';
import '../models/mensagem.dart';
import '../services/firebase_data_service.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({FirebaseDataService? service})
    : _service = service ?? FirebaseDataService() {
    if (_service.isEnabled) {
      _authSubscription = _service.authUserIds.listen(
        (_) => carregarConversas(),
      );
      carregarConversas();
    }
  }

  final FirebaseDataService _service;
  StreamSubscription<String?>? _authSubscription;

  List<Conversa> _conversas = [...MockData.conversas];

  List<Conversa> get conversas => _conversas;

  Future<void> carregarConversas() async {
    if (!_service.isEnabled) return;

    await _service.seedDadosIniciais();
    _conversas = await _service.listarConversas();
    notifyListeners();
  }

  Conversa? buscarConversaPorId(String id) {
    try {
      return _conversas.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> enviarMensagem(String conversaId, String texto) async {
    final index = _conversas.indexWhere((c) => c.id == conversaId);
    if (index == -1) return;

    final mensagem = Mensagem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      remetenteId: _service.currentUserId ?? 'me',
      texto: texto,
      dataHora: DateTime.now(),
      enviadaPorMim: true,
    );

    _conversas[index].mensagens.add(mensagem);
    notifyListeners();

    if (_service.isEnabled) {
      await _service.salvarConversa(_conversas[index]);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
