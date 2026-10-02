import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/data_hora.dart';
import '../../providers/oportunidade_provider.dart';
import '../../routes/app_routes.dart';

class FiltroBuscaScreen extends StatefulWidget {
  const FiltroBuscaScreen({super.key});

  @override
  State<FiltroBuscaScreen> createState() => _FiltroBuscaScreenState();
}

class _FiltroBuscaScreenState extends State<FiltroBuscaScreen> {
  final _cidadeController = TextEditingController();
  final _pesquisaController = TextEditingController();
  String? _generoSelecionado;
  String _tipoOrdenacao = 'nome_asc';
  DateTime? _livresEm;

  @override
  void initState() {
    super.initState();

    final provider = context.read<OportunidadeProvider>();
    _generoSelecionado = provider.generoSelecionadoMusicos;
    _cidadeController.text = provider.cidadeFiltroMusicos ?? '';
    _pesquisaController.text = provider.termoPesquisa;
    _tipoOrdenacao = provider.tipoOrdenacao;
    _livresEm = provider.livresEm;
  }

  Future<void> _escolherDia() async {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final atual = _livresEm;
    final escolhida = await showDatePicker(
      context: context,
      helpText: 'Músicos livres em',
      initialDate: atual != null && !atual.isBefore(hoje) ? atual : hoje,
      firstDate: hoje,
      lastDate: DateTime(hoje.year + 2),
    );
    if (escolhida != null) setState(() => _livresEm = escolhida);
  }

  @override
  void dispose() {
    _cidadeController.dispose();
    _pesquisaController.dispose();
    super.dispose();
  }

  void _aplicarFiltro() {
    final provider = context.read<OportunidadeProvider>();

    provider.filtrarMusicos(
      genero: _generoSelecionado,
      cidade: _cidadeController.text.trim(),
    );
    provider.pesquisarMusicos(_pesquisaController.text.trim());
    provider.ordenarMusicos(_tipoOrdenacao);
    if (provider.livresEm != _livresEm) {
      provider.filtrarMusicosLivresEm(_livresEm);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filtro aplicado com sucesso.')),
    );

    Navigator.pushNamed(context, AppRoutes.listaMusicos);
  }

  void _limparFiltro() {
    final provider = context.read<OportunidadeProvider>();

    provider.resetarFiltroMusicos();

    setState(() {
      _generoSelecionado = null;
      _cidadeController.clear();
      _pesquisaController.clear();
      _tipoOrdenacao = 'nome_asc';
      _livresEm = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Filtros resetados.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Filtro de busca')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _pesquisaController,
                decoration: const InputDecoration(
                  labelText: 'Pesquisar artista',
                  hintText: 'Digite nome ou descrição',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _generoSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Gênero musical',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String>(value: '', child: Text('Todos')),
                  ...AppStrings.generosMusicais.map(
                    (genero) => DropdownMenuItem<String>(
                      value: genero,
                      child: Text(genero),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _generoSelecionado = (value == null || value.isEmpty)
                        ? null
                        : value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _cidadeController,
                decoration: const InputDecoration(
                  labelText: 'Cidade',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Livres em',
                  helperText: 'Sem bloqueio na agenda e sem show confirmado',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: _escolherDia,
                        icon: const Icon(Icons.event_available),
                        label: Text(
                          _livresEm == null
                              ? 'Qualquer data'
                              : formatarData(_livresEm!),
                        ),
                      ),
                    ),
                    if (_livresEm != null)
                      IconButton(
                        tooltip: 'Tirar a data',
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _livresEm = null),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _tipoOrdenacao,
                decoration: const InputDecoration(
                  labelText: 'Ordenar por',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem<String>(
                    value: 'nome_asc',
                    child: Text('Nome (A-Z)'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'nome_desc',
                    child: Text('Nome (Z-A)'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'cache_maior',
                    child: Text('Cache (Maior primeiro)'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'cache_menor',
                    child: Text('Cache (Menor primeiro)'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _tipoOrdenacao = value ?? 'nome_asc';
                  });
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _aplicarFiltro,
                  child: const Text('Aplicar filtro'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _limparFiltro,
                  child: const Text('Limpar filtro'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
