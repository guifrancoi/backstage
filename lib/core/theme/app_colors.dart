import 'package:flutter/material.dart';

/// Paleta do Backstage (Plano 8): tema escuro dos protótipos, roxo de
/// destaque e verde para dinheiro. Telas não usam estas constantes direto:
/// leem `Theme.of(context).colorScheme` ou [BackstageCores] (`context.cores`)
/// — assim um tema claro futuro só troca os valores aqui.
abstract final class AppColors {
  // Superfícies, da mais funda para a mais alta.
  static const fundo = Color(0xFF0B0B10);
  static const superficie = Color(0xFF16161F);
  static const superficieAlta = Color(0xFF1E1E2A);
  static const borda = Color(0xFF2A2A3A);

  /// Contorno de botão secundário (um tom acima da borda dos cards).
  static const bordaForte = Color(0xFF3D3D52);

  // Marca.
  /// Roxo dos protótipos (#7C5CFF) escurecido um pouco: texto branco nos
  /// botões precisa de 4,5:1 (WCAG AA) e o original dava 4,35:1.
  static const primaria = Color(0xFF7656F5);

  /// Roxo para texto e ícones pequenos: `primaria` sobre o fundo fica em
  /// ~4,1:1, abaixo do mínimo WCAG (4,5:1); este fica em ~7,2:1.
  static const primariaTexto = Color(0xFFA78BFA);
  static const primariaContainer = Color(0xFF2D2550);

  // Texto.
  static const texto = Color(0xFFF2F2F7);
  static const textoSecundario = Color(0xFF9A9AB0);

  /// Só para conteúdo desabilitado/decorativo (não passa em contraste de
  /// texto corrido).
  static const textoTerciario = Color(0xFF6B6B80);

  // Semânticas.
  /// Informação neutra (ex.: contraproposta em negociação).
  static const info = Color(0xFF60A5FA);

  /// Estrelas de avaliação e selo de assinante.
  static const estrela = Color(0xFFFBBF24);

  static const sucesso = Color(0xFF34D27B);
  static const sucessoFundo = Color(0xFF123224);
  static const aviso = Color(0xFFF5A524);
  static const avisoFundo = Color(0xFF3A2A0E);
  static const erro = Color(0xFFF05252);
  static const erroFundo = Color(0xFF3A1717);

  /// Card de destaque (oportunidade em destaque, cabeçalho dos detalhes).
  static const gradienteDestaque = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3A2C7A), Color(0xFF1C1638)],
  );
}

/// Cores que o `ColorScheme` do Material não tem (dinheiro e status).
/// Ler com `context.cores`.
@immutable
class BackstageCores extends ThemeExtension<BackstageCores> {
  const BackstageCores({
    required this.dinheiro,
    required this.sucesso,
    required this.sucessoFundo,
    required this.aviso,
    required this.avisoFundo,
    required this.erro,
    required this.erroFundo,
    required this.primariaTexto,
    required this.textoSecundario,
    required this.textoTerciario,
    required this.superficieAlta,
    required this.borda,
    required this.gradienteDestaque,
  });

  static const escuro = BackstageCores(
    dinheiro: AppColors.sucesso,
    sucesso: AppColors.sucesso,
    sucessoFundo: AppColors.sucessoFundo,
    aviso: AppColors.aviso,
    avisoFundo: AppColors.avisoFundo,
    erro: AppColors.erro,
    erroFundo: AppColors.erroFundo,
    primariaTexto: AppColors.primariaTexto,
    textoSecundario: AppColors.textoSecundario,
    textoTerciario: AppColors.textoTerciario,
    superficieAlta: AppColors.superficieAlta,
    borda: AppColors.borda,
    gradienteDestaque: AppColors.gradienteDestaque,
  );

  final Color dinheiro;
  final Color sucesso;
  final Color sucessoFundo;
  final Color aviso;
  final Color avisoFundo;
  final Color erro;
  final Color erroFundo;
  final Color primariaTexto;
  final Color textoSecundario;
  final Color textoTerciario;
  final Color superficieAlta;
  final Color borda;
  final Gradient gradienteDestaque;

  @override
  BackstageCores copyWith({
    Color? dinheiro,
    Color? sucesso,
    Color? sucessoFundo,
    Color? aviso,
    Color? avisoFundo,
    Color? erro,
    Color? erroFundo,
    Color? primariaTexto,
    Color? textoSecundario,
    Color? textoTerciario,
    Color? superficieAlta,
    Color? borda,
    Gradient? gradienteDestaque,
  }) {
    return BackstageCores(
      dinheiro: dinheiro ?? this.dinheiro,
      sucesso: sucesso ?? this.sucesso,
      sucessoFundo: sucessoFundo ?? this.sucessoFundo,
      aviso: aviso ?? this.aviso,
      avisoFundo: avisoFundo ?? this.avisoFundo,
      erro: erro ?? this.erro,
      erroFundo: erroFundo ?? this.erroFundo,
      primariaTexto: primariaTexto ?? this.primariaTexto,
      textoSecundario: textoSecundario ?? this.textoSecundario,
      textoTerciario: textoTerciario ?? this.textoTerciario,
      superficieAlta: superficieAlta ?? this.superficieAlta,
      borda: borda ?? this.borda,
      gradienteDestaque: gradienteDestaque ?? this.gradienteDestaque,
    );
  }

  @override
  BackstageCores lerp(BackstageCores? other, double t) {
    if (other == null) return this;
    return BackstageCores(
      dinheiro: Color.lerp(dinheiro, other.dinheiro, t)!,
      sucesso: Color.lerp(sucesso, other.sucesso, t)!,
      sucessoFundo: Color.lerp(sucessoFundo, other.sucessoFundo, t)!,
      aviso: Color.lerp(aviso, other.aviso, t)!,
      avisoFundo: Color.lerp(avisoFundo, other.avisoFundo, t)!,
      erro: Color.lerp(erro, other.erro, t)!,
      erroFundo: Color.lerp(erroFundo, other.erroFundo, t)!,
      primariaTexto: Color.lerp(primariaTexto, other.primariaTexto, t)!,
      textoSecundario: Color.lerp(textoSecundario, other.textoSecundario, t)!,
      textoTerciario: Color.lerp(textoTerciario, other.textoTerciario, t)!,
      superficieAlta: Color.lerp(superficieAlta, other.superficieAlta, t)!,
      borda: Color.lerp(borda, other.borda, t)!,
      gradienteDestaque: t < 0.5 ? gradienteDestaque : other.gradienteDestaque,
    );
  }
}

extension CoresDoTema on BuildContext {
  /// Cores do Backstage além do `ColorScheme` (dinheiro, status...). Fora do
  /// tema do app (ex.: teste sem `MaterialApp(theme:)`) cai no escuro.
  BackstageCores get cores =>
      Theme.of(this).extension<BackstageCores>() ?? BackstageCores.escuro;
}
