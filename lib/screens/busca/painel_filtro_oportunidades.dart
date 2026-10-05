import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/data_hora.dart';
import '../../models/filtro_oportunidades.dart';
import '../../widgets/titulo_secao.dart';

/// Abre o painel de filtro e devolve o filtro escolhido (`null` = fechou sem
/// aplicar). [mostrarAgenda]: opções que dependem da agenda do músico.
/// Pesquisa e gênero ficam no topo da lista (Plano 8) e passam intactos.
Future<FiltroOportunidades?> abrirPainelFiltroOportunidades(
  BuildContext context, {
  required FiltroOportunidades atual,
  required bool mostrarAgenda,
}) {
  return showModalBottomSheet<FiltroOportunidades>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _PainelFiltro(atual: atual, mostrarAgenda: mostrarAgenda),
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
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filtrar oportunidades',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _cidadeController,
              decoration: const InputDecoration(
                labelText: 'Cidade',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _cacheController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Cachê mínimo (R\$)',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const RotuloSecao('Período do evento'),
            const SizedBox(height: AppSpacing.xs),
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
              // Plano 18: só o músico favorita oportunidades.
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Só favoritas'),
                value: _filtro.soFavoritas,
                onChanged: (valor) => setState(() {
                  _filtro = _filtro.copyWith(soFavoritas: valor);
                }),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    // Zera o painel, mantendo pesquisa e gênero (no topo).
                    onPressed: () => Navigator.pop(
                      context,
                      FiltroOportunidades(
                        termo: widget.atual.termo,
                        genero: widget.atual.genero,
                      ),
                    ),
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
