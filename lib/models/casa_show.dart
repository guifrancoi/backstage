class CasaShow {
  final String id;
  final String nome;
  final String cidade;
  final int capacidade;
  final List<String> estilosDesejados;
  final String descricao;
  final String contato;
  final String cnpj;

  CasaShow({
    required this.id,
    required this.nome,
    required this.cidade,
    required this.capacidade,
    required this.estilosDesejados,
    required this.descricao,
    required this.contato,
    required this.cnpj,
  });

  CasaShow copyWith({
    String? id,
    String? nome,
    String? cidade,
    int? capacidade,
    List<String>? estilosDesejados,
    String? descricao,
    String? contato,
    String? cnpj,
  }) {
    return CasaShow(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cidade: cidade ?? this.cidade,
      capacidade: capacidade ?? this.capacidade,
      estilosDesejados: estilosDesejados ?? this.estilosDesejados,
      descricao: descricao ?? this.descricao,
      contato: contato ?? this.contato,
      cnpj: cnpj ?? this.cnpj,
    );
  }

  factory CasaShow.fromMap(String id, Map<String, dynamic> map) {
    return CasaShow(
      id: id,
      nome: map['nome'] as String? ?? '',
      cidade: map['cidade'] as String? ?? '',
      capacidade: (map['capacidade'] as num?)?.toInt() ?? 0,
      estilosDesejados: List<String>.from(
        map['estilosDesejados'] as List? ?? [],
      ),
      descricao: map['descricao'] as String? ?? '',
      contato: map['contato'] as String? ?? '',
      cnpj: map['cnpj'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'cidade': cidade,
      'capacidade': capacidade,
      'estilosDesejados': estilosDesejados,
      'descricao': descricao,
      'contato': contato,
      'cnpj': cnpj,
    };
  }
}
