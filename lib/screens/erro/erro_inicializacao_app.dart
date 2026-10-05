import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// App mínimo mostrado quando o Firebase não inicializa. Substitui o antigo
/// modo mock: sem Firebase o Backstage não tem o que mostrar.
class ErroInicializacaoApp extends StatefulWidget {
  const ErroInicializacaoApp({super.key, required this.onTentarNovamente});

  /// Tenta inicializar de novo; o `main` troca para o app em caso de sucesso.
  final Future<void> Function() onTentarNovamente;

  @override
  State<ErroInicializacaoApp> createState() => _ErroInicializacaoAppState();
}

class _ErroInicializacaoAppState extends State<ErroInicializacaoApp> {
  bool _tentando = false;

  Future<void> _tentarNovamente() async {
    setState(() => _tentando = true);
    await widget.onTentarNovamente();
    if (mounted) setState(() => _tentando = false);
  }

  @override
  Widget build(BuildContext context) {
    // Em Web/desktop sem --dart-define tentar de novo não resolve: avisa o
    // desenvolvedor (só em debug) do que falta.
    final faltaConfiguracao =
        kDebugMode && !FirebaseBootstrap.temConfiguracaoNativa;

    return MaterialApp(
      title: 'Backstage',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.escuro,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: AppColors.textoSecundario),
                  const SizedBox(height: 16),
                  const Text(
                    'Não foi possível conectar ao Backstage',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Verifique sua conexão com a internet e tente novamente.',
                    textAlign: TextAlign.center,
                  ),
                  if (faltaConfiguracao) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Nesta plataforma o Firebase precisa das chaves via '
                      '--dart-define (veja o CLAUDE.md da raiz).',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textoSecundario),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _tentando ? null : _tentarNovamente,
                    icon: const Icon(Icons.refresh),
                    label: Text(_tentando ? 'Conectando...' : 'Tentar novamente'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
