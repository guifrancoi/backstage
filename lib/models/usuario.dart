enum TipoUsuario { musico, casaShow }

class Usuario {
  final String id;
  final String nome;
  final String email;
  final String telefone;
  final TipoUsuario? tipoUsuario;
  final bool assinante;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    this.tipoUsuario,
    bool? assinante,
  }) : assinante = assinante ?? false;

  Usuario copyWith({
    String? id,
    String? nome,
    String? email,
    String? telefone,
    TipoUsuario? tipoUsuario,
    bool? assinante,
    bool clearTipoUsuario = false,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      tipoUsuario: clearTipoUsuario ? null : (tipoUsuario ?? this.tipoUsuario),
      assinante: assinante ?? this.assinante,
    );
  }

  factory Usuario.fromMap(String id, Map<String, dynamic> map) {
    return Usuario(
      id: id,
      nome: map['nome'] as String? ?? '',
      email: map['email'] as String? ?? '',
      telefone: map['telefone'] as String? ?? '',
      tipoUsuario: _tipoUsuarioFromValue(map['tipoUsuario']),
      assinante: map['assinante'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'telefone': telefone,
      if (tipoUsuario != null) 'tipoUsuario': tipoUsuario!.name,
      'assinante': assinante,
    };
  }
}

TipoUsuario? _tipoUsuarioFromValue(dynamic value) {
  if (value is! String) return null;
  try {
    return TipoUsuario.values.byName(value);
  } catch (_) {
    return null;
  }
}
