import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/data_hora.dart';
import '../../models/filtro_oportunidades.dart';

/// Abre o painel de filtro e devolve o filtro escolhido (`null` = fechou sem
/// aplicar). [mostrarAgenda]: opções que dependem da agenda do músico.
Future<FiltroOportunidades?> abrirPainelFiltroOportunidades(
  BuildContext context, {
  required FiltroOportunidades atual,
  required bool mostrarAgenda,
}) {
  return showModalBottomSheet<FiltroOportunidades>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        _PainelFiltro(atual: atual, mostrarAgenda: mostrarAgenda),
  );
}

class _PainelFiltro extends StatefulWidget {
  const _PainelFiltro({required this.atual, required this.mostrarAgenda});

  final FiltroOportunidades atual;
  final bool mostrarAgenda;

  @override
  State<_PainelFiltro> createState() => _PainelFiltroState();
}

class _PainelFiltroState extends State<_PainelFiltro> {
  late FiltroOportunidades _filtro = widget.atual;
  late final _cidadeController = TextEditingController(
    text: widget.atual.cidade ?? '',
  );
  late final _cacheController = TextEditingController(
    text: widget.atual.cacheMinimo?.toStringAsFixed(0) ?? '',
  );

  @override
  void dispose() {
    _cidadeController.dispose();
    _cacheController.dispose();
    super.dispose();
  }

  Future<void> _escolherData({required bool inicio}) async {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final atual = inicio ? _filtro.de : _filtro.ate;
    final escolhida = await showDatePicker(
      context: context,
      initialDate: atual != null && !atual.isBefore(hoje) ? atual : hoje,
      firstDate: hoje,
      lastDate: DateTime(hoje.year + 2),
    );
    if (escolhida == null) return;
    setState(() {
      _filtro = inicio
          ? _filtro.copyWith(de: escolhida)
          : _filtro.copyWith(ate: escolhida);
    });
  }

  void _aplicar() {
    final cidade = _cidadeController.text.trim();
    final cache = double.tryParse(
      _cacheController.text.trim().replaceAll(',', '.'),
    );
    var filtro = _filtro.copyWith(
      cidade: cidade,
      limparCidade: cidade.isEmpty,
      cacheMinimo: cache,
      limparCacheMinimo: cache == null || cache <= 0,
    );
    // Período invertido: troca as pontas em vez de não achar nada.
    final de = filtro.de;
    final ate = filtro.ate;
    if (de != null && ate != null && ate.isBefore(de)) {
      filtro = filtro.copyWith(de: ate, ate: de);
    }
    Navigator.pop(context, filtro);
  }

  @override
  Widget build(BuildContext context) {
    final de = _filtro.de;
    final ate = _filtro.ate;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Filtrar oportunidades',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _filtro.genero,
              decoration: const InputDecoration(labelText: 'Gênero musical'),
              items: [
                const DropdownMenuItem<String>(child: Text('Todos')),
                for (final genero in AppStrings.generosMusicais)
                  DropdownMenuItem(value: genero, child: Text(genero)),
              ],
              onChanged: (genero) => setState(() {
                _filtro = _filtro.copyWith(
                  genero: genero,
                  limparGenero: genero == null,
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cidadeController,
              decoration: const InputDecoration(labelText: 'Cidade'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cacheController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Cachê mínimo (R\$)',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _escolherData(inicio: true),
                    child: Text(de == null ? 'De' : 'De ${formatarData(de)}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _escolherData(inicio: false),
                    child: Text(
                      ate == null ? 'Até' : 'Até ${formatarData(ate)}',
                    ),
                  ),
                ),
              ],
            ),
            if (widget.mostrarAgenda) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Só dias em que estou livre'),
                subtitle: const Text('Sem show confirmado e sem bloqueio'),
                value: _filtro.soDiasLivres,
                onChanged: (valor) => setState(() {
                  _filtro = _filtro.copyWith(soDiasLivres: valor);
                }),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.pop(context, const FiltroOportunidades()),
                    child: const Text('Limpar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _aplicar,
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
