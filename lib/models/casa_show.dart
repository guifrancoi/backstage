/// Perfil do dono de estabelecimento, em `estabelecimentos/{uid}`.
class CasaShow {
  final String id;
  final String nome;
  final String cidade;
  final String logradouro;
  final String numero;
  final String estado;
  final String? cep;
  final int capacidade;
  final List<String> estilosDesejados;
  final String descricao;
  final String contato;
  final String cnpj;

  /// Criado pela conta admin: não aparece para os outros usuários.
  final bool oculto;

  CasaShow({
    required this.id,
    required this.nome,
    required this.cidade,
    required this.capacidade,
    required this.estilosDesejados,
    required this.descricao,
    required this.contato,
    required this.cnpj,
    this.logradouro = '',
    this.numero = '',
    this.estado = '',
    this.cep,
    this.oculto = false,
  });

  /// Campos obrigatórios do perfil (decisão de 29/09/2026): nome, cidade,
  /// endereço e contato.
  bool get completo =>
      nome.trim().isNotEmpty &&
      cidade.trim().isNotEmpty &&
      logradouro.trim().isNotEmpty &&
      numero.trim().isNotEmpty &&
      estado.trim().isNotEmpty &&
      contato.trim().isNotEmpty;

  CasaShow copyWith({
    String? id,
    String? nome,
    String? cidade,
    String? logradouro,
    String? numero,
    String? estado,
    String? cep,
    int? capacidade,
    List<String>? estilosDesejados,
    String? descricao,
    String? contato,
    String? cnpj,
    bool? oculto,
    bool clearCep = false,
  }) {
    return CasaShow(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cidade: cidade ?? this.cidade,
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      estado: estado ?? this.estado,
      cep: clearCep ? null : (cep ?? this.cep),
      capacidade: capacidade ?? this.capacidade,
      estilosDesejados: estilosDesejados ?? this.estilosDesejados,
      descricao: descricao ?? this.descricao,
      contato: contato ?? this.contato,
      cnpj: cnpj ?? this.cnpj,
      oculto: oculto ?? this.oculto,
    );
  }

  factory CasaShow.fromMap(String id, Map<String, dynamic> map) {
    return CasaShow(
      id: id,
      nome: map['nome'] as String? ?? '',
      cidade: map['cidade'] as String? ?? '',
      logradouro: map['logradouro'] as String? ?? '',
      numero: map['numero'] as String? ?? '',
      estado: map['estado'] as String? ?? '',
      cep: map['cep'] as String?,
      capacidade: (map['capacidade'] as num?)?.toInt() ?? 0,
      estilosDesejados: List<String>.from(
        map['estilosDesejados'] as List? ?? [],
      ),
      descricao: map['descricao'] as String? ?? '',
      contato: map['contato'] as String? ?? '',
      cnpj: map['cnpj'] as String? ?? '',
      oculto: map['oculto'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'cidade': cidade,
      'logradouro': logradouro,
      'numero': numero,
      'estado': estado,
      'cep': ?cep,
      'capacidade': capacidade,
      'estilosDesejados': estilosDesejados,
      'descricao': descricao,
      'contato': contato,
      'cnpj': cnpj,
      'oculto': oculto,
    };
  }
}
