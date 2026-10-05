import '../../models/musico.dart';
import '../../models/oportunidade.dart';
import 'texto.dart';

/// Sugestões de compatibilidade (Plano 15) e prioridade de assinantes
/// (Plano 7). Tudo aqui é função pura: as telas e o provider só juntam os
/// dados (agenda, interesses, assinantes) e chamam.

/// Pesos fixos dos critérios (somam 100).
abstract final class PesosCompatibilidade {
  static const genero = 35;
  static const cidade = 25;
  static const cache = 20;
  static const formacao = 5;
  static const equipamento = 5;
  static const livreNoDia = 10;

  /// Abaixo disso o par não aparece como sugestão.
  static const notaMinima = 50;
}

/// Resultado de um par músico × oportunidade: nota de 0 a 100 e os motivos
/// que somaram pontos, na ordem dos pesos (para mostrar ao usuário).
class Compatibilidade {
  const Compatibilidade(this.nota, this.motivos);

  final int nota;
  final List<String> motivos;

  bool get sugerivel => nota >= PesosCompatibilidade.notaMinima;
}

/// Avalia o par. `null` = eliminado:
/// - músico oculto, oportunidade oculta, sem dono, vencida ou do próprio músico;
/// - músico com show confirmado ([ocupado]) ou que bloqueou o dia ([bloqueado]);
/// - já existe interesse entre os dois nessa oportunidade ([jaTemInteresse]).
///
/// [agendaConhecida] = `false` quando a agenda não pôde ser lida: não
/// elimina, mas também não soma "livre no dia".
Compatibilidade? avaliarCompatibilidade({
  required Musico musico,
  required Oportunidade oportunidade,
  required DateTime hoje,
  bool ocupado = false,
  bool bloqueado = false,
  bool agendaConhecida = true,
  bool jaTemInteresse = false,
}) {
  if (musico.oculto ||
      oportunidade.oculto ||
      !oportunidade.temDono ||
      oportunidade.donoId == musico.id ||
      oportunidade.vencidaEm(hoje) ||
      ocupado ||
      bloqueado ||
      jaTemInteresse) {
    return null;
  }

  var nota = 0;
  final motivos = <String>[];
  void somar(bool criterio, int peso, String motivo) {
    if (!criterio) return;
    nota += peso;
    motivos.add(motivo);
  }

  somar(
    musico.generoMusical == oportunidade.generoMusical,
    PesosCompatibilidade.genero,
    'Mesmo gênero',
  );
  somar(
    _normalizar(musico.cidade).isNotEmpty &&
        _normalizar(musico.cidade) == _normalizar(oportunidade.cidade),
    PesosCompatibilidade.cidade,
    'Mesma cidade',
  );
  somar(
    musico.cacheMedio <= oportunidade.cacheOferecido,
    PesosCompatibilidade.cache,
    'Cachê dentro do oferecido',
  );
  somar(
    agendaConhecida,
    PesosCompatibilidade.livreNoDia,
    'Livre no dia',
  );
  final formacao = musico.formacao;
  somar(
    formacao != null,
    PesosCompatibilidade.formacao,
    formacao?.rotulo ?? '',
  );
  somar(
    musico.equipamentoProprio,
    PesosCompatibilidade.equipamento,
    'Equipamento próprio',
  );
  return Compatibilidade(nota, motivos);
}

/// Item sugerido com a avaliação e se o "outro lado" é assinante.
class Sugestao<T> {
  const Sugestao(this.item, this.compatibilidade, {this.assinante = false});

  final T item;
  final Compatibilidade compatibilidade;
  final bool assinante;
}

/// Só as sugeríveis, da maior nota para a menor; assinante desempata notas
/// iguais (Plano 7: nunca soma pontos). [desempate] decide o resto (nome,
/// data). Devolve no máximo [limite].
List<Sugestao<T>> ordenarSugestoes<T>(
  Iterable<Sugestao<T>> sugestoes, {
  required int Function(T a, T b) desempate,
  int? limite,
}) {
  final lista = sugestoes.where((s) => s.compatibilidade.sugerivel).toList()
    ..sort((a, b) {
      final porNota = b.compatibilidade.nota.compareTo(a.compatibilidade.nota);
      if (porNota != 0) return porNota;
      if (a.assinante != b.assinante) return a.assinante ? -1 : 1;
      return desempate(a.item, b.item);
    });
  return limite == null || lista.length <= limite
      ? lista
      : lista.sublist(0, limite);
}

/// Plano 7: assinantes primeiro, mantendo entre eles (e entre os demais) a
/// ordem que a lista já tinha. Não usa `sort` (não é estável em Dart).
List<T> assinantesPrimeiro<T>(
  Iterable<T> lista,
  bool Function(T item) ehAssinante,
) {
  final assinantes = <T>[];
  final demais = <T>[];
  for (final item in lista) {
    (ehAssinante(item) ? assinantes : demais).add(item);
  }
  return [...assinantes, ...demais];
}

String _normalizar(String texto) => normalizarTexto(texto);
