import 'package:backstage/core/logging/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

/// Destino que guarda os registros do [AppLogger] para o teste conferir.
class CapturaLog extends DestinoLog {
  final List<RegistroLog> registros = [];
  final List<String?> usuarios = [];

  @override
  void registrar(RegistroLog registro) => registros.add(registro);

  @override
  void definirUsuario(String? uid) => usuarios.add(uid);

  /// Registros de [origem] (ex.: `AuthProvider`).
  List<RegistroLog> de(String origem) =>
      registros.where((r) => r.origem == origem).toList();
}

/// Troca os destinos do [AppLogger] por uma captura até o fim do teste.
/// Chamar dentro do teste (ou do `setUp`).
CapturaLog capturarLogs() {
  final captura = CapturaLog();
  AppLogger.configurar([captura]);
  addTearDown(AppLogger.restaurarPadrao);
  return captura;
}
