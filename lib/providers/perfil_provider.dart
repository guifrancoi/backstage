import 'dart:async';

import 'package:flutter/material.dart';

import '../models/musico.dart';
import '../services/firebase_data_service.dart';

class PerfilProvider extends ChangeNotifier {
  PerfilProvider({FirebaseDataService? service})
    : _service = service ?? FirebaseDataService() {
    if (_service.isEnabled) {
      _authSubscription = _service.authUserIds.listen((_) => carregarPerfil());
    }
  }

  final FirebaseDataService _service;
  StreamSubscription<String?>? _authSubscription;

  Musico? _perfilMusico;
  bool _isLoading = false;

  Musico? get perfilMusico => _perfilMusico;
  bool get isLoading => _isLoading;

  Future<void> carregarPerfilMock() => carregarPerfil();

  Future<void> carregarPerfil() async {
    final usuarioId = _service.currentUserId ?? 'mock-user';

    _isLoading = true;
    notifyListeners();

    if (_service.isEnabled) {
      final perfilFirebase = await _service.carregarPerfilMusico(usuarioId);
      if (perfilFirebase != null) {
        _perfilMusico = perfilFirebase;
        _isLoading = false;
        notifyListeners();
        return;
      }
    }

    _perfilMusico = _perfilInicial(usuarioId);

    if (_service.isEnabled) {
      await _service.salvarPerfilMusico(usuarioId, _perfilMusico!);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> atualizarPerfil({
    required String nomeArtistico,
    required String generoMusical,
    required String cidade,
    required double cacheMedio,
    required String descricao,
    required List<String> portfolioLinks,
    String? fotoPath,
  }) async {
    final perfilAtual = _perfilMusico;
    if (perfilAtual == null) return;

    _perfilMusico = perfilAtual.copyWith(
      nomeArtistico: nomeArtistico,
      generoMusical: generoMusical,
      cidade: cidade,
      cacheMedio: cacheMedio,
      descricao: descricao,
      portfolioLinks: portfolioLinks,
      fotoPath: fotoPath,
    );

    notifyListeners();

    if (_service.isEnabled) {
      await _service.salvarPerfilMusico(_perfilMusico!.id, _perfilMusico!);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

Musico _perfilInicial(String usuarioId) {
  return Musico(
    id: usuarioId,
    nomeArtistico: 'The VooDooS',
    generoMusical: 'Metal',
    cidade: 'Ribeirao Preto',
    descricao: 'Banda com repertorio nacional e internacional.',
    cacheMedio: 1200,
    portfolioLinks: [
      'https://www.youtube.com/@thevoodoosoficial',
      'https://www.instagram.com/voodoos.ofc/',
    ],
    datasDisponiveis: ['2026-03-20', '2026-03-25'],
    fotoPath: null,
  );
}
