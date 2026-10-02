import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/data_hora.dart';
import '../../models/filtro_musicos.dart';
import '../../models/musico.dart';

/// Abre o painel de filtro da lista de músicos e devolve o filtro escolhido
/// (`null` = fechou sem aplicar).
Future<FiltroMusicos?> abrirPainelFiltroMusicos(
  BuildContext context, {
  required FiltroMusicos atual,
}) {
  return showModalBottomSheet<FiltroMusicos>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PainelFiltroMusicos(atual: atual),
  );
}

class _PainelFiltroMusicos extends StatefulWidget {
  const _PainelFiltroMusicos({required this.atual});

  final FiltroMusicos atual;

  @override
  State<_PainelFiltroMusicos> createState() => _PainelFiltroMusicosState();
}

class _PainelFiltroMusicosState extends State<_PainelFiltroMusicos> {
  late FiltroMusicos _filtro = widget.atual;
  late final _termoController = TextEditingController(text: widget.atual.termo);
  late final _cidadeController = TextEditingController(
    text: widget.atual.cidade ?? '',
  );

  @override
  void dispose() {
    _termoController.dispose();
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
      _filtro.copyWith(
        termo: _termoController.text.trim(),
        cidade: cidade,
        limparCidade: cidade.isEmpty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final livresEm = _filtro.livresEm;

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
              'Filtrar músicos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _termoController,
              decoration: const InputDecoration(
                labelText: 'Pesquisar artista',
                hintText: 'Nome ou descrição',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
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
            DropdownButtonFormField<Formacao?>(
              initialValue: _filtro.formacao,
              decoration: const InputDecoration(labelText: 'Formação'),
              items: [
                const DropdownMenuItem<Formacao?>(child: Text('Qualquer')),
                for (final f in Formacao.values)
                  DropdownMenuItem<Formacao?>(value: f, child: Text(f.rotulo)),
              ],
              onChanged: (formacao) => setState(() {
                _filtro = _filtro.copyWith(
                  formacao: formacao,
                  limparFormacao: formacao == null,
                );
              }),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Só com equipamento próprio'),
              value: _filtro.soEquipamentoProprio,
              onChanged: (valor) => setState(() {
                _filtro = _filtro.copyWith(soEquipamentoProprio: valor);
              }),
            ),
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.pop(context, const FiltroMusicos()),
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
