import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/casa_show.dart';
import '../../models/denuncia.dart';
import '../../providers/auth_provider.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../providers/perfil_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/bloco_info.dart';
import '../../widgets/cabecalho_perfil.dart';
import '../../widgets/estados.dart';
import '../../widgets/etiqueta.dart';
import '../../widgets/musico_card.dart' show InfoComIcone, SeloAssinante;
import '../../widgets/oportunidade_card.dart';
import '../../widgets/titulo_secao.dart';
import '../moderacao/acoes_moderacao.dart';
import 'acoes_interesse.dart';
import 'avaliacoes_secao.dart';
import 'card_local.dart';

/// Perfil público do estabelecimento (Plano 16; visual do Plano 8):
/// cabeçalho em gradiente, capacidade, local com mapa, estilos, sobre,
/// avaliações, contato e as oportunidades abertas do dono. Contato e CNPJ
/// só aparecem para o dono e para quem já conversa com ele (as regras não
/// deixam os outros lerem `privado/dados`).
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CasaShow?>(
      future: _estabelecimento,
      builder: (context, snapshot) {
        final carregou = snapshot.connectionState == ConnectionState.done;
        final auth = context.watch<AuthProvider>();
        var casa = snapshot.data;
        // Perfil oculto (conta admin) só aparece para o admin.
        final oculto = casa != null && casa.oculto && !auth.isAdmin;
        if (oculto) casa = null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Estabelecimento'),
            actions: [
              if (casa != null)
                MenuModeracao(
                  alvoUid: widget.donoId,
                  nome: casa.nome,
                  tipo: TipoAlvoDenuncia.perfil,
                  alvoId: widget.donoId,
                  descricao: casa.nome,
                  rotuloDenuncia: 'Denunciar estabelecimento',
                ),
            ],
          ),
          body: !carregou
              ? const EstadoCarregando()
              : snapshot.hasError
              ? const EstadoErro(
                  mensagem:
                      'Não foi possível carregar o estabelecimento. '
                      'Verifique sua conexão.',
                )
              : oculto
              ? const EstadoVazio(
                  icone: Icons.storefront_outlined,
                  titulo: 'Estabelecimento não encontrado.',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (casa == null)
                        const Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: AppSpacing.card,
                            child: Text(
                              'Este estabelecimento ainda não completou o perfil.',
                            ),
                          ),
                        )
                      else
                        ..._dados(
                          context,
                          casa,
                          ehDono: auth.userId == widget.donoId,
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      _OportunidadesAbertas(donoId: widget.donoId),
                    ],
                  ),
                ),
        );
      },
    );
  }

  List<Widget> _dados(
    BuildContext context,
    CasaShow casa, {
    required bool ehDono,
  }) {
    final provider = context.watch<OportunidadeProvider>();
    final cidade = casa.estado.isEmpty
        ? casa.cidade
        : '${casa.cidade}, ${casa.estado}';
    const espaco = SizedBox(height: AppSpacing.sm);

    return [
      if (provider.ehBloqueado(widget.donoId))
        AvisoBloqueado(uid: widget.donoId, nome: casa.nome),
      CabecalhoPerfil(
        nome: casa.nome,
        etiquetas: [
          InfoComIcone(Icons.place_outlined, cidade),
          if (provider.ehAssinante(widget.donoId)) const SeloAssinante(),
        ],
      ),
      if (casa.capacidade > 0) ...[
        espaco,
        GradeBlocos(
          blocos: [
            BlocoInfo(
              rotulo: 'Capacidade',
              valor: '${casa.capacidade} pessoas',
              icone: Icons.groups_outlined,
            ),
          ],
        ),
      ],
      espaco,
      CardLocal(
        logradouro: casa.logradouro,
        numero: casa.numero,
        cidade: casa.cidade,
        estado: casa.estado,
        cep: casa.cep,
        titulo: 'Localização',
      ),
      if (casa.estilosDesejados.isNotEmpty) ...[
        espaco,
        CardSecao(
          titulo: 'Estilos que procura',
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final estilo in casa.estilosDesejados) Etiqueta(estilo),
            ],
          ),
        ),
      ],
      if (casa.descricao.trim().isNotEmpty) ...[
        espaco,
        CardSecao(titulo: 'Sobre', child: Text(casa.descricao)),
      ],
      espaco,
      CardSecao(
        titulo: 'Contato',
        child: casa.contato.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(casa.contato),
                  if (casa.cnpj.isNotEmpty)
                    Text(
                      'CNPJ: ${casa.cnpj}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: AppColors.textoSecundario,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      ehDono
                          ? 'Você ainda não informou o contato.'
                          : 'Contato e CNPJ são liberados depois de um '
                                'interesse aceito entre vocês.',
                      style: const TextStyle(color: AppColors.textoSecundario),
                    ),
                  ),
                ],
              ),
      ),
      espaco,
      AvaliacoesSecao(uid: widget.donoId),
    ];
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
        TituloSecao(
          abertas.isEmpty
              ? 'Nenhuma oportunidade aberta'
              : 'Oportunidades abertas (${abertas.length})',
        ),
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
            onCandidatar:
                podeCandidatar(auth, oportunidade) &&
                    !provider.ehBloqueado(donoId)
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
