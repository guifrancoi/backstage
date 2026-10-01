import 'dart:async';

import 'package:flutter/material.dart';

import '../models/agenda_publica.dart';
import '../services/firebase_data_service.dart';

/// Dias que o músico logado bloqueou na agenda (`bloqueios`). Todo dia é
/// livre por padrão; os dias com proposta ou show vêm das contratações
/// (`ContratacaoProvider`).
class AgendaProvider extends ChangeNotifier {
  AgendaProvider({FirebaseDataService? service})
    : _service = service ?? FirebaseDataService() {
    _authSubscription = _service.authUserIds.listen((_) => carregarBloqueios());
  }

  final FirebaseDataService _service;
  StreamSubscription<String?>? _authSubscription;

  final List<DateTime> _diasBloqueados = [];

  List<DateTime> get diasBloqueados => List.unmodifiable(_diasBloqueados);

  bool bloqueado(DateTime data) => _diasBloqueados.any((d) => _mesmoDia(d, data));

  /// Agenda de qualquer músico como os outros a veem (bloqueado/ocupado),
  /// em tempo real — detalhe do músico, convite e proposta de contratação.
  Stream<AgendaPublica> agendaPublica(String musicoId) =>
      _service.streamAgendaPublica(musicoId);

  Future<void> carregarBloqueios() async {
    final usuarioId = _service.currentUserId;
    _diasBloqueados.clear();
    if (usuarioId != null) {
      _diasBloqueados.addAll(await _service.listarDiasBloqueados(usuarioId));
    }
    notifyListeners();
  }

  Future<void> bloquearDia(DateTime data) async {
    final usuarioId = _service.currentUserId;
    if (usuarioId == null) return;

    final dia = DateTime(data.year, data.month, data.day);
    if (!bloqueado(dia)) {
      _diasBloqueados
        ..add(dia)
        ..sort();
      notifyListeners();
    }

    await _service.bloquearDia(usuarioId, dia);
  }

  Future<void> desbloquearDia(DateTime data) async {
    final usuarioId = _service.currentUserId;
    if (usuarioId == null) return;

    _diasBloqueados.removeWhere((d) => _mesmoDia(d, data));
    notifyListeners();

    await _service.desbloquearDia(usuarioId, data);
  }

  static bool _mesmoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
