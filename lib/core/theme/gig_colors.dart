import 'package:flutter/painting.dart';

/// Paleta extraída do canvas "GIG — Música ao Vivo".
abstract final class GigColors {
  // Superfícies
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1E1E1E);
  static const surfaceHigh = Color(0xFF262626);
  static const border = Color(0xFF2E2E2E);
  static const navBackground = Color(0xF21E1E1E); // surface a 95%
  static const scrim = Color(0xCC000000); // fundo de diálogo (80%)

  // Texto
  static const text = Color(0xFFEAEAEA);
  static const textSubtle = Color(0xFFB3B3B3);
  static const textMuted = Color(0xFF8C8C8C);
  static const textDisabled = Color(0x4D8C8C8C); // muted a 30%

  // Marca e estados
  static const primary = Color(0xFFFFB700);
  static const onPrimary = Color(0xFF121212);
  static const primarySoft = Color(0x1AFFB700); // fundo de ícone (10%)
  static const primaryBorder = Color(0x73FFB700); // hover/seleção (45%)
  static const info = Color(0xFF568ED2);
  static const danger = Color(0xFFD02F2F);
  static const success = Color(0xFF3FA66B);

  /// Cores de fundo dos avatares com iniciais.
  static const avatars = <Color>[
    Color(0xFF7A3B5C),
    Color(0xFF3D5A2F),
    Color(0xFF2F5D73),
    Color(0xFF7A4B1F),
    Color(0xFF3B3F7A),
    Color(0xFF73402F),
    Color(0xFF5C4A14),
  ];
}
