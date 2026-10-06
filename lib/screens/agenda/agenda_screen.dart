import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/data_hora.dart';
import '../../models/contratacao.dart';
import '../../providers/agenda_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contratacao_provider.dart';
import '../../widgets/etiqueta.dart';
import '../../widgets/titulo_secao.dart';
import '../contratacoes/contratacoes_screen.dart';
import '../contratacoes/status_contratacao.dart';

/// Marcações de um dia no calendário, da mais forte para a mais fraca.
/// Todo dia é livre por padrão (sem marcação).
enum _Marca { confirmada, proposta, bloqueado }

/// Cor de fundo da célula e do texto do dia, pela marcação mais forte.
const _fundos = {
  _Marca.confirmada: AppColors.sucessoFundo,
  _Marca.proposta: AppColors.avisoFundo,
  _Marca.bloqueado: AppColors.superficieAlta,
};
const _textos = {
  _Marca.confirmada: AppColors.sucesso,
  _Marca.proposta: AppColors.aviso,
  _Marca.bloqueado: AppColors.textoTerciario,
};

/// Agenda (protótipo, Plano 8): calendário com os dias marcados por cor
/// (show confirmado, proposta, bloqueado), o dia escolhido com o switch de
/// bloqueio (músico) e os shows dele, e os próximos eventos. Músico: todo
/// dia é livre por padrão; ele bloqueia os que não pode. Dono: vê as
/// contratações que propôs. Admin: tudo.
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _focado = DateTime.now();
  DateTime _selecionado = DateTime.now();

  void _selecionar(DateTime dia) => setState(() {
    _selecionado = dia;
    _focado = dia;
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final agenda = context.watch<AgendaProvider>();
    final contratacoes = context.watch<ContratacaoProvider>();
    final ehMusico = auth.atuaComoMusico;
    final texto = Theme.of(context).textTheme;

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
        for (final c in ativas)
          if (c.dia == chave)
            c.status == StatusContratacao.confirmada
                ? _Marca.confirmada
                : _Marca.proposta,
        if (ehMusico && agenda.bloqueado(dia)) _Marca.bloqueado,
      ]..sort((a, b) => a.index.compareTo(b.index));
    }

    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final doDia = ativas
        .where((c) => c.dia == Contratacao.diaDe(_selecionado))
        .toList();
    final bloqueadoNoDia = agenda.bloqueado(_selecionado);
    final podeMarcar = ehMusico && !_selecionado.isBefore(hoje);
    // Os do dia escolhido já aparecem logo acima (sem repetir).
    final proximos =
        ativas
            .where(
              (c) =>
                  !c.data.isBefore(hoje) &&
                  c.dia != Contratacao.diaDe(_selecionado),
            )
            .toList()
          ..sort((a, b) => a.dia.compareTo(b.dia));

    /// Célula do dia: fundo pela marcação mais forte (protótipo).
    Widget celula(DateTime dia, {bool hojeDia = false, bool fora = false}) {
      final lista = marcas(dia);
      final marca = lista.isEmpty ? null : lista.first;
      return Container(
        margin: const EdgeInsets.all(3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fora ? null : _fundos[marca],
          borderRadius: AppRadius.circular(AppRadius.md),
          border: hojeDia
              ? Border.all(color: AppColors.primaria, width: 1.5)
              : null,
        ),
        child: Text(
          '${dia.day}',
          style: texto.bodyMedium?.copyWith(
            color: fora
                ? AppColors.textoTerciario
                : (_textos[marca] ?? AppColors.texto),
            fontWeight: marca == null && !hojeDia
                ? FontWeight.w400
                : FontWeight.w700,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                0,
                AppSpacing.xs,
                AppSpacing.xs,
              ),
              child: TableCalendar<_Marca>(
                locale: 'pt_BR',
                firstDay: DateTime(hoje.year - 1, 1, 1),
                lastDay: DateTime(hoje.year + 3, 12, 31),
                focusedDay: _focado,
                availableCalendarFormats: const {CalendarFormat.month: 'Mês'},
                rowHeight: 46,
                daysOfWeekHeight: 28,
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: texto.titleMedium!,
                  leftChevronIcon: const Icon(
                    Icons.chevron_left,
                    color: AppColors.primariaTexto,
                  ),
                  rightChevronIcon: const Icon(
                    Icons.chevron_right,
                    color: AppColors.primariaTexto,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: texto.labelSmall!,
                  weekendStyle: texto.labelSmall!,
                ),
                selectedDayPredicate: (dia) => isSameDay(dia, _selecionado),
                onDaySelected: (selecionado, focado) => setState(() {
                  _selecionado = selecionado;
                  _focado = focado;
                }),
                onPageChanged: (focado) => _focado = focado,
                eventLoader: marcas,
                // O table_calendar não lê o tema: células no estilo do
                // protótipo (quadrado arredondado colorido pela marcação).
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, dia, _) => celula(dia),
                  todayBuilder: (context, dia, _) => celula(dia, hojeDia: true),
                  outsideBuilder: (context, dia, _) => celula(dia, fora: true),
                  selectedBuilder: (context, dia, _) => Container(
                    margin: const EdgeInsets.all(3),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaria,
                      borderRadius: AppRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      '${dia.day}',
                      style: texto.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // As cores das células já dizem tudo: sem pontinhos.
                  markerBuilder: (context, dia, eventos) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          const _Legenda(),
          const SizedBox(height: AppSpacing.sm),
          TituloSecao(formatarData(_selecionado)),
          if (podeMarcar)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SwitchListTile(
                secondary: Icon(
                  bloqueadoNoDia ? Icons.block : Icons.event_available,
                  color: bloqueadoNoDia
                      ? AppColors.textoSecundario
                      : AppColors.sucesso,
                ),
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
            ),
          if (doDia.isEmpty)
            Text(
              'Nenhum show neste dia.',
              style: texto.bodyMedium?.copyWith(
                color: AppColors.textoSecundario,
              ),
            )
          else
            for (final c in doDia)
              ContratacaoCard(
                contratacao: c,
                souMusico: c.musicoId == auth.userId,
              ),
          if (proximos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const TituloSecao('Próximos eventos'),
            for (final c in proximos.take(5))
              _ProximoEvento(contratacao: c, onTap: () => _selecionar(c.data)),
          ],
        ],
      ),
    );
  }
}

/// Linha de "Próximos eventos" (protótipo): selo com dia e mês, título,
/// local · horário e o status. Tocar leva o calendário até o dia.
class _ProximoEvento extends StatelessWidget {
  const _ProximoEvento({required this.contratacao, required this.onTap});

  final Contratacao contratacao;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = contratacao;
    final texto = Theme.of(context).textTheme;
    final tipo = tipoEtiquetaContratacao(c);
    final confirmada = tipo == TipoEtiqueta.sucesso;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: InkWell(
        borderRadius: AppRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: confirmada
                      ? AppColors.sucessoFundo
                      : AppColors.primariaContainer,
                  borderRadius: AppRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    Text(
                      '${c.data.day}',
                      style: texto.titleLarge?.copyWith(
                        color: confirmada
                            ? AppColors.sucesso
                            : AppColors.primariaTexto,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      mesAbreviado(c.data).toUpperCase(),
                      style: texto.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.titulo,
                      style: texto.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${c.cidade} · ${c.horaInicio}',
                      style: texto.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Etiqueta(c.rotuloStatus, tipo: tipo),
            ],
          ),
        ),
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
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _fundos[marca],
            borderRadius: AppRadius.circular(3),
            border: Border.all(color: _textos[marca]!),
          ),
        ),
        const SizedBox(width: 6),
        Text(texto, style: Theme.of(context).textTheme.bodySmall),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xxs,
        children: [
          item(_Marca.confirmada, 'Show confirmado'),
          item(_Marca.proposta, 'Proposta pendente'),
          item(_Marca.bloqueado, 'Bloqueado'),
        ],
      ),
    );
  }
}
