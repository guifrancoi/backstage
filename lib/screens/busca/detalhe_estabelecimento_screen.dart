import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/casa_show.dart';
import '../../providers/auth_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../providers/perfil_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/musico_card.dart' show SeloAssinante;
import '../../widgets/oportunidade_card.dart';
import 'abrir_mapa.dart';
import 'acoes_interesse.dart';
import 'avaliacoes_secao.dart';

/// Perfil público do estabelecimento (Plano 16): endereço com mapa,
/// capacidade, estilos, descrição e as oportunidades abertas do dono.
/// Contato e CNPJ só aparecem para o dono e para quem já conversa com ele
/// (as regras não deixam os outros lerem `privado/dados`).
class DetalheEstabelecimentoScreen extends StatefulWidget {
  const DetalheEstabelecimentoScreen({super.key, required this.donoId});

  final String donoId;

  @override
  State<DetalheEstabelecimentoScreen> createState() =>
      _DetalheEstabelecimentoScreenState();
}

class _DetalheEstabelecimentoScreenState
    extends State<DetalheEstabelecimentoScreen> {
  late final Future<CasaShow?> _estabelecimento = context
      .read<PerfilProvider>()
      .estabelecimentoPublico(widget.donoId);
  bool _carregandoMapa = false;

  Future<void> _verNoMapa(CasaShow casa) async {
    setState(() => _carregandoMapa = true);
    try {
      await abrirMapa(
        context,
        logradouro: casa.logradouro,
        numero: casa.numero,
        cidade: casa.cidade,
        estado: casa.estado,
        cep: casa.cep,
      );
    } finally {
      if (mounted) setState(() => _carregandoMapa = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estabelecimento')),
      body: FutureBuilder<CasaShow?>(
        future: _estabelecimento,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _Mensagem(
              'Não foi possível carregar o estabelecimento. '
              'Verifique sua conexão.',
            );
          }
          final auth = context.watch<AuthProvider>();
          final casa = snapshot.data;
          // Perfil oculto (conta admin) só aparece para o admin.
          if (casa != null && casa.oculto && !auth.isAdmin) {
            return const _Mensagem('Estabelecimento não encontrado.');
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (casa == null)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Este estabelecimento ainda não completou o perfil.',
                    ),
                  ),
                )
              else
                _dados(context, casa, ehDono: auth.userId == widget.donoId),
              const SizedBox(height: 24),
              _OportunidadesAbertas(donoId: widget.donoId),
            ],
          );
        },
      ),
    );
  }

  Widget _dados(BuildContext context, CasaShow casa, {required bool ehDono}) {
    final assinante = context.watch<OportunidadeProvider>().ehAssinante(
      widget.donoId,
    );
    final temEndereco =
        casa.logradouro.isNotEmpty &&
        casa.numero.isNotEmpty &&
        casa.estado.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    casa.nome,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (assinante) ...[
                  const SizedBox(width: 8),
                  const SeloAssinante(),
                ],
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Localização',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            if (temEndereco) ...[
              Text('${casa.logradouro}, ${casa.numero}'),
              Text(
                '${casa.cidade} — ${casa.estado}'
                '${casa.cep != null ? '  CEP: ${casa.cep}' : ''}',
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _carregandoMapa ? null : () => _verNoMapa(casa),
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
            ] else
              Text(casa.cidade),
            if (casa.capacidade > 0) ...[
              const SizedBox(height: 12),
              Text('Capacidade: ${casa.capacidade} pessoas'),
            ],
            if (casa.estilosDesejados.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Estilos que procura',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final estilo in casa.estilosDesejados)
                    Chip(
                      label: Text(estilo),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
            if (casa.descricao.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Descrição',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(casa.descricao),
            ],
            const SizedBox(height: 16),
            AvaliacoesSecao(uid: widget.donoId),
            const SizedBox(height: 16),
            const Text(
              'Contato',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            if (casa.contato.isNotEmpty) ...[
              Text(casa.contato),
              if (casa.cnpj.isNotEmpty) Text('CNPJ: ${casa.cnpj}'),
            ] else
              Text(
                ehDono
                    ? 'Você ainda não informou o contato.'
                    : 'Contato e CNPJ são liberados depois de um interesse '
                          'aceito entre vocês.',
                style: const TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}

/// Oportunidades futuras do dono (sem as ocultas, exceto para o admin).
class _OportunidadesAbertas extends StatelessWidget {
  const _OportunidadesAbertas({required this.donoId});

  final String donoId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OportunidadeProvider>();
    final auth = context.watch<AuthProvider>();
    final interesses = context.watch<InteresseProvider>();
    final abertas = provider
        .minhasOportunidades(donoId)
        .where((o) => !o.vencida && (!o.oculto || auth.isAdmin))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          abertas.isEmpty
              ? 'Nenhuma oportunidade aberta'
              : 'Oportunidades abertas (${abertas.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        for (final oportunidade in abertas)
          OportunidadeCard(
            oportunidade: oportunidade,
            assinante: provider.ehAssinante(donoId),
            favorita: provider.ehOportunidadeFavorita(oportunidade.id),
            onFavoritar: podeFavoritarOportunidade(auth, oportunidade)
                ? () => alternarFavorito(
                    context,
                    (p) => p.alternarOportunidadeFavorita(oportunidade.id),
                  )
                : null,
            onCandidatar: podeCandidatar(auth, oportunidade)
                ? () => confirmarCandidatura(context, oportunidade)
                : null,
            statusCandidatura: podeCandidatar(auth, oportunidade)
                ? interesses.candidaturaPara(oportunidade.id)?.rotuloStatus
                : null,
            onVerDetalhes: () => Navigator.pushNamed(
              context,
              AppRoutes.detalheOportunidade,
              arguments: oportunidade.id,
            ),
          ),
      ],
    );
  }
}

class _Mensagem extends StatelessWidget {
  const _Mensagem(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(texto, textAlign: TextAlign.center),
      ),
    );
  }
}
