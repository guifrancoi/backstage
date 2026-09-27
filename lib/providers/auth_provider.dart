import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/usuario.dart';
import '../services/firebase_data_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({FirebaseDataService? service})
    : _service = service ?? FirebaseDataService() {
    if (_service.isEnabled && _service.currentUserId != null) {
      _isLoggedIn = true;
      _userEmail = _service.currentUserEmail;
      _userId = _service.currentUserId;
    }
  }

  final FirebaseDataService _service;

  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _userId;
  String? _userEmail;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get errorMessage => _errorMessage;

  Future<bool> login({required String email, required String senha}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (!_service.isEnabled) {
      await Future.delayed(const Duration(seconds: 1));

      _isLoading = false;

      _errorMessage = 'Falha na conexão dos nosso serviços. Por favor, tente novamente mais tarde.';
      notifyListeners();
      return false;
    }

    try {
      final credential = await _service.login(email: email, senha: senha);
      _userId = credential.user?.uid;
      _userEmail = credential.user?.email;
      _isLoggedIn = true;
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _mensagemFirebaseAuth(error);
      return false;
    } on FirebaseException catch (error) {
      _errorMessage = _mensagemFirebase(error);
      return false;
    } on TimeoutException {
      _errorMessage =
          'O Firebase demorou para responder. Verifique a conexao e tente novamente.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cadastrar({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (!_service.isEnabled) {
      await Future.delayed(const Duration(seconds: 1));

      _isLoading = false;
      _isLoggedIn = true;
      _userId = 'mock-user';
      _userEmail = email;
      notifyListeners();

      return true;
    }

    try {
      final credential = await _service.cadastrar(
        nome: nome,
        email: email,
        telefone: telefone,
        senha: senha,
      );
      _isLoggedIn = true;
      _userId = credential.user?.uid;
      _userEmail = credential.user?.email;
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _mensagemFirebaseAuth(error);
      return false;
    } on FirebaseException catch (error) {
      _errorMessage = _mensagemFirebase(error);
      return false;
    } on TimeoutException {
      _errorMessage =
          'O Firebase demorou para responder. Verifique a conexao e tente novamente.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> recuperarSenha(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (!_service.isEnabled) {
      await Future.delayed(const Duration(seconds: 1));

      _isLoading = false;
      notifyListeners();
      return true;
    }

    try {
      await _service.recuperarSenha(email);
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _mensagemFirebaseAuth(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retorna `true` quando o usuário logado ainda não escolheu um
  /// `tipoUsuario` (onboarding pendente). No modo mock nunca bloqueia a
  /// navegação; um erro de leitura também não bloqueia (assume completo).
  Future<bool> precisaCompletarPerfil() async {
    if (!_service.isEnabled) return false;

    final uid = _userId;
    if (uid == null) return false;

    try {
      final usuario = await _service.carregarUsuario(uid);
      return usuario?.tipoUsuario == null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> completarCadastro(TipoUsuario tipoUsuario) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.definirTipoUsuario(_userId!, tipoUsuario);
      return true;
    } on FirebaseException catch (error) {
      _errorMessage = _mensagemFirebase(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (_service.isEnabled) {
      await _service.logout();
    }

    _isLoggedIn = false;
    _userId = null;
    _userEmail = null;
    _errorMessage = null;
    notifyListeners();
  }
}

String _mensagemFirebaseAuth(FirebaseAuthException error) {
  return switch (error.code) {
    'invalid-email' => 'E-mail invalido.',
    'user-disabled' => 'Usuario desativado.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'E-mail ou senha invalidos.',
    'email-already-in-use' => 'Este e-mail ja esta cadastrado.',
    'weak-password' => 'A senha deve ser mais forte.',
    _ => 'Nao foi possivel concluir a autenticacao.',
  };
}

String _mensagemFirebase(FirebaseException error) {
  return switch (error.code) {
    'permission-denied' => 'Sem permissao para salvar os dados do cadastro.',
    'unavailable' || 'deadline-exceeded' =>
      'O Firebase esta indisponivel. Tente novamente.',
    _ => 'Nao foi possivel salvar os dados do cadastro.',
  };
}
