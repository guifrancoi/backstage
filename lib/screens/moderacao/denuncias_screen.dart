import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/data_hora.dart';
import '../../models/denuncia.dart';
import '../../providers/denuncia_provider.dart';

/// Denúncias recebidas (Plano 22) — só a conta admin chega aqui. Filtra
/// Pendentes/Analisadas e marca como analisada.
class DenunciasScreen extends StatefulWidget {
  const DenunciasScreen({super.key});

  @override
  State<DenunciasScreen> createState() => _DenunciasScreenState();
}

class _DenunciasScreenState extends State<DenunciasScreen> {
  bool _analisadas = false;

  Future<void> _marcar(Denuncia denuncia) async {
    final provider = context.read<DenunciaProvider>();
    final ok = await provider.marcarAnalisada(denuncia);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Não foi possível.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DenunciaProvider>();
    final lista = provider.denuncias
        .where((d) => d.analisada == _analisadas)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Denúncias')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text('Pendentes (${provider.pendentes})'),
                ),
                const ButtonSegment(value: true, label: Text('Analisadas')),
              ],
              selected: {_analisadas},
              onSelectionChanged: (s) => setState(() => _analisadas = s.first),
            ),
          ),
          Expanded(
            child: lista.isEmpty
                ? Center(
                    child: Text(
                      _analisadas
                          ? 'Nenhuma denúncia analisada.'
                          : 'Nenhuma denúncia pendente.',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: lista.length,
                    itemBuilder: (context, index) {
                      final d = lista[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${d.tipoAlvo.rotulo} · ${d.motivo.rotulo}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('"${d.descricaoAlvo}"'),
                              if (d.texto.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('Detalhes: ${d.texto}'),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                'Por ${d.autorNome} em ${formatarData(d.criadaEm)}'
                                ' · alvo ${d.alvoUid}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              if (!d.analisada)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => _marcar(d),
                                    icon: const Icon(Icons.check),
                                    label: const Text('Marcar como analisada'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
