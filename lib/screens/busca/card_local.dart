import 'package:flutter/material.dart';

import '../../widgets/titulo_secao.dart';
import 'abrir_mapa.dart';

/// Seção "Local" dos detalhes (oportunidade e estabelecimento, Plano 8):
/// endereço e "Ver no mapa" (com indicador enquanto geocodifica). Sem
/// endereço completo, mostra só a cidade e o mapa busca por ela.
class CardLocal extends StatefulWidget {
  const CardLocal({
    super.key,
    required this.logradouro,
    required this.numero,
    required this.cidade,
    required this.estado,
    this.cep,
    this.titulo = 'Local',
  });

  final String logradouro;
  final String numero;
  final String cidade;
  final String estado;
  final String? cep;
  final String titulo;

  @override
  State<CardLocal> createState() => _CardLocalState();
}

class _CardLocalState extends State<CardLocal> {
  bool _carregandoMapa = false;

  bool get _temEndereco =>
      widget.logradouro.isNotEmpty &&
      widget.numero.isNotEmpty &&
      widget.estado.isNotEmpty;

  Future<void> _verNoMapa() async {
    setState(() => _carregandoMapa = true);
    try {
      await abrirMapa(
        context,
        logradouro: widget.logradouro,
        numero: widget.numero,
        cidade: widget.cidade,
        estado: widget.estado,
        cep: widget.cep,
      );
    } finally {
      if (mounted) setState(() => _carregandoMapa = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cep = widget.cep;
    return CardSecao(
      titulo: widget.titulo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_temEndereco) ...[
            Text('${widget.logradouro}, ${widget.numero}'),
            Text(
              '${widget.cidade} — ${widget.estado}'
              '${cep != null && cep.isNotEmpty ? '  CEP: $cep' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else
            Text(widget.cidade),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _carregandoMapa ? null : _verNoMapa,
            icon: _carregandoMapa
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.map_outlined),
            label: const Text('Ver no mapa'),
          ),
        ],
      ),
    );
  }
}
