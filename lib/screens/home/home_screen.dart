import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/lembrete_show.dart';
import '../../core/utils/painel_numeros.dart';
import '../../widgets/grafico_shows_por_mes.dart' show resumoNumeros;
import '../../providers/auth_provider.dart';
import '../../providers/avaliacao_provider.dart';
import '../../providers/contratacao_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/notificacao_provider.dart';
import '../../routes/app_routes.dart';
import 'oportunidades_para_voce.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final pendentes = context.watch<InteresseProvider>().pendentesRecebidos;
    final propostas = context.watch<ContratacaoProvider>().propostasPendentes;
    final naoLidas = context.watch<NotificacaoProvider>().naoLidas;
    final mensagensNaoLidas = context.watch<ChatProvider>().totalNaoLidas;
    final ehDono = authProvider.atuaComoDono;
    // Plano 17: shows realizados ainda sem a avaliação do usuário.
    final contratacoes = context.watch<ContratacaoProvider>().todas;
    final paraAvaliar = context.watch<AvaliacaoProvider>().paraAvaliar(
      contratacoes,
    );
    // Plano 19: shows confirmados de hoje e amanhã (nada é gravado).
    final uid = authProvider.userId;
    final lembretes = uid == null
        ? const <LembreteShow>[]
        : lembretesDeShow(contratacoes, uid: uid, agora: DateTime.now());
    // Plano 20: resumo do lado principal (músico, se atua como músico).
    final agora = DateTime.now();
    final avaliacao = uid == null
        ? null
        : context.watch<AvaliacaoProvider>().resumoDe(uid);
    final resumo = uid == null
        ? null
        : resumoNumeros(
            calcularNumeros(
              contratacoes,
              uid: uid,
              comoMusico: authProvider.atuaComoMusico,
              agora: agora,
            ),
            agora.year,
            avaliacao: avaliacao != null && avaliacao.temAvaliacao
                ? avaliacao.rotuloCurto
                : null,
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backstage'),
        actions: [
          IconButton(
            tooltip: 'Notificações',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.notificacoes),
            icon: Badge(
              isLabelVisible: naoLidas > 0,
              label: Text('$naoLidas'),
              child: const Icon(Icons.notifications),
            ),
          ),
          IconButton(
            onPressed: () async {
              await authProvider.logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Bem-vindo, ${authProvider.userEmail ?? 'usuário'}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          for (final lembrete in lembretes)
            Card(
              color: lembrete.hoje
                  ? Colors.deepPurple.shade50
                  : Colors.blueGrey.shade50,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(
                  lembrete.hoje ? Icons.music_note : Icons.event,
                  color: Colors.deepPurple,
                ),
                title: Text(
                  lembrete.titulo,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(lembrete.detalhe),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.contratacoes),
              ),
            ),
          if (paraAvaliar.isNotEmpty)
            Card(
              color: Colors.amber.shade50,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: Text(
                  paraAvaliar.length == 1
                      ? 'Você tem 1 show para avaliar'
                      : 'Você tem ${paraAvaliar.length} shows para avaliar',
                ),
                subtitle: const Text('Até 30 dias depois do show.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.contratacoes),
              ),
            ),
          if (authProvider.atuaComoMusico) const OportunidadesParaVoce(),
          _HomeTile(
            title: 'Perfil',
            icon: Icons.person,
            onTap: () => Navigator.pushNamed(context, AppRoutes.perfil),
          ),
          _HomeTile(
            title: 'Lista de músicos',
            icon: Icons.library_music,
            onTap: () => Navigator.pushNamed(context, AppRoutes.listaMusicos),
          ),
          _HomeTile(
            title: 'Lista de oportunidades',
            icon: Icons.event,
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.listaOportunidades),
          ),
          if (ehDono)
            _HomeTile(
              title: 'Minhas oportunidades',
              icon: Icons.storefront,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.minhasOportunidades),
            ),
          _HomeTile(
            title: 'Interesses',
            icon: Icons.favorite,
            contador: pendentes,
            onTap: () => Navigator.pushNamed(context, AppRoutes.interesses),
          ),
          _HomeTile(
            title: 'Contratações',
            icon: Icons.handshake,
            contador: propostas,
            onTap: () => Navigator.pushNamed(context, AppRoutes.contratacoes),
          ),
          _HomeTile(
            title: 'Meus números',
            icon: Icons.bar_chart,
            subtitle: resumo,
            onTap: () => Navigator.pushNamed(context, AppRoutes.meusNumeros),
          ),
          _HomeTile(
            title: 'Agenda',
            icon: Icons.calendar_month,
            onTap: () => Navigator.pushNamed(context, AppRoutes.agenda),
          ),
          _HomeTile(
            title: 'Conversas',
            icon: Icons.chat,
            contador: mensagensNaoLidas,
            onTap: () => Navigator.pushNamed(context, AppRoutes.conversas),
          ),
          _HomeTile(
            title: 'Sobre',
            icon: Icons.info,
            onTap: () => Navigator.pushNamed(context, AppRoutes.sobre),
          ),
        ],
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  /// Quantidade de itens pendentes; 0 esconde o selo.
  final int contador;

  /// Linha de resumo embaixo do título (ex.: "Meus números").
  final String? subtitle;

  const _HomeTile({
    required this.title,
    required this.icon,
    required this.onTap,
    this.contador = 0,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Badge(
          isLabelVisible: contador > 0,
          label: Text('$contador'),
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}
