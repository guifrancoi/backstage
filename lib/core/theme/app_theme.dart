import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Tema único do app (Plano 8): escuro, Material 3, montado a partir dos
/// tokens (`AppColors`, `AppTypography`, `AppSpacing`/`AppRadius`). Os
/// temas de componente dão a cara do Backstage a cards, campos, botões,
/// chips etc. sem estilo inline nas telas.
abstract final class AppTheme {
  static ThemeData get escuro {
    const scheme = ColorScheme.dark(
      primary: AppColors.primaria,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primariaContainer,
      onPrimaryContainer: AppColors.primariaTexto,
      secondary: AppColors.primariaTexto,
      onSecondary: AppColors.fundo,
      secondaryContainer: AppColors.primariaContainer,
      onSecondaryContainer: AppColors.primariaTexto,
      tertiary: AppColors.sucesso,
      onTertiary: AppColors.fundo,
      error: AppColors.erro,
      onError: Colors.white,
      errorContainer: AppColors.erroFundo,
      onErrorContainer: AppColors.erro,
      surface: AppColors.fundo,
      onSurface: AppColors.texto,
      onSurfaceVariant: AppColors.textoSecundario,
      surfaceContainerLowest: AppColors.fundo,
      surfaceContainerLow: AppColors.superficie,
      surfaceContainer: AppColors.superficie,
      surfaceContainerHigh: AppColors.superficieAlta,
      surfaceContainerHighest: AppColors.superficieAlta,
      outline: AppColors.bordaForte,
      outlineVariant: AppColors.borda,
      inverseSurface: AppColors.texto,
      onInverseSurface: AppColors.fundo,
      inversePrimary: AppColors.primaria,
      surfaceTint: Colors.transparent,
    );

    final texto = AppTypography.textTheme;
    final textTheme = texto.copyWith(
      bodySmall: texto.bodySmall?.copyWith(color: AppColors.textoSecundario),
      labelSmall: texto.labelSmall?.copyWith(
        color: AppColors.textoSecundario,
      ),
    );

    final cantoCampo = RoundedRectangleBorder(
      borderRadius: AppRadius.circular(AppRadius.md),
    );
    OutlineInputBorder bordaCampo(Color cor, [double largura = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: cor, width: largura),
        );
    const tamanhoBotao = Size(64, 48);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      fontFamily: AppTypography.familia,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.fundo,
      canvasColor: AppColors.fundo,
      dividerColor: AppColors.borda,
      extensions: const [BackstageCores.escuro],
      iconTheme: const IconThemeData(color: AppColors.texto),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.fundo,
        foregroundColor: AppColors.texto,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.superficie,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.borda),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.superficieAlta,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        labelStyle: const TextStyle(color: AppColors.textoSecundario),
        floatingLabelStyle: const TextStyle(color: AppColors.primariaTexto),
        hintStyle: const TextStyle(color: AppColors.textoTerciario),
        helperStyle: const TextStyle(color: AppColors.textoSecundario),
        prefixIconColor: AppColors.textoSecundario,
        suffixIconColor: AppColors.textoSecundario,
        border: bordaCampo(AppColors.borda),
        enabledBorder: bordaCampo(AppColors.borda),
        focusedBorder: bordaCampo(AppColors.primaria, 1.5),
        errorBorder: bordaCampo(AppColors.erro),
        focusedErrorBorder: bordaCampo(AppColors.erro, 1.5),
        disabledBorder: bordaCampo(AppColors.borda.withValues(alpha: 0.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaria,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.superficieAlta,
          disabledForegroundColor: AppColors.textoTerciario,
          elevation: 0,
          minimumSize: tamanhoBotao,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: cantoCampo,
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaria,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.superficieAlta,
          disabledForegroundColor: AppColors.textoTerciario,
          minimumSize: tamanhoBotao,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: cantoCampo,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.texto,
          disabledForegroundColor: AppColors.textoTerciario,
          minimumSize: tamanhoBotao,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          side: const BorderSide(color: AppColors.bordaForte),
          shape: cantoCampo,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primariaTexto,
          textStyle: textTheme.labelLarge,
          shape: cantoCampo,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.texto),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaria,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circular(AppRadius.lg),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.superficieAlta,
        selectedColor: AppColors.primariaContainer,
        disabledColor: AppColors.superficie,
        checkmarkColor: AppColors.primariaTexto,
        deleteIconColor: AppColors.textoSecundario,
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.primariaTexto,
        ),
        side: const BorderSide(color: AppColors.borda),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circular(AppRadius.pilula),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.superficie,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primariaContainer,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (estados) => textTheme.labelSmall?.copyWith(
            letterSpacing: 0,
            fontWeight: FontWeight.w600,
            color: estados.contains(WidgetState.selected)
                ? AppColors.primariaTexto
                : AppColors.textoSecundario,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (estados) => IconThemeData(
            color: estados.contains(WidgetState.selected)
                ? AppColors.primariaTexto
                : AppColors.textoSecundario,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primariaTexto,
        unselectedLabelColor: AppColors.textoSecundario,
        indicatorColor: AppColors.primaria,
        dividerColor: AppColors.borda,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.superficie,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.bordaForte,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.superficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: textTheme.titleMedium,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textoSecundario,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.superficieAlta,
        contentTextStyle: textTheme.bodyMedium,
        actionTextColor: AppColors.primariaTexto,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.borda),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.superficieAlta,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.borda),
        ),
        textStyle: textTheme.bodyMedium,
      ),
      menuTheme: const MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.superficieAlta),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textoSecundario,
        textColor: AppColors.texto,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circular(AppRadius.md),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borda,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaria,
        linearTrackColor: AppColors.superficieAlta,
        circularTrackColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.textoSecundario,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? AppColors.primaria
              : AppColors.superficieAlta,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? AppColors.primaria
              : AppColors.bordaForte,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? AppColors.primaria
              : Colors.transparent,
        ),
        side: const BorderSide(color: AppColors.bordaForte, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? AppColors.primaria
              : AppColors.bordaForte,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primaria,
        thumbColor: AppColors.primaria,
        inactiveTrackColor: AppColors.superficieAlta,
      ),
      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.primaria,
        textColor: Colors.white,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.superficieAlta,
          borderRadius: AppRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.borda),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: AppColors.texto),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.superficie,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.primariaContainer,
        headerForegroundColor: AppColors.texto,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circular(AppRadius.xl),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circular(AppRadius.xl),
        ),
      ),
    );
  }
}
