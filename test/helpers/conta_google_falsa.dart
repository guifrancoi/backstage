import 'package:backstage/services/conta_google.dart';

/// Plano 23: "Continuar com Google" sem conta Google de verdade — o
/// [ContaGoogleFalsa] faz o papel da escolha de conta.
class ContaGoogleFalsa implements ContaGoogle {
  ContaGoogleFalsa({this.token = 'token-google', this.erro});

  /// `null` = a pessoa fechou a escolha de conta.
  final String? token;
  final Object? erro;
  int saidas = 0;

  @override
  Future<String?> idToken() async {
    if (erro case final erro?) throw erro;
    return token;
  }

  @override
  Future<void> sair() async => saidas++;
}
