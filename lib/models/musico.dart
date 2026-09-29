import '../core/constants/app_strings.dart';

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
    required this.datasDisponiveis,
    this.fotoPath,
    this.oculto = false,
  });

  /// Campos obrigatórios do perfil (os mesmos do formulário de edição):
  /// nome artístico, gênero da lista, cidade, cachê e descrição.
  bool get completo =>
      nomeArtistico.trim().isNotEmpty &&
      AppStrings.generosMusicais.contains(generoMusical) &&
      cidade.trim().isNotEmpty &&
      descricao.trim().isNotEmpty &&
      cacheMedio >= 0;

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
    bool? oculto,
    bool clearFotoPath = false,
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
      fotoPath: clearFotoPath ? null : (fotoPath ?? this.fotoPath),
      oculto: oculto ?? this.oculto,
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
      oculto: map['oculto'] as bool? ?? false,
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
      'oculto': oculto,
    };
  }
}
