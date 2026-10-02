import '../core/constants/app_strings.dart';

/// Formação do artista (Plano 14), persistida como `.name`.
enum Formacao {
  solo('Solo'),
  duo('Duo'),
  trio('Trio'),
  banda('Banda');

  const Formacao(this.rotulo);
  final String rotulo;

  static Formacao? deNome(String? nome) {
    for (final f in values) {
      if (f.name == nome) return f;
    }
    return null;
  }
}

class Musico {
  /// Tamanho máximo da miniatura em base64 (caracteres) — o mesmo limite
  /// está em `firestore.rules`. Uma foto de 256 px em JPEG fica bem abaixo.
  static const tamanhoMaximoFoto = 200000;

  final String id;
  final String nomeArtistico;
  final String generoMusical;
  final String cidade;
  final String descricao;
  final double cacheMedio;
  final List<String> portfolioLinks;

  /// Miniatura da foto (JPEG/PNG em base64), gravada no próprio perfil para
  /// que todos a vejam (Plano 14). Substitui o antigo `fotoPath`, que era um
  /// caminho no aparelho de quem escolheu a foto.
  final String? foto;

  // Dados do show (Plano 14) — todos opcionais.
  final Formacao? formacao;

  /// Só faz sentido para banda (solo/duo/trio já dizem quantos são).
  final int? integrantes;
  final bool equipamentoProprio;
  final int? duracaoShowMin;
  final String? repertorio;

  /// Criado pela conta admin: não aparece para os outros usuários.
  final bool oculto;

  Musico({
    required this.id,
    required this.nomeArtistico,
    required this.generoMusical,
    required this.cidade,
    required this.descricao,
    required this.cacheMedio,
    required this.portfolioLinks,
    this.foto,
    this.formacao,
    this.integrantes,
    this.equipamentoProprio = false,
    this.duracaoShowMin,
    this.repertorio,
    this.oculto = false,
  });

  /// Campos obrigatórios do perfil (os mesmos do formulário de edição):
  /// nome artístico, gênero da lista, cidade, cachê e descrição. Os dados do
  /// show (Plano 14) são opcionais e não entram aqui.
  bool get completo =>
      nomeArtistico.trim().isNotEmpty &&
      AppStrings.generosMusicais.contains(generoMusical) &&
      cidade.trim().isNotEmpty &&
      descricao.trim().isNotEmpty &&
      cacheMedio >= 0;

  /// Formação com o número de integrantes da banda: "Banda (5 integrantes)".
  String? get formacaoDescrita {
    final f = formacao;
    if (f == null) return null;
    final n = integrantes;
    if (f == Formacao.banda && n != null) return 'Banda ($n integrantes)';
    return f.rotulo;
  }

  /// Linha curta do card: "Trio · Equipamento próprio" (`null` se vazio).
  String? get resumoShow {
    final partes = [
      ?formacao?.rotulo,
      if (equipamentoProprio) 'Equipamento próprio',
    ];
    return partes.isEmpty ? null : partes.join(' · ');
  }

  Musico copyWith({
    String? id,
    String? nomeArtistico,
    String? generoMusical,
    String? cidade,
    String? descricao,
    double? cacheMedio,
    List<String>? portfolioLinks,
    String? foto,
    Formacao? formacao,
    int? integrantes,
    bool? equipamentoProprio,
    int? duracaoShowMin,
    String? repertorio,
    bool? oculto,
    bool clearFoto = false,
  }) {
    return Musico(
      id: id ?? this.id,
      nomeArtistico: nomeArtistico ?? this.nomeArtistico,
      generoMusical: generoMusical ?? this.generoMusical,
      cidade: cidade ?? this.cidade,
      descricao: descricao ?? this.descricao,
      cacheMedio: cacheMedio ?? this.cacheMedio,
      portfolioLinks: portfolioLinks ?? this.portfolioLinks,
      foto: clearFoto ? null : (foto ?? this.foto),
      formacao: formacao ?? this.formacao,
      integrantes: integrantes ?? this.integrantes,
      equipamentoProprio: equipamentoProprio ?? this.equipamentoProprio,
      duracaoShowMin: duracaoShowMin ?? this.duracaoShowMin,
      repertorio: repertorio ?? this.repertorio,
      oculto: oculto ?? this.oculto,
    );
  }

  factory Musico.fromMap(String id, Map<String, dynamic> map) {
    String? texto(String chave) {
      final valor = (map[chave] as String?)?.trim();
      return valor == null || valor.isEmpty ? null : valor;
    }

    return Musico(
      id: id,
      nomeArtistico: map['nomeArtistico'] as String? ?? '',
      generoMusical: map['generoMusical'] as String? ?? '',
      cidade: map['cidade'] as String? ?? '',
      descricao: map['descricao'] as String? ?? '',
      cacheMedio: (map['cacheMedio'] as num?)?.toDouble() ?? 0,
      portfolioLinks: List<String>.from(map['portfolioLinks'] as List? ?? []),
      foto: texto('foto'),
      formacao: Formacao.deNome(map['formacao'] as String?),
      integrantes: (map['integrantes'] as num?)?.toInt(),
      equipamentoProprio: map['equipamentoProprio'] as bool? ?? false,
      duracaoShowMin: (map['duracaoShowMin'] as num?)?.toInt(),
      repertorio: texto('repertorio'),
      oculto: map['oculto'] as bool? ?? false,
    );
  }

  /// Grava todas as chaves (inclusive `null`): o perfil é salvo com merge, e
  /// assim um campo apagado no formulário também some do documento.
  Map<String, dynamic> toMap() {
    return {
      'nomeArtistico': nomeArtistico,
      'generoMusical': generoMusical,
      'cidade': cidade,
      'descricao': descricao,
      'cacheMedio': cacheMedio,
      'portfolioLinks': portfolioLinks,
      'foto': foto,
      'formacao': formacao?.name,
      'integrantes': integrantes,
      'equipamentoProprio': equipamentoProprio,
      'duracaoShowMin': duracaoShowMin,
      'repertorio': repertorio,
      'oculto': oculto,
    };
  }
}
