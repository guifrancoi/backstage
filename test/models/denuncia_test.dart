import 'package:backstage/models/denuncia.dart';
import 'package:flutter_test/flutter_test.dart';

Denuncia _denuncia({String descricao = 'Bar Central'}) => Denuncia(
  autorId: 'm1',
  autorNome: 'Banda',
  tipoAlvo: TipoAlvoDenuncia.mensagem,
  alvoId: 'msg1',
  alvoUid: 'e1',
  descricaoAlvo: descricao,
  motivo: MotivoDenuncia.perfilFalso,
  texto: 'Detalhe',
  criadaEm: DateTime(2026, 10, 2),
);

void main() {
  test('toMap/fromMap: enums por nome e status pendente', () {
    final map = _denuncia().toMap();
    final copia = Denuncia.fromMap('d1', map);

    expect(map['tipoAlvo'], 'mensagem');
    expect(map['motivo'], 'perfilFalso');
    expect(map['status'], 'pendente');
    expect(map.containsKey('analisadaEm'), isFalse);
    expect(copia.id, 'd1');
    expect(copia.tipoAlvo, TipoAlvoDenuncia.mensagem);
    expect(copia.motivo, MotivoDenuncia.perfilFalso);
    expect(copia.analisada, isFalse);
    expect(copia.criadaEm, DateTime(2026, 10, 2));
  });

  test('descrição do item é cortada no limite das regras', () {
    final map = _denuncia(descricao: 'x' * 400).toMap();
    expect((map['descricaoAlvo'] as String).length, Denuncia.tamanhoMaximoDescricao);
  });

  test('analisada vem do status; valores desconhecidos caem no padrão', () {
    final d = Denuncia.fromMap('d1', {
      'status': 'analisada',
      'tipoAlvo': 'inexistente',
      'motivo': 'inexistente',
    });
    expect(d.analisada, isTrue);
    expect(d.tipoAlvo, TipoAlvoDenuncia.perfil);
    expect(d.motivo, MotivoDenuncia.outro);
  });

  test('UsuarioBloqueado ida e volta', () {
    final b = UsuarioBloqueado(uid: 'm1', nome: 'Banda', criadoEm: DateTime(2026));
    final copia = UsuarioBloqueado.fromMap('m1', b.toMap());
    expect(copia.nome, 'Banda');
    expect(copia.criadoEm, DateTime(2026));
    expect(b.toMap().keys, unorderedEquals(['nome', 'criadoEm']));
  });
}
