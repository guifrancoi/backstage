import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/titulo_secao.dart';

/// Sobre o app (Plano 8): logo, objetivo, equipe e dados do projeto.
class SobreScreen extends StatelessWidget {
  const SobreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    const espaco = SizedBox(height: AppSpacing.sm);

    return Scaffold(
      appBar: AppBar(title: const Text('Sobre')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        children: [
          const Center(child: AppLogo()),
          const SizedBox(height: AppSpacing.lg),
          const CardSecao(
            titulo: 'Objetivo do aplicativo',
            child: Text(
              'Nosso objetivo é criar uma plataforma que conecte músicos e '
              'casas de show de forma eficiente, automatizando a busca e a '
              'seleção por meio de filtros e recomendação inteligente. '
              'Busca-se oferecer um ambiente centralizado para divulgação de '
              'portfólios, consulta de agendas, negociação via chat e '
              'identificação de oportunidades compatíveis, reduzindo o tempo '
              'gasto em processos manuais e aumentando a probabilidade de '
              'contratação para ambos os lados. Além disso, o sistema '
              'pretende profissionalizar o relacionamento entre artistas e '
              'estabelecimentos, entregando uma ferramenta acessível, prática '
              'e economicamente viável, capaz de melhorar a organização, a '
              'visibilidade e a produtividade do setor musical independente.',
            ),
          ),
          espaco,
          const CardSecao(
            titulo: 'Equipe de desenvolvimento',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• Guilherme Francoi'),
                Text('• Marco A. Lonardon Jr.'),
                Text('• Victor Vicentini'),
              ],
            ),
          ),
          espaco,
          CardSecao(
            titulo: 'Projeto',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (rotulo, valor) in const [
                  ('Disciplina', 'Desenvolvimento Mobile'),
                  ('Instituição', 'Unaerp'),
                  ('Professor', 'Rodrigo Plotze'),
                  ('Versão', '1.0.0'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '$rotulo: ', style: texto.bodySmall),
                          TextSpan(text: valor),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
