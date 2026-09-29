import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/mock_data.dart';
import '../models/casa_show.dart';
import '../models/musico.dart';
import '../models/usuario.dart';
import '../services/firebase_data_service.dart';

/// Perfis do usuário logado: de artista (`perfis_musicos`) e/ou de
/// estabelecimento (`estabelecimentos`), conforme o papel. Admin tem os dois.
///
/// Nenhum perfil é criado automaticamente: ele só é gravado quando o usuário
/// salva o formulário (onboarding ou tela de Perfil), para a busca só mostrar
/// perfis preenchidos.
class PerfilProvider extends ChangeNotifier {
  PerfilProvider({FirebaseDataService? service})
    : _service = service ?? FirebaseDataService() {
    if (_service.isEnabled) {
      _authSubscription = _service.authUserIds.listen(_aoTrocarUsuario);
    }
  }

  final FirebaseDataService _service;
  StreamSubscription<String?>? _authSubscription;

  Musico? _perfilMusico;
  CasaShow? _perfilEstabelecimento;
  bool _isLoading = false;
  bool _isAdmin = false;
  String? _errorMessage;

  Musico? get perfilMusico => _perfilMusico;
  CasaShow? get perfilEstabelecimento => _perfilEstabelecimento;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> carregarPerfilMock() => carregarPerfil();

  /// Ao trocar de conta, descarta os perfis anteriores na hora: senão uma
  /// ação feita antes do novo carregamento usaria o perfil de outra pessoa.
  void _aoTrocarUsuario(String? uid) {
    _perfilMusico = null;
    _perfilEstabelecimento = null;
    _isAdmin = false;
    notifyListeners();
    if (uid != null) carregarPerfil();
  }

  String? get _uid =>
      _service.isEnabled ? _service.currentUserId : MockData.usuarioMockId;

  Future<void> carregarPerfil() async {
    final uid = _uid;
    if (uid == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      if (!_service.isEnabled) {
        _perfilMusico ??= _perfilMock(uid);
        return;
      }

      final usuario = await _service.carregarUsuario(uid);
      _isAdmin = await _service.ehAdmin();
      final tipo = usuario?.tipoUsuario;

      _perfilMusico = (_isAdmin || tipo == TipoUsuario.musico)
          ? await _service.carregarPerfilMusico(uid)
          : null;
      _perfilEstabelecimento = (_isAdmin || tipo == TipoUsuario.casaShow)
          ? await _service.carregarEstabelecimento(uid)
          : null;
    } catch (_) {
      // Falha de rede/permissão: a tela mostra o perfil como ausente.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Grava o perfil de artista do usuário logado (id = uid). O que a conta
  /// admin grava sai `oculto`, fora das listas dos outros usuários.
  Future<bool> salvarPerfilMusico(Musico perfil) async {
    final uid = _uid;
    if (uid == null) return false;

    final salvo = perfil.copyWith(id: uid, oculto: _isAdmin);
    return _salvar(() async {
      if (_service.isEnabled) await _service.salvarPerfilMusico(uid, salvo);
      _perfilMusico = salvo;
    });
  }

  Future<bool> salvarPerfilEstabelecimento(CasaShow perfil) async {
    final uid = _uid;
    if (uid == null) return false;

    final salvo = perfil.copyWith(id: uid, oculto: _isAdmin);
    return _salvar(() async {
      if (_service.isEnabled) await _service.salvarEstabelecimento(uid, salvo);
      _perfilEstabelecimento = salvo;
    });
  }

  Future<bool> _salvar(Future<void> Function() gravar) async {
    _errorMessage = null;
    try {
      await gravar();
      return true;
    } on FirebaseException catch (error) {
      _errorMessage = error.code == 'permission-denied'
          ? 'Sem permissão para salvar o perfil.'
          : 'Não foi possível salvar o perfil. Tente novamente.';
      return false;
    } finally {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// Só para o modo mock (sem Firebase).
Musico _perfilMock(String usuarioId) {
  return Musico(
    id: usuarioId,
    nomeArtistico: 'Artista',
    generoMusical: '',
    cidade: '',
    descricao: '',
    cacheMedio: 0,
    portfolioLinks: const [],
    datasDisponiveis: const [],
  );
}
