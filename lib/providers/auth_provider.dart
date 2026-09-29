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
      _carregarUsuario();
    }
  }

  final FirebaseDataService _service;

  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _userId;
  String? _userEmail;
  String? _errorMessage;
  Usuario? _usuario;
  bool _isAdmin = false;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get errorMessage => _errorMessage;
  Usuario? get usuario => _usuario;
  TipoUsuario? get tipoUsuario => _usuario?.tipoUsuario;

  /// Conta de testes com os dois papéis (custom claim `admin`).
  bool get isAdmin => _isAdmin;

  /// Pode agir como músico (se candidatar, ter perfil de artista).
  bool get atuaComoMusico => _isAdmin || tipoUsuario == TipoUsuario.musico;

  /// Pode agir como dono (criar oportunidades, convidar, ter estabelecimento).
  bool get atuaComoDono => _isAdmin || tipoUsuario == TipoUsuario.casaShow;

  /// Nome para exibir aos outros (ex.: em um interesse enviado).
  String get nomeExibicao {
    final nome = _usuario?.nome ?? '';
    return nome.isNotEmpty ? nome : (_userEmail ?? 'Usuário');
  }

  Future<void> _carregarUsuario() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      _usuario = await _service.carregarUsuario(uid);
      _isAdmin = await _service.ehAdmin();
      notifyListeners();
    } catch (_) {
      // Sem o documento, o app só esconde as ações que dependem do papel.
    }
  }

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

  /// Retorna `true` quando o onboarding está pendente: sem `tipoUsuario`, ou
  /// o perfil do tipo não existe / não está `completo`. Admin nunca passa
  /// pelo onboarding. No modo mock nunca bloqueia a navegação; um erro de
  /// leitura também não bloqueia (assume completo).
  Future<bool> precisaCompletarPerfil() async {
    if (!_service.isEnabled) return false;

    final uid = _userId;
    if (uid == null) return false;

    try {
      _usuario = await _service.carregarUsuario(uid);
      _isAdmin = await _service.ehAdmin();
      notifyListeners();
      if (_isAdmin) return false;

      return switch (_usuario?.tipoUsuario) {
        null => true,
        TipoUsuario.musico =>
          !((await _service.carregarPerfilMusico(uid))?.completo ?? false),
        TipoUsuario.casaShow =>
          !((await _service.carregarEstabelecimento(uid))?.completo ?? false),
      };
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
      _usuario = await _service.carregarUsuario(_userId!);
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
    _usuario = null;
    _isAdmin = false;
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
