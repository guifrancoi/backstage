import 'dart:async';

import 'package:flutter/material.dart';

/// Campo de pesquisa do topo das listas (Plano 8): ícone de lupa, "x" para
/// limpar e espera curta antes de avisar [onChanged] (não refiltra a cada
/// tecla). Se [valor] mudar por fora (ex.: "Limpar filtros"), o texto acompanha.
class CampoPesquisa extends StatefulWidget {
  const CampoPesquisa({
    super.key,
    required this.valor,
    required this.onChanged,
    required this.dica,
    this.espera = const Duration(milliseconds: 300),
  });

  final String valor;
  final ValueChanged<String> onChanged;

  /// Texto de exemplo ("Nome, gênero, cidade...").
  final String dica;
  final Duration espera;

  @override
  State<CampoPesquisa> createState() => _CampoPesquisaState();
}

class _CampoPesquisaState extends State<CampoPesquisa> {
  late final _controller = TextEditingController(text: widget.valor);
  Timer? _timer;

  @override
  void didUpdateWidget(CampoPesquisa antigo) {
    super.didUpdateWidget(antigo);
    // Só sincroniza mudança vinda de fora (não a que o próprio campo gerou;
    // quem guarda o termo tira os espaços das pontas, e apagar o espaço
    // atrapalharia quem digita "rock nacional").
    if (widget.valor != antigo.valor &&
        widget.valor.trim() != _controller.text.trim()) {
      _controller.text = widget.valor;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _mudou(String texto) {
    setState(() {}); // mostra/esconde o "x"
    _timer?.cancel();
    _timer = Timer(widget.espera, () => widget.onChanged(texto));
  }

  void _limpar() {
    _timer?.cancel();
    _controller.clear();
    setState(() {});
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _mudou,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.dica,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpar pesquisa',
                icon: const Icon(Icons.close),
                onPressed: _limpar,
              ),
      ),
    );
  }
}
