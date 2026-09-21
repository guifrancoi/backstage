import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backstage'),
        actions: [
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
            title: 'Meus artistas de interesse',
            icon: Icons.star,
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.meusArtistasInteresse),
          ),
          _HomeTile(
            title: 'Lista de oportunidades',
            icon: Icons.event,
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.listaOportunidades),
          ),
          _HomeTile(
            title: 'Meus interesses',
            icon: Icons.favorite,
            onTap: () => Navigator.pushNamed(context, AppRoutes.meusInteresses),
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

  const _HomeTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}
