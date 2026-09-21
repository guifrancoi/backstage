class Musico {
  final String id;
  final String nomeArtistico;
  final String generoMusical;
  final String cidade;
  final String descricao;
  final double cacheMedio;
  final List<String> portfolioLinks;
  final List<String> datasDisponiveis;
  final String? fotoPath;
  final bool interesseEnviado;

  Musico({
    required this.id,
    required this.nomeArtistico,
    required this.generoMusical,
    required this.cidade,
    required this.descricao,
    required this.cacheMedio,
    required this.portfolioLinks,
    required this.datasDisponiveis,
    this.fotoPath,
    bool? interesseEnviado,
  }) : interesseEnviado = interesseEnviado ?? false;

  Musico copyWith({
    String? id,
    String? nomeArtistico,
    String? generoMusical,
    String? cidade,
    String? descricao,
    double? cacheMedio,
    List<String>? portfolioLinks,
    List<String>? datasDisponiveis,
    String? fotoPath,
    bool? interesseEnviado,
  }) {
    return Musico(
      id: id ?? this.id,
      nomeArtistico: nomeArtistico ?? this.nomeArtistico,
      generoMusical: generoMusical ?? this.generoMusical,
      cidade: cidade ?? this.cidade,
      descricao: descricao ?? this.descricao,
      cacheMedio: cacheMedio ?? this.cacheMedio,
      portfolioLinks: portfolioLinks ?? this.portfolioLinks,
      datasDisponiveis: datasDisponiveis ?? this.datasDisponiveis,
      fotoPath: fotoPath ?? this.fotoPath,
      interesseEnviado: interesseEnviado ?? this.interesseEnviado,
    );
  }

  factory Musico.fromMap(String id, Map<String, dynamic> map) {
    return Musico(
      id: id,
      nomeArtistico: map['nomeArtistico'] as String? ?? '',
      generoMusical: map['generoMusical'] as String? ?? '',
      cidade: map['cidade'] as String? ?? '',
      descricao: map['descricao'] as String? ?? '',
      cacheMedio: (map['cacheMedio'] as num?)?.toDouble() ?? 0,
      portfolioLinks: List<String>.from(map['portfolioLinks'] as List? ?? []),
      datasDisponiveis: List<String>.from(
        map['datasDisponiveis'] as List? ?? [],
      ),
      fotoPath: map['fotoPath'] as String?,
      interesseEnviado: map['interesseEnviado'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nomeArtistico': nomeArtistico,
      'generoMusical': generoMusical,
      'cidade': cidade,
      'descricao': descricao,
      'cacheMedio': cacheMedio,
      'portfolioLinks': portfolioLinks,
      'datasDisponiveis': datasDisponiveis,
      'fotoPath': fotoPath,
      'interesseEnviado': interesseEnviado,
    };
  }
}
