import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/foto_perfil.dart';
import '../../models/contratacao.dart';
import '../../models/oportunidade.dart';
import '../../providers/interesse_provider.dart';
import '../../providers/oportunidade_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/motivos_compatibilidade.dart';
import '../../widgets/musico_card.dart' show SeloAssinante;
import 'acoes_interesse.dart';

/// "Músicos sugeridos" (Plano 15) no detalhe da oportunidade do próprio
/// dono: os 5 mais compatíveis, com os motivos e o Convidar já marcado
/// nesta oportunidade. Quem tem show ou bloqueou o dia não aparece.
class MusicosSugeridosSecao extends StatefulWidget {
  const MusicosSugeridosSecao({super.key, required this.oportunidade});

  final Oportunidade oportunidade;

  @override
  State<MusicosSugeridosSecao> createState() => _MusicosSugeridosSecaoState();
}

class _MusicosSugeridosSecaoState extends State<MusicosSugeridosSecao> {
  late Stream<Set<String>> _indisponiveis = _assinar();

  Stream<Set<String>> _assinar() => context
      .read<OportunidadeProvider>()
      .indisponiveisNoDia(widget.oportunidade.dataEvento);

  @override
  void didUpdateWidget(MusicosSugeridosSecao antigo) {
    super.didUpdateWidget(antigo);
    // Data do evento editada: consulta o novo dia.
    if (Contratacao.diaDe(antigo.oportunidade.dataEvento) !=
        Contratacao.diaDe(widget.oportunidade.dataEvento)) {
      _indisponiveis = _assinar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OportunidadeProvider>();
    final interesses = context.watch<InteresseProvider>();

    return StreamBuilder<Set<String>>(
      stream: _indisponiveis,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        // Sem a agenda do dia, sugere mesmo assim (sem "livre no dia").
        final sugestoes = provider.musicosSugeridos(
          widget.oportunidade,
          indisponiveis: snapshot.data,
          comInteresse: interesses.musicosComInteresseEm(
            widget.oportunidade.id,
          ),
        );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Músicos sugeridos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pelo gênero, cidade, cachê e agenda do dia.',
                  style: TextStyle(color: Colors.grey),
                ),
                if (sugestoes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Nenhum músico compatível sem convite ainda.',
                    ),
                  ),
                for (final sugestao in sugestoes) ...[
                  const Divider(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundImage: imagemDaFoto(sugestao.item.foto),
                        child: sugestao.item.foto == null
                            ? const Icon(Icons.music_note)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    sugestao.item.nomeArtistico,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (sugestao.assinante) ...[
                                  const SizedBox(width: 6),
                                  const SeloAssinante(),
                                ],
                              ],
                            ),
                            MotivosCompatibilidade(
                              compatibilidade: sugestao.compatibilidade,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.detalheMusico,
                            arguments: sugestao.item.id,
                          ),
                          child: const Text('Ver perfil'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => confirmarConvite(
                            context,
                            sugestao.item,
                            oportunidade: widget.oportunidade,
                          ),
                          child: const Text('Convidar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
