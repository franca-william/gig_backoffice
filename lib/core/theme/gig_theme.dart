import 'package:flutter/material.dart';

import 'gig_colors.dart';
import 'gig_spacing.dart';
import 'gig_typography.dart';

/// Tokens de cor que não existem no ColorScheme do Material.
@immutable
class GigPalette extends ThemeExtension<GigPalette> {
  const GigPalette({
    required this.surfaceHigh,
    required this.border,
    required this.textMuted,
    required this.textSubtle,
    required this.info,
    required this.danger,
  });

  final Color surfaceHigh;
  final Color border;
  final Color textMuted;
  final Color textSubtle;
  final Color info;
  final Color danger;

  static const dark = GigPalette(
    surfaceHigh: GigColors.surfaceHigh,
    border: GigColors.border,
    textMuted: GigColors.textMuted,
    textSubtle: GigColors.textSubtle,
    info: GigColors.info,
    danger: GigColors.danger,
  );

  @override
  GigPalette copyWith({
    Color? surfaceHigh,
    Color? border,
    Color? textMuted,
    Color? textSubtle,
    Color? info,
    Color? danger,
  }) =>
      GigPalette(
        surfaceHigh: surfaceHigh ?? this.surfaceHigh,
        border: border ?? this.border,
        textMuted: textMuted ?? this.textMuted,
        textSubtle: textSubtle ?? this.textSubtle,
        info: info ?? this.info,
        danger: danger ?? this.danger,
      );

  @override
  GigPalette lerp(ThemeExtension<GigPalette>? other, double t) {
    if (other is! GigPalette) return this;
    return GigPalette(
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      border: Color.lerp(border, other.border, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textSubtle: Color.lerp(textSubtle, other.textSubtle, t)!,
      info: Color.lerp(info, other.info, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

extension GigThemeContext on BuildContext {
  GigPalette get gig => Theme.of(this).extension<GigPalette>() ?? GigPalette.dark;
}

abstract final class GigTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: GigColors.primary,
      onPrimary: GigColors.onPrimary,
      secondary: GigColors.info,
      onSecondary: GigColors.text,
      surface: GigColors.surface,
      onSurface: GigColors.text,
      error: GigColors.danger,
      onError: GigColors.text,
      outline: GigColors.border,
    );

    const inputBorder = OutlineInputBorder(
      borderRadius: GigRadius.card,
      borderSide: BorderSide(color: GigColors.border),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: GigColors.background,
      canvasColor: GigColors.background,
      textTheme: GigTypography.textTheme,
      splashFactory: InkRipple.splashFactory,
      dividerTheme: const DividerThemeData(color: GigColors.border, thickness: 1, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: GigColors.primary),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: GigColors.primary,
        selectionColor: GigColors.primaryBorder,
        selectionHandleColor: GigColors.primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GigColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GigTypography.body.copyWith(color: GigColors.textMuted),
        errorStyle: GigTypography.small.copyWith(color: GigColors.danger),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: GigColors.primary)),
        errorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: GigColors.danger)),
        focusedErrorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: GigColors.danger)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: GigColors.primary,
          foregroundColor: GigColors.onPrimary,
          minimumSize: const Size.fromHeight(GigSizes.buttonLarge),
          shape: const RoundedRectangleBorder(borderRadius: GigRadius.button),
          textStyle: GigTypography.buttonLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GigColors.text,
          backgroundColor: GigColors.background,
          side: const BorderSide(color: GigColors.border),
          minimumSize: const Size.fromHeight(GigSizes.buttonMedium),
          shape: const RoundedRectangleBorder(borderRadius: GigRadius.button),
          textStyle: GigTypography.buttonFlex,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: GigColors.primary,
          textStyle: GigTypography.link,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: GigColors.background,
        elevation: 8,
        contentTextStyle: GigTypography.body,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(GigRadius.sm)),
          side: BorderSide(color: GigColors.border),
        ),
      ),
      extensions: const [GigPalette.dark],
    );
  }
}
