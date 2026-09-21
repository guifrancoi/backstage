import 'package:flutter/material.dart';

class SobreScreen extends StatelessWidget {
  const SobreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: const [
            Text(
              'Backstage',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Objetivo do aplicativo:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Nosso objetivo é criar uma plataforma que conecte músicos e casas de'
              'show de forma eficiente, automatizando a busca e a seleção por meio de filtros e'
              'recomendação inteligente. Busca-se oferecer um ambiente centralizado para divulgação de'
              'portfólios, consulta de agendas, negociação via chat e identificação de oportunidades'
              'compatíveis, reduzindo o tempo gasto em processos manuais e aumentando a probabilidade'
              'de contratação para ambos os lados.'
              'Além disso, o sistema pretende profissionalizar o relacionamento entre artistas e'
              'estabelecimentos, entregando uma ferramenta acessível, prática e economicamente viável,'
              'capaz de melhorar a organização, a visibilidade e a produtividade do setor musical independente.',
            ),
            SizedBox(height: 16),
            Text(
              'Equipe de desenvolvimento:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• Guilherme Francoi'),
            Text('• Marco A. Lonardon Jr.'),
            Text('• Victor Vicentini'),
            SizedBox(height: 16),
            Text('Disciplina: Desenvolvimento Mobile'),
            Text('Instituição: Unaerp'),
            Text('Professor: Rodrigo Plotze'),
            Text('Versão: 1.0.0'),
          ],
        ),
      ),
    );
  }
}
