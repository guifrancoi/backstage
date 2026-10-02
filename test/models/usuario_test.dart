import 'package:backstage/models/usuario.dart';
import 'package:flutter_test/flutter_test.dart';

Usuario _usuario() => Usuario(
  id: 'u1',
  nome: 'Guilherme',
  email: 'teste@email.com',
  telefone: '16998765432',
  tipoUsuario: TipoUsuario.musico,
);

void main() {
  group('Usuario', () {
    test('toMap e fromMap preservam todos os campos (id fora do mapa)', () {
      final original = _usuario();

      final map = original.toMap();
      final copia = Usuario.fromMap('u1', map);

      expect(map.containsKey('id'), isFalse);
      expect(copia.id, 'u1');
      expect(copia.nome, original.nome);
      expect(copia.email, original.email);
      expect(copia.telefone, original.telefone);
      expect(copia.tipoUsuario, TipoUsuario.musico);
    });

    test('fromMap aplica valores padrão para campos ausentes', () {
      final usuario = Usuario.fromMap('x', {});

      expect(usuario.nome, '');
      expect(usuario.email, '');
      expect(usuario.telefone, '');
      expect(usuario.tipoUsuario, isNull);
    });

    test('fromMap ignora valor inválido de tipoUsuario', () {
      final usuario = Usuario.fromMap('x', {'tipoUsuario': 'inexistente'});

      expect(usuario.tipoUsuario, isNull);
    });

    test('assinante não é lido de usuarios (Plano 7: vem de assinantes)', () {
      final map = Usuario.fromMap('x', {'assinante': true}).toMap();

      expect(map.containsKey('assinante'), isFalse);
    });

    test('toMap omite tipoUsuario quando nulo', () {
      final map = Usuario(
        id: '1',
        nome: 'A',
        email: 'a@a.com',
        telefone: '123',
      ).toMap();

      expect(map.containsKey('tipoUsuario'), isFalse);
    });

    test('copyWith altera só os campos informados', () {
      final original = _usuario();

      final alterado = original.copyWith(nome: 'Victor');

      expect(alterado.nome, 'Victor');
      expect(alterado.tipoUsuario, original.tipoUsuario);
      expect(original.nome, 'Guilherme');
    });

    test('clearTipoUsuario remove o tipo definido', () {
      final semTipo = _usuario().copyWith(clearTipoUsuario: true);

      expect(semTipo.tipoUsuario, isNull);
      expect(semTipo.toMap().containsKey('tipoUsuario'), isFalse);
    });

    test('clearTipoUsuario tem prioridade sobre um tipo informado', () {
      final semTipo = _usuario().copyWith(
        tipoUsuario: TipoUsuario.casaShow,
        clearTipoUsuario: true,
      );

      expect(semTipo.tipoUsuario, isNull);
    });
  });
}
