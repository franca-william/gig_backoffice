import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'gig_colors.dart';

/// Tipografia do GIG: Roboto Slab nos títulos/rótulos, Roboto Flex no texto.
///
/// Letter-spacing em Flutter é absoluto (px): 0.1em em 12px = 1.2.
abstract final class GigTypography {
  static TextStyle _slab(double size, FontWeight weight, {double? height, double? spacing, Color? color}) =>
      GoogleFonts.robotoSlab(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: spacing,
        color: color ?? GigColors.text,
      );

  static TextStyle _flex(double size, FontWeight weight, {double? height, double? spacing, Color? color}) =>
      GoogleFonts.robotoFlex(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: spacing,
        color: color ?? GigColors.text,
      );

  // Títulos
  static TextStyle get display => _slab(30, FontWeight.w700, height: 1.25);
  static TextStyle get h1 => _slab(24, FontWeight.w700, height: 32 / 24);
  static TextStyle get h2 => _slab(18, FontWeight.w700, height: 28 / 18);
  static TextStyle get h3 => _slab(16, FontWeight.w600, height: 1.25);
  static TextStyle get cardTitle => _slab(20, FontWeight.w700, height: 1.2);
  static TextStyle get stat => _slab(18, FontWeight.w700, height: 28 / 18);

  // Texto
  static TextStyle get bodyLarge => _flex(16, FontWeight.w400, height: 1.5);
  static TextStyle get body => _flex(14, FontWeight.w400, height: 20 / 14);
  static TextStyle get bodyMuted => body.copyWith(color: GigColors.textMuted);
  static TextStyle get paragraph => _flex(14, FontWeight.w400, height: 1.625, color: GigColors.textMuted);
  static TextStyle get small => _flex(12, FontWeight.w400, height: 16 / 12, color: GigColors.textMuted);
  static TextStyle get caption => _flex(11, FontWeight.w400, color: GigColors.textMuted);

  // Rótulos (aplicar .toUpperCase() no texto quando o design pede caixa alta)
  static TextStyle get fieldLabel => _slab(12, FontWeight.w600, spacing: 1.2, color: GigColors.textMuted);
  static TextStyle get sectionTitle => _slab(14, FontWeight.w600, spacing: 1.4);
  static TextStyle get tag => _slab(10, FontWeight.w600, spacing: 1.0);
  static TextStyle get chip => _slab(12, FontWeight.w600);
  static TextStyle get link => _slab(12, FontWeight.w600, color: GigColors.primary);
  static TextStyle get navLabel => _slab(10, FontWeight.w500, spacing: 0.25);

  // Botões
  static TextStyle get buttonLarge => _slab(16, FontWeight.w700, spacing: 0.4);
  static TextStyle get buttonMedium => _slab(14, FontWeight.w600);
  static TextStyle get buttonFlex => _flex(14, FontWeight.w500);

  /// TextTheme do Material mapeado para os estilos acima.
  static TextTheme get textTheme => TextTheme(
        displaySmall: display,
        headlineMedium: h1,
        headlineSmall: h2,
        titleLarge: cardTitle,
        titleMedium: h3,
        titleSmall: chip,
        bodyLarge: bodyLarge,
        bodyMedium: body,
        bodySmall: small,
        labelLarge: buttonMedium,
        labelMedium: fieldLabel,
        labelSmall: tag,
      );
}
