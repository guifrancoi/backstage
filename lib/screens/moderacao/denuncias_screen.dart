import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/data_hora.dart';
import '../../models/denuncia.dart';
import '../../providers/denuncia_provider.dart';
import '../../widgets/estados.dart';
import '../../widgets/etiqueta.dart';

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
            padding: const EdgeInsets.all(AppSpacing.md),
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
                ? EstadoVazio(
                    icone: Icons.verified_user_outlined,
                    titulo: _analisadas
                        ? 'Nenhuma denúncia analisada.'
                        : 'Nenhuma denúncia pendente.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.lg,
                    ),
                    itemCount: lista.length,
                    itemBuilder: (context, index) => _CardDenuncia(
                      denuncia: lista[index],
                      onMarcar: () => _marcar(lista[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Uma denúncia: o que foi denunciado, por quê, o trecho e quem denunciou.
class _CardDenuncia extends StatelessWidget {
  const _CardDenuncia({required this.denuncia, required this.onMarcar});

  final Denuncia denuncia;
  final VoidCallback onMarcar;

  @override
  Widget build(BuildContext context) {
    final d = denuncia;
    final texto = Theme.of(context).textTheme;
    final cores = context.cores;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${d.tipoAlvo.rotulo} · ${d.motivo.rotulo}',
                    style: texto.titleSmall,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Etiqueta(
                  d.analisada ? 'Analisada' : 'Pendente',
                  tipo: d.analisada ? TipoEtiqueta.sucesso : TipoEtiqueta.aviso,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            // O trecho denunciado, destacado como citação.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: cores.superficieAlta,
                borderRadius: AppRadius.circular(AppRadius.md),
                border: Border(left: BorderSide(color: cores.erro, width: 3)),
              ),
              child: Text('"${d.descricaoAlvo}"'),
            ),
            if (d.texto.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Detalhes: ${d.texto}', style: texto.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Por ${d.autorNome} em ${formatarData(d.criadaEm)}'
              ' · alvo ${d.alvoUid}',
              style: texto.bodySmall,
            ),
            if (!d.analisada)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onMarcar,
                  icon: const Icon(Icons.check),
                  label: const Text('Marcar como analisada'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
