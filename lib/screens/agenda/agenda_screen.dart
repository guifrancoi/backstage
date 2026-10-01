import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/utils/data_hora.dart';
import '../../models/contratacao.dart';
import '../../providers/agenda_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contratacao_provider.dart';
import '../contratacoes/contratacoes_screen.dart';

/// Marcações de um dia no calendário.
/// Todo dia é livre por padrão (sem marcação).
enum _Marca { bloqueado, proposta, confirmada }

const _cores = {
  _Marca.bloqueado: Colors.grey,
  _Marca.proposta: Colors.orange,
  _Marca.confirmada: Colors.deepPurple,
};

/// Calendário mensal. Músico: todo dia é livre por padrão; ele bloqueia os
/// que não pode e vê propostas e shows confirmados (ocupados). Dono: vê as contratações que propôs. Admin: tudo.
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _focado = DateTime.now();
  DateTime _selecionado = DateTime.now();

  bool _mesmoDia(DateTime a, DateTime b) => isSameDay(a, b);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final agenda = context.watch<AgendaProvider>();
    final contratacoes = context.watch<ContratacaoProvider>();
    final ehMusico = auth.atuaComoMusico;

    // Admin vê tudo; os demais, só o lado do próprio papel.
    final visiveis = auth.isAdmin
        ? contratacoes.todas
        : ehMusico
        ? contratacoes.recebidas
        : contratacoes.enviadas;
    final ativas = visiveis.where((c) => c.ativa).toList();

    List<_Marca> marcas(DateTime dia) {
      final chave = Contratacao.diaDe(dia);
      return [
        if (ehMusico && agenda.bloqueado(dia)) _Marca.bloqueado,
        for (final c in ativas)
          if (c.dia == chave)
            c.status == StatusContratacao.confirmada
                ? _Marca.confirmada
                : _Marca.proposta,
      ];
    }

    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final doDia = ativas
        .where((c) => c.dia == Contratacao.diaDe(_selecionado))
        .toList();
    final bloqueadoNoDia = agenda.bloqueado(_selecionado);
    final podeMarcar = ehMusico && !_selecionado.isBefore(hoje);

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      body: ListView(
        children: [
          TableCalendar<_Marca>(
            locale: 'pt_BR',
            firstDay: DateTime(hoje.year - 1, 1, 1),
            lastDay: DateTime(hoje.year + 3, 12, 31),
            focusedDay: _focado,
            availableCalendarFormats: const {CalendarFormat.month: 'Mês'},
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            selectedDayPredicate: (dia) => _mesmoDia(dia, _selecionado),
            onDaySelected: (selecionado, focado) => setState(() {
              _selecionado = selecionado;
              _focado = focado;
            }),
            onPageChanged: (focado) => _focado = focado,
            eventLoader: marcas,
            calendarBuilders: CalendarBuilders(
              singleMarkerBuilder: (context, dia, marca) => Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _cores[marca],
                ),
              ),
            ),
          ),
          const _Legenda(),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              formatarData(_selecionado),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          if (podeMarcar)
            SwitchListTile(
              title: const Text('Bloquear este dia'),
              subtitle: Text(
                bloqueadoNoDia
                    ? 'Você não aparece como livre neste dia.'
                    : 'Livre para shows (padrão).',
              ),
              value: bloqueadoNoDia,
              onChanged: (bloquear) => bloquear
                  ? agenda.bloquearDia(_selecionado)
                  : agenda.desbloquearDia(_selecionado),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: doDia.isEmpty
                ? const Text(
                    'Nenhum show neste dia.',
                    style: TextStyle(color: Colors.grey),
                  )
                : Column(
                    children: [
                      for (final c in doDia)
                        ContratacaoCard(
                          contratacao: c,
                          souMusico: c.musicoId == auth.userId,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda();

  @override
  Widget build(BuildContext context) {
    Widget item(_Marca marca, String texto) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: _cores[marca]),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontSize: 12)),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          item(_Marca.bloqueado, 'Bloqueado'),
          item(_Marca.proposta, 'Proposta pendente'),
          item(_Marca.confirmada, 'Show confirmado'),
        ],
      ),
    );
  }
}
