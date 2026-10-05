import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/data_hora.dart';
import '../../models/filtro_musicos.dart';
import '../../models/musico.dart';
import '../../widgets/titulo_secao.dart';

/// Abre o painel de filtro da lista de músicos e devolve o filtro escolhido
/// (`null` = fechou sem aplicar). Pesquisa e gênero ficam no topo da lista
/// (Plano 8) e passam intactos pelo painel.
Future<FiltroMusicos?> abrirPainelFiltroMusicos(
  BuildContext context, {
  required FiltroMusicos atual,
  bool mostrarFavoritos = false,
}) {
  return showModalBottomSheet<FiltroMusicos>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        _PainelFiltroMusicos(atual: atual, mostrarFavoritos: mostrarFavoritos),
  );
}

class _PainelFiltroMusicos extends StatefulWidget {
  const _PainelFiltroMusicos({
    required this.atual,
    required this.mostrarFavoritos,
  });

  final FiltroMusicos atual;

  /// Plano 18: só quem favorita músicos (dono/admin) vê a opção.
  final bool mostrarFavoritos;

  @override
  State<_PainelFiltroMusicos> createState() => _PainelFiltroMusicosState();
}

class _PainelFiltroMusicosState extends State<_PainelFiltroMusicos> {
  late FiltroMusicos _filtro = widget.atual;
  late final _cidadeController = TextEditingController(
    text: widget.atual.cidade ?? '',
  );

  @override
  void dispose() {
    _cidadeController.dispose();
    super.dispose();
  }

  Future<void> _escolherDia() async {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final atual = _filtro.livresEm;
    final escolhida = await showDatePicker(
      context: context,
      helpText: 'Músicos livres em',
      initialDate: atual != null && !atual.isBefore(hoje) ? atual : hoje,
      firstDate: hoje,
      lastDate: DateTime(hoje.year + 2),
    );
    if (escolhida != null) {
      setState(() => _filtro = _filtro.copyWith(livresEm: escolhida));
    }
  }

  void _aplicar() {
    final cidade = _cidadeController.text.trim();
    Navigator.pop(
      context,
      _filtro.copyWith(cidade: cidade, limparCidade: cidade.isEmpty),
    );
  }

  /// Zera o painel, mantendo pesquisa e gênero (que ficam no topo).
  void _limpar() {
    Navigator.pop(
      context,
      FiltroMusicos(termo: widget.atual.termo, genero: widget.atual.genero),
    );
  }

  @override
  Widget build(BuildContext context) {
    final livresEm = _filtro.livresEm;

    Widget formacao(String rotulo, Formacao? valor) => ChoiceChip(
      label: Text(rotulo),
      selected: _filtro.formacao == valor,
      showCheckmark: false,
      onSelected: (_) => setState(() {
        _filtro = _filtro.copyWith(
          formacao: valor,
          limparFormacao: valor == null,
        );
      }),
    );

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
              'Filtrar músicos',
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
            const SizedBox(height: AppSpacing.md),
            const RotuloSecao('Formação'),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                formacao('Qualquer', null),
                for (final f in Formacao.values) formacao(f.rotulo, f),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Só com equipamento próprio'),
              value: _filtro.soEquipamentoProprio,
              onChanged: (valor) => setState(() {
                _filtro = _filtro.copyWith(soEquipamentoProprio: valor);
              }),
            ),
            if (widget.mostrarFavoritos)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Só favoritos'),
                value: _filtro.soFavoritos,
                onChanged: (valor) => setState(() {
                  _filtro = _filtro.copyWith(soFavoritos: valor);
                }),
              ),
            const SizedBox(height: AppSpacing.xs),
            const RotuloSecao('Agenda'),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _escolherDia,
                    icon: const Icon(Icons.event_available),
                    label: Text(
                      livresEm == null
                          ? 'Livres em uma data'
                          : 'Livres em ${formatarData(livresEm)}',
                    ),
                  ),
                ),
                if (livresEm != null)
                  IconButton(
                    tooltip: 'Tirar a data',
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _filtro = _filtro.copyWith(limparLivresEm: true);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _filtro.ordenacao,
              decoration: const InputDecoration(labelText: 'Ordenar por'),
              items: const [
                DropdownMenuItem(value: 'nome_asc', child: Text('Nome (A-Z)')),
                DropdownMenuItem(value: 'nome_desc', child: Text('Nome (Z-A)')),
                DropdownMenuItem(
                  value: 'cache_maior',
                  child: Text('Cachê (maior primeiro)'),
                ),
                DropdownMenuItem(
                  value: 'cache_menor',
                  child: Text('Cachê (menor primeiro)'),
                ),
              ],
              onChanged: (ordem) => setState(() {
                _filtro = _filtro.copyWith(ordenacao: ordem);
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _limpar,
                    child: const Text('Limpar'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
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
