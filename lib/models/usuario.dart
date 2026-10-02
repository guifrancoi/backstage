enum TipoUsuario { musico, casaShow }

/// Dados básicos da conta (`usuarios/{uid}`, lido e escrito só pelo dono).
/// Ser assinante **não** fica aqui (o próprio usuário poderia se marcar):
/// vem da coleção `assinantes`, gravada pelo Admin SDK (Plano 7).
class Usuario {
  final String id;
  final String nome;
  final String email;
  final String telefone;
  final TipoUsuario? tipoUsuario;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    this.tipoUsuario,
  });

  Usuario copyWith({
    String? id,
    String? nome,
    String? email,
    String? telefone,
    TipoUsuario? tipoUsuario,
    bool clearTipoUsuario = false,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      tipoUsuario: clearTipoUsuario ? null : (tipoUsuario ?? this.tipoUsuario),
    );
  }

  factory Usuario.fromMap(String id, Map<String, dynamic> map) {
    return Usuario(
      id: id,
      nome: map['nome'] as String? ?? '',
      email: map['email'] as String? ?? '',
      telefone: map['telefone'] as String? ?? '',
      tipoUsuario: _tipoUsuarioFromValue(map['tipoUsuario']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'telefone': telefone,
      if (tipoUsuario != null) 'tipoUsuario': tipoUsuario!.name,
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
