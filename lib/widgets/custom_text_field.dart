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

  /// Plano 8: campos de várias linhas (descrição, portfólio) e limite de
  /// caracteres com contador.
  final int linhas;
  final int? maxLength;

  /// Explicação fixa abaixo do campo (ex.: "Um link por linha").
  final String? ajuda;

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
    this.linhas = 1,
    this.maxLength,
    this.ajuda,
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
      // Várias linhas de texto: o Enter quebra linha em vez de enviar.
      keyboardType:
          widget.linhas > 1 && widget.keyboardType == TextInputType.text
          ? TextInputType.multiline
          : widget.keyboardType,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onFieldSubmitted: widget.onSubmitted,
      maxLines: widget.linhas,
      maxLength: widget.maxLength,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.dica,
        helperText: widget.ajuda,
        helperMaxLines: 2,
        // Rótulo no alto em campo de várias linhas, como nos protótipos.
        alignLabelWithHint: widget.linhas > 1,
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
