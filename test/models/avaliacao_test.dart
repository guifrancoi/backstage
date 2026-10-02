import 'package:backstage/models/avaliacao.dart';
import 'package:backstage/models/contratacao.dart';
import 'package:backstage/models/notificacao.dart';
import 'package:flutter_test/flutter_test.dart';

Avaliacao _avaliacao({int nota = 5, String autorId = 'm1'}) => Avaliacao(
  contratacaoId: 'c1',
  autorId: autorId,
  autorNome: 'Banda',
  avaliadoId: 'e1',
  nota: nota,
  comentario: 'Ótimo',
  criadaEm: DateTime(2026, 10, 1),
);

Contratacao _contratacao({String dia = '2026-11-20', StatusContratacao status = StatusContratacao.confirmada}) =>
    Contratacao(
      id: 'c1',
      interesseId: 'i1',
      musicoId: 'm1',
      musicoNome: 'Banda',
      donoId: 'e1',
      donoNome: 'Bar Central',
      titulo: 'Show de sexta',
      dia: dia,
      horaInicio: '20:00',
      horaFim: '23:00',
      cacheAcordado: 1500,
      logradouro: 'Rua A',
      numero: '10',
      cidade: 'Franca',
      estado: 'SP',
      criadoEm: DateTime(2026, 10, 1),
      status: status,
    );

void main() {
  group('Avaliacao', () {
    test('id é {contratacao}_{autor}; toMap/fromMap ida e volta', () {
      final a = _avaliacao();
      final copia = Avaliacao.fromMap(a.id, a.toMap());

      expect(a.id, 'c1_m1');
      expect(Avaliacao.idDe('c1', 'e1'), 'c1_e1');
      expect(copia.nota, 5);
      expect(copia.avaliadoId, 'e1');
      expect(copia.comentario, 'Ótimo');
      expect(copia.criadaEm, DateTime(2026, 10, 1));
    });
  });

  group('ResumoAvaliacoes', () {
    test('média, quantidade e rótulos com vírgula', () {
      final r = ResumoAvaliacoes.de([
        _avaliacao(nota: 5),
        _avaliacao(nota: 4),
        _avaliacao(nota: 5),
      ]);

      expect(r.quantidade, 3);
      expect(r.media, closeTo(4.67, 0.01));
      expect(r.rotuloCurto, '★ 4,7 (3)');
      expect(r.rotulo, '★ 4,7 · 3 avaliações');
      expect(ResumoAvaliacoes.de([_avaliacao(nota: 3)]).rotulo, '★ 3,0 · 1 avaliação');
    });

    test('sem avaliações', () {
      final r = ResumoAvaliacoes.de(const []);
      expect(r.temAvaliacao, isFalse);
      expect(r.quantidade, 0);
    });
  });

  group('Contratacao.podeAvaliarEm', () {
    final c = _contratacao(); // show em 20/11/2026

    test('abre no dia seguinte e fecha 30 dias depois', () {
      expect(c.podeAvaliarEm(DateTime(2026, 11, 20, 23, 59)), isFalse);
      expect(c.podeAvaliarEm(DateTime(2026, 11, 21)), isTrue);
      expect(c.podeAvaliarEm(DateTime(2026, 12, 20, 23)), isTrue);
      expect(c.podeAvaliarEm(DateTime(2026, 12, 21)), isFalse);
    });

    test('só show confirmado', () {
      expect(
        _contratacao(status: StatusContratacao.cancelada).podeAvaliarEm(DateTime(2026, 11, 22)),
        isFalse,
      );
      expect(
        _contratacao(status: StatusContratacao.proposta).podeAvaliarEm(DateTime(2026, 11, 22)),
        isFalse,
      );
    });
  });

  group('Notificacao.avaliacaoRecebida', () {
    test('vai para a outra parte, com o interesse da contratação', () {
      final n = Notificacao.avaliacaoRecebida(
        _contratacao(),
        autorId: 'm1',
        nota: 4,
        outraParteJaAvaliou: false,
      );

      expect(n.destinatarioId, 'e1');
      expect(n.autorNome, 'Banda');
      expect(n.interesseId, 'i1');
      expect(n.contratacaoId, 'c1');
      expect(n.texto, 'Banda avaliou o show "Show de sexta" com 4 estrelas. Avalie também.');
      expect(n.destino, DestinoNotificacao.contratacoes);
    });

    test('sem convite quando a outra parte já avaliou', () {
      final n = Notificacao.avaliacaoRecebida(
        _contratacao(),
        autorId: 'e1',
        nota: 1,
        outraParteJaAvaliou: true,
      );

      expect(n.destinatarioId, 'm1');
      expect(n.texto, 'Bar Central avaliou o show "Show de sexta" com 1 estrela.');
    });
  });
}
