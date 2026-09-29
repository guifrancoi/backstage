import 'dart:async';

import 'package:flutter/material.dart';

import '../models/agenda_publica.dart';
import '../services/firebase_data_service.dart';

/// Datas disponíveis do músico logado (`disponibilidades`). Os dias
/// ocupados vêm das contratações (`ContratacaoProvider`).
class AgendaProvider extends ChangeNotifier {
  AgendaProvider({FirebaseDataService? service})
    : _service = service ?? FirebaseDataService() {
    _authSubscription = _service.authUserIds.listen((_) => carregarDatas());
  }

  final FirebaseDataService _service;
  StreamSubscription<String?>? _authSubscription;

  final List<DateTime> _datasDisponiveis = [];

  List<DateTime> get datasDisponiveis => List.unmodifiable(_datasDisponiveis);

  /// Agenda de qualquer músico como os outros a veem (disponível/ocupado),
  /// em tempo real — detalhe do músico, convite e proposta de contratação.
  Stream<AgendaPublica> agendaPublica(String musicoId) =>
      _service.streamAgendaPublica(musicoId);

  Future<void> carregarDatas() async {
    final usuarioId = _service.currentUserId;
    _datasDisponiveis.clear();
    if (usuarioId != null) {
      _datasDisponiveis.addAll(
        await _service.listarDatasDisponiveis(usuarioId),
      );
    }
    notifyListeners();
  }

  Future<void> adicionarData(DateTime data) async {
    final usuarioId = _service.currentUserId;
    if (usuarioId == null) return;

    final dataNormalizada = DateTime(data.year, data.month, data.day);

    final jaExiste = _datasDisponiveis.any(
      (item) =>
          item.year == dataNormalizada.year &&
          item.month == dataNormalizada.month &&
          item.day == dataNormalizada.day,
    );

    if (!jaExiste) {
      _datasDisponiveis.add(dataNormalizada);
      _datasDisponiveis.sort();
      notifyListeners();
    }

    await _service.adicionarDataDisponivel(usuarioId, dataNormalizada);
  }

  Future<void> removerData(DateTime data) async {
    final usuarioId = _service.currentUserId;
    if (usuarioId == null) return;

    _datasDisponiveis.removeWhere(
      (item) =>
          item.year == data.year &&
          item.month == data.month &&
          item.day == data.day,
    );
    notifyListeners();

    await _service.removerDataDisponivel(usuarioId, data);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
