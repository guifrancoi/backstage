import 'package:google_sign_in/google_sign_in.dart';

/// Plano 23: o pedaço nativo do "Continuar com Google" (Android/iOS). Só
/// abre a escolha de conta e devolve o `idToken`; quem troca o token por
/// uma sessão no Firebase é o `FirebaseDataService`. Nos testes entra um
/// falso no lugar (não há conta Google lá).
abstract class ContaGoogle {
  /// `idToken` da conta escolhida, ou `null` se a pessoa desistiu.
  Future<String?> idToken();

  /// Esquece a conta escolhida (senão o próximo login entra direto nela).
  Future<void> sair();
}

class ContaGoogleNativa implements ContaGoogle {
  /// `initialize` só pode rodar uma vez por app (a instância é única). O
  /// client ID do servidor vem do `google-services.json`/`Info.plist`.
  static Future<void>? _inicializacao;

  Future<void> _iniciar() =>
      _inicializacao ??= GoogleSignIn.instance.initialize();

  @override
  Future<String?> idToken() async {
    await _iniciar();
    try {
      final conta = await GoogleSignIn.instance.authenticate();
      return conta.authentication.idToken;
    } on GoogleSignInException catch (erro) {
      // Fechar a escolha de conta não é erro.
      if (erro.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  @override
  Future<void> sair() async {
    await _iniciar();
    await GoogleSignIn.instance.signOut();
  }
}
