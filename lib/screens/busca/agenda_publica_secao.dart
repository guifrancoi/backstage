import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/data_hora.dart';
import '../../models/agenda_publica.dart';
import '../../providers/agenda_provider.dart';
import '../../widgets/etiqueta.dart';

/// Próximos dias em que o músico **não** está livre: com show (`ocupacoes`)
/// ou bloqueados por ele (`bloqueios`). Os demais dias são livres.
class AgendaPublicaSecao extends StatefulWidget {
  const AgendaPublicaSecao({super.key, required this.musicoId});

  final String musicoId;

  @override
  State<AgendaPublicaSecao> createState() => _AgendaPublicaSecaoState();
}

class _AgendaPublicaSecaoState extends State<AgendaPublicaSecao> {
  // Criado uma vez: um stream novo a cada build reiniciaria a leitura.
  late final Stream<AgendaPublica> _agenda = context
      .read<AgendaProvider>()
      .agendaPublica(widget.musicoId);

  /// Só dias de hoje em diante, em ordem.
  List<DateTime> _futuros(Iterable<String> dias) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    return dias
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .where((d) => !d.isBefore(hoje))
        .toList()
      ..sort();
  }

  Widget _linha(String titulo, List<DateTime> dias, TipoEtiqueta tipo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final dia in dias.take(12))
                Etiqueta(formatarData(dia), tipo: tipo),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AgendaPublica>(
      stream: _agenda,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Não foi possível carregar a agenda.');
        }
        final agenda = snapshot.data;
        if (agenda == null) {
          return const LinearProgressIndicator();
        }

        final ocupados = _futuros(agenda.ocupados);
        final bloqueados = _futuros(
          agenda.bloqueados.where((d) => !agenda.ocupado(d)),
        );

        // Plano 8: só as linhas com dias; sem nenhum, uma frase só.
        final semNada = ocupados.isEmpty && bloqueados.isEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              semNada
                  ? 'Livre em todos os próximos dias.'
                  : 'Livre nos demais dias.',
              style: const TextStyle(color: AppColors.sucesso),
            ),
            if (!semNada) const SizedBox(height: 8),
            if (ocupados.isNotEmpty)
              _linha('Com show', ocupados, TipoEtiqueta.destaque),
            if (bloqueados.isNotEmpty)
              _linha('Bloqueado', bloqueados, TipoEtiqueta.neutra),
          ],
        );
      },
    );
  }
}
