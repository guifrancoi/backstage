import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Link de portfólio dos protótipos (Plano 8): ícone pelo site, o link e
/// "abrir fora". Abre no app externo e avisa com SnackBar se falhar.
class LinkPortfolio extends StatelessWidget {
  const LinkPortfolio(this.link, {super.key});

  final String link;

  /// Completa o esquema (`instagram.com/x` → `https://instagram.com/x`).
  static Uri? uriDe(String link) {
    final texto = link.trim();
    if (texto.isEmpty) return null;
    final completo = texto.startsWith('http://') || texto.startsWith('https://')
        ? texto
        : 'https://$texto';
    final uri = Uri.tryParse(completo);
    return uri == null || uri.host.isEmpty ? null : uri;
  }

  /// Ícone pelo endereço (Instagram, YouTube, Spotify, SoundCloud...).
  static IconData iconeDe(String link) {
    final host = uriDe(link)?.host.toLowerCase() ?? '';
    if (host.contains('instagram')) return Icons.camera_alt_outlined;
    if (host.contains('youtu')) return Icons.smart_display_outlined;
    if (host.contains('spotify') ||
        host.contains('deezer') ||
        host.contains('soundcloud')) {
      return Icons.headphones_outlined;
    }
    return Icons.link;
  }

  Future<void> _abrir(BuildContext context) async {
    final uri = uriDe(link);
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Link inválido.')));
      return;
    }
    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abriu && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        leading: Icon(iconeDe(link), color: AppColors.primariaTexto),
        title: Text(link, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () => _abrir(context),
      ),
    );
  }
}
