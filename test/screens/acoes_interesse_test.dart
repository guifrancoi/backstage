import 'package:backstage/models/agenda_publica.dart';
import 'package:backstage/screens/busca/acoes_interesse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const agenda = AgendaPublica(
    ocupados: {'2099-03-01'},
    bloqueados: {'2099-03-02'},
  );

  test('avisoAgenda: ocupado, bloqueado ou nada (livre é o padrão)', () {
    expect(
      avisoAgenda(agenda, DateTime(2099, 3, 1, 21)),
      'O músico já tem um show confirmado nesse dia.',
    );
    expect(
      avisoAgenda(agenda, DateTime(2099, 3, 2)),
      'O músico bloqueou esse dia na agenda.',
    );
    expect(avisoAgenda(agenda, DateTime(2099, 3, 3)), isNull);
    expect(avisoAgenda(null, DateTime(2099, 3, 1)), isNull);
  });
}
