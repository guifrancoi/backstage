import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_logo.dart';

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
      home: Builder(
        builder: (context) {
          final texto = Theme.of(context).textTheme;
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppLogo(compacto: true),
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: AppColors.erroFundo,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_off_outlined,
                            size: 30,
                            color: AppColors.erro,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Não foi possível conectar ao Backstage',
                          textAlign: TextAlign.center,
                          style: texto.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Verifique sua conexão com a internet e tente '
                          'novamente.',
                          textAlign: TextAlign.center,
                          style: texto.bodyMedium?.copyWith(
                            color: AppColors.textoSecundario,
                          ),
                        ),
                        if (faltaConfiguracao) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Nesta plataforma o Firebase precisa das chaves '
                            'via --dart-define (veja o CLAUDE.md da raiz).',
                            textAlign: TextAlign.center,
                            style: texto.bodySmall,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _tentando ? null : _tentarNovamente,
                            icon: const Icon(Icons.refresh),
                            label: Text(
                              _tentando ? 'Conectando...' : 'Tentar novamente',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
