import '../../models/contratacao.dart';
import '../../widgets/etiqueta.dart';

/// Cor da etiqueta de status da contratação (Plano 8), igual em
/// Contratações e na Agenda: proposta = aviso (amarelo), contraproposta =
/// destaque (roxo), confirmada = sucesso (verde, como no protótipo),
/// realizada = neutra, recusada/cancelada = erro.
TipoEtiqueta tipoEtiquetaContratacao(Contratacao c) {
  if (c.realizada) return TipoEtiqueta.neutra;
  return switch (c.status) {
    StatusContratacao.proposta => TipoEtiqueta.aviso,
    StatusContratacao.contraproposta => TipoEtiqueta.destaque,
    StatusContratacao.confirmada => TipoEtiqueta.sucesso,
    StatusContratacao.recusada ||
    StatusContratacao.cancelada => TipoEtiqueta.erro,
  };
}
