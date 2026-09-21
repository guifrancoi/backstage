import 'dart:async';

import 'package:flutter/material.dart';

import '../services/firebase_data_service.dart';

class AgendaProvider extends ChangeNotifier {
  AgendaProvider({FirebaseDataService? service})
    : _service = service ?? FirebaseDataService() {
    if (_service.isEnabled) {
      _authSubscription = _service.authUserIds.listen((_) => carregarDatas());
    }
  }

  final FirebaseDataService _service;
  StreamSubscription<String?>? _authSubscription;

  final List<DateTime> _datasDisponiveis = [
    DateTime(2026, 3, 20),
    DateTime(2026, 3, 25),
    DateTime(2026, 3, 28),
  ];

  List<DateTime> get datasDisponiveis => List.unmodifiable(_datasDisponiveis);

  Future<void> carregarDatas() async {
    final usuarioId = _service.currentUserId;
    if (!_service.isEnabled || usuarioId == null) return;

    final datas = await _service.listarDatasDisponiveis(usuarioId);
    _datasDisponiveis
      ..clear()
      ..addAll(datas);
    notifyListeners();
  }

  Future<void> adicionarData(DateTime data) async {
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

    final usuarioId = _service.currentUserId;
    if (_service.isEnabled && usuarioId != null) {
      await _service.adicionarDataDisponivel(usuarioId, dataNormalizada);
    }
  }

  Future<void> removerData(DateTime data) async {
    _datasDisponiveis.removeWhere(
      (item) =>
          item.year == data.year &&
          item.month == data.month &&
          item.day == data.day,
    );
    notifyListeners();

    final usuarioId = _service.currentUserId;
    if (_service.isEnabled && usuarioId != null) {
      await _service.removerDataDisponivel(usuarioId, data);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
