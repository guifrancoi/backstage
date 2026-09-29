import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/contratacao_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/notificacao_provider.dart';
import '../../routes/app_routes.dart';

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
            title: 'Filtro de busca',
            icon: Icons.filter_list,
            onTap: () => Navigator.pushNamed(context, AppRoutes.filtroBusca),
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

  const _HomeTile({
    required this.title,
    required this.icon,
    required this.onTap,
    this.contador = 0,
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
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}
