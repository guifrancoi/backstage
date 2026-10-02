import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/botao_favorito.dart';
import 'abrir_mapa.dart';
import 'acoes_interesse.dart';
import 'musicos_sugeridos_secao.dart';

class DetalheOportunidadeScreen extends StatefulWidget {
  final String oportunidadeId;

  const DetalheOportunidadeScreen({super.key, required this.oportunidadeId});

  @override
  State<DetalheOportunidadeScreen> createState() =>
      _DetalheOportunidadeScreenState();
}

class _DetalheOportunidadeScreenState extends State<DetalheOportunidadeScreen> {
  bool _carregandoMapa = false;

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  Future<void> _abrirMapa({
    required String logradouro,
    required String numero,
    required String cidade,
    required String estado,
    String? cep,
  }) async {
    setState(() => _carregandoMapa = true);
    try {
      await abrirMapa(
        context,
        logradouro: logradouro,
        numero: numero,
        cidade: cidade,
        estado: estado,
        cep: cep,
      );
    } finally {
      if (mounted) setState(() => _carregandoMapa = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OportunidadeProvider>();
    final auth = context.watch<AuthProvider>();
    final interesses = context.watch<InteresseProvider>();
    final oportunidade =
        provider.buscarOportunidadePorId(widget.oportunidadeId);

    if (oportunidade == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes da oportunidade')),
        body: const Center(child: Text('Oportunidade não encontrada.')),
      );
    }

    final pode = podeCandidatar(auth, oportunidade);
    final candidatura = interesses.candidaturaPara(oportunidade.id);

    final temEndereco = oportunidade.logradouro.isNotEmpty &&
        oportunidade.numero.isNotEmpty &&
        oportunidade.estado.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da oportunidade'),
        actions: [
          if (podeFavoritarOportunidade(auth, oportunidade))
            BotaoFavorito(
              favorito: provider.ehOportunidadeFavorita(oportunidade.id),
              onPressed: () => alternarFavorito(
                context,
                (p) => p.alternarOportunidadeFavorita(oportunidade.id),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (oportunidade.vencida) ...[
                    const Chip(
                      avatar: Icon(Icons.event_busy, size: 18),
                      label: Text('Evento encerrado'),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    oportunidade.titulo,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (oportunidade.temDono)
                    // Plano 16: o contratante abre o perfil do estabelecimento.
                    InkWell(
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.detalheEstabelecimento,
                        arguments: oportunidade.donoId,
                      ),
                      child: Text.rich(
                        TextSpan(
                          text: 'Contratante: ',
                          children: [
                            TextSpan(
                              text: oportunidade.contratante,
                              style: const TextStyle(
                                color: Colors.deepPurple,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Text('Contratante: ${oportunidade.contratante}'),
                  const SizedBox(height: 8),
                  const Text(
                    'Localização',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  if (temEndereco) ...[
                    Text(
                      '${oportunidade.logradouro}, ${oportunidade.numero}',
                    ),
                    Text(
                      '${oportunidade.cidade} — ${oportunidade.estado}'
                      '${oportunidade.cep != null ? '  CEP: ${oportunidade.cep}' : ''}',
                    ),
                  ] else
                    Text(oportunidade.cidade),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _carregandoMapa
                          ? null
                          : () => _abrirMapa(
                                logradouro: oportunidade.logradouro,
                                numero: oportunidade.numero,
                                cidade: oportunidade.cidade,
                                estado: oportunidade.estado,
                                cep: oportunidade.cep,
                              ),
                      icon: _carregandoMapa
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.map_outlined),
                      label: const Text('Ver no mapa'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Gênero musical: ${oportunidade.generoMusical}'),
                  const SizedBox(height: 8),
                  Text(
                    'Data do evento: ${_formatarData(oportunidade.dataEvento)}',
                  ),
                  if (oportunidade.horario.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Horário: ${oportunidade.horario}'),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Cachê oferecido: R\$ ${oportunidade.cacheOferecido.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Descrição',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(oportunidade.descricao),
                ],
              ),
            ),
          ),
          if (pode) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: candidatura == null
                    ? () => confirmarCandidatura(context, oportunidade)
                    : null,
                icon: const Icon(Icons.send_outlined),
                label: Text(candidatura?.rotuloStatus ?? 'Candidatar-se'),
              ),
            ),
          ],
          // Atalho do dono (Plano 13): quem pode tocar nesse dia.
          if (podeGerenciar(auth, oportunidade) &&
              auth.atuaComoDono &&
              !oportunidade.vencida) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  provider.filtrarMusicosLivresEm(oportunidade.dataEvento);
                  Navigator.pushNamed(context, AppRoutes.listaMusicos);
                },
                icon: const Icon(Icons.event_available),
                label: const Text('Ver músicos livres neste dia'),
              ),
            ),
            const SizedBox(height: 20),
            MusicosSugeridosSecao(oportunidade: oportunidade),
          ],
          if (podeGerenciar(auth, oportunidade)) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final removeu = await confirmarRemocao(
                        context,
                        oportunidade,
                      );
                      if (removeu && context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remover'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.editarOportunidade,
                      arguments: oportunidade.id,
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
