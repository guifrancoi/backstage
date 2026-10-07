import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/logging/app_logger.dart';
import '../models/usuario.dart';
import '../services/firebase_data_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({FirebaseDataService? service})
    : _service = service ?? FirebaseDataService() {
    if (_service.currentUserId != null) {
      _isLoggedIn = true;
      _userEmail = _service.currentUserEmail;
      _userId = _service.currentUserId;
      _carregarUsuario();
    }
  }

  final FirebaseDataService _service;

  bool _isLoading = false;
  bool _entrandoComGoogle = false;
  bool _isLoggedIn = false;
  String? _userId;
  String? _userEmail;
  String? _errorMessage;
  Usuario? _usuario;
  bool _isAdmin = false;

  bool get isLoading => _isLoading;

  /// Login com Google em andamento (Plano 23): o indicador fica no botão do
  /// Google, não no "Entrar".
  bool get entrandoComGoogle => _entrandoComGoogle;
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
    } catch (erro, stack) {
      // Sem o documento, o app só esconde as ações que dependem do papel.
      AppLogger.falha(_origem, 'Falha ao carregar o usuário', erro, stack);
    }
  }

  Future<bool> login({required String email, required String senha}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _service.login(email: email, senha: senha);
      _userId = credential.user?.uid;
      _userEmail = credential.user?.email;
      _isLoggedIn = true;
      AppLogger.info(_origem, 'Login');
      return true;
    } on FirebaseAuthException catch (error, stack) {
      AppLogger.falha(_origem, 'Falha no login', error, stack);
      _errorMessage = _mensagemFirebaseAuth(error);
      return false;
    } on FirebaseException catch (error, stack) {
      AppLogger.falha(_origem, 'Falha no login', error, stack);
      _errorMessage = _mensagemFirebase(error);
      return false;
    } on TimeoutException catch (error, stack) {
      AppLogger.falha(_origem, 'Falha no login', error, stack);
      _errorMessage =
          'O Firebase demorou para responder. Verifique a conexão e tente novamente.';
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
    } on FirebaseAuthException catch (error, stack) {
      AppLogger.falha(_origem, 'Falha no cadastro', error, stack);
      _errorMessage = _mensagemFirebaseAuth(error);
      return false;
    } on FirebaseException catch (error, stack) {
      AppLogger.falha(_origem, 'Falha no cadastro', error, stack);
      _errorMessage = _mensagemFirebase(error);
      return false;
    } on TimeoutException catch (error, stack) {
      AppLogger.falha(_origem, 'Falha no cadastro', error, stack);
      _errorMessage =
          'O Firebase demorou para responder. Verifique a conexão e tente novamente.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Plano 23: "Continuar com Google". `true` = entrou (a tela confere o
  /// onboarding como no login). `false` com `errorMessage` nulo = a pessoa
  /// fechou a escolha de conta (não é erro, a tela não avisa nada).
  Future<bool> entrarComGoogle() async {
    _entrandoComGoogle = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _service.entrarComGoogle();
      if (credential == null) return false;
      _userId = credential.user?.uid;
      _userEmail = credential.user?.email;
      _isLoggedIn = true;
      AppLogger.info(_origem, 'Login com Google');
      return true;
    } on FirebaseAuthException catch (error, stack) {
      // Fechar a janela do Google no navegador também chega como erro.
      if (_desistiuNoNavegador.contains(error.code)) return false;
      AppLogger.falha(_origem, 'Falha no login com Google', error, stack);
      _errorMessage = _mensagemFirebaseAuth(error);
      return false;
    } on GoogleSignInException catch (error, stack) {
      AppLogger.falha(_origem, 'Falha no login com Google', error, stack);
      _errorMessage = 'Não foi possível entrar com o Google. Tente novamente.';
      return false;
    } on FirebaseException catch (error, stack) {
      AppLogger.falha(_origem, 'Falha no login com Google', error, stack);
      _errorMessage = _mensagemFirebase(error);
      return false;
    } on TimeoutException catch (error, stack) {
      AppLogger.falha(_origem, 'Falha no login com Google', error, stack);
      _errorMessage =
          'O Firebase demorou para responder. Verifique a conexão e tente novamente.';
      return false;
    } finally {
      _entrandoComGoogle = false;
      notifyListeners();
    }
  }

  Future<bool> recuperarSenha(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.recuperarSenha(email);
      return true;
    } on FirebaseAuthException catch (error, stack) {
      AppLogger.falha(_origem, 'Falha ao recuperar a senha', error, stack);
      _errorMessage = _mensagemFirebaseAuth(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retorna `true` quando o onboarding está pendente: sem `tipoUsuario`, ou
  /// o perfil do tipo não existe / não está `completo`. Admin nunca passa
  /// pelo onboarding. Um erro de leitura não bloqueia (assume completo).
  Future<bool> precisaCompletarPerfil() async {
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
    } catch (erro, stack) {
      AppLogger.falha(_origem, 'Falha ao conferir o onboarding', erro, stack);
      return false;
    }
  }

  /// Conta sem telefone (criada pelo Google, Plano 23) precisa informá-lo.
  bool get precisaTelefone =>
      !_isAdmin && (_usuario?.telefone.trim().isEmpty ?? false);

  Future<bool> completarCadastro(
    TipoUsuario tipoUsuario, {
    String? telefone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.definirTipoUsuario(
        _userId!,
        tipoUsuario,
        telefone: telefone,
      );
      _usuario = await _service.carregarUsuario(_userId!);
      return true;
    } on FirebaseException catch (error, stack) {
      AppLogger.falha(
        _origem,
        'Falha ao definir o tipo de usuário',
        error,
        stack,
      );
      _errorMessage = _mensagemFirebase(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _service.logout();
    AppLogger.info(_origem, 'Logout');

    _isLoggedIn = false;
    _userId = null;
    _userEmail = null;
    _usuario = null;
    _isAdmin = false;
    _errorMessage = null;
    notifyListeners();
  }
}

const _origem = 'AuthProvider';

/// Códigos de quem fechou a janela do Google no navegador.
const _desistiuNoNavegador = {
  'popup-closed-by-user',
  'cancelled-popup-request',
};

String _mensagemFirebaseAuth(FirebaseAuthException error) {
  return switch (error.code) {
    'invalid-email' => 'E-mail inválido.',
    'user-disabled' => 'Usuário desativado.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'E-mail ou senha inválidos.',
    'email-already-in-use' => 'Este e-mail já está cadastrado.',
    'weak-password' => 'A senha deve ser mais forte.',
    'account-exists-with-different-credential' =>
      'Este e-mail já está cadastrado com outra forma de login.',
    _ => 'Não foi possível concluir a autenticação.',
  };
}

String _mensagemFirebase(FirebaseException error) {
  return switch (error.code) {
    'permission-denied' => 'Sem permissão para salvar os dados do cadastro.',
    'unavailable' ||
    'deadline-exceeded' => 'O Firebase está indisponível. Tente novamente.',
    _ => 'Não foi possível salvar os dados do cadastro.',
  };
}
