import 'package:flutter/material.dart';

/// Campo de formulário padrão (estilo vem do `inputDecorationTheme`). Plano 8:
/// ícone opcional à esquerda e, em senha, botão de mostrar/ocultar.
class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  /// Ícone à esquerda (ex.: `Icons.mail_outline`).
  final IconData? icone;

  /// Texto de exemplo dentro do campo.
  final String? dica;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.icone,
    this.dica,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _oculto = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _oculto,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onFieldSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.dica,
        prefixIcon: widget.icone == null ? null : Icon(widget.icone),
        suffixIcon: widget.obscureText
            ? IconButton(
                tooltip: _oculto ? 'Mostrar senha' : 'Ocultar senha',
                icon: Icon(
                  _oculto
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _oculto = !_oculto),
              )
            : null,
      ),
    );
  }
}
