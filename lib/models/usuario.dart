enum TipoUsuario { musico, casaShow }

class Usuario {
  final String id;
  final String nome;
  final String email;
  final String telefone;
  final TipoUsuario tipoUsuario;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.tipoUsuario,
  });
}
