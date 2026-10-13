import 'package:flutter/widgets.dart';

/// Escala de espaçamento (px) usada no canvas.
abstract final class GigSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// Margem lateral das telas com abas.
  static const double page = 16;

  /// Margem lateral das telas de acesso (login, cadastro).
  static const double pageAuth = 24;

  static const pagePadding = EdgeInsets.symmetric(horizontal: page);
  static const authPadding = EdgeInsets.symmetric(horizontal: pageAuth);
}

abstract final class GigRadius {
  static const double sm = 8;
  static const double md = 10; // botões
  static const double lg = 12; // cards, inputs
  static const double xl = 16; // cards de festa
  static const double pill = 999;

  static const button = BorderRadius.all(Radius.circular(md));
  static const card = BorderRadius.all(Radius.circular(lg));
  static const cardLarge = BorderRadius.all(Radius.circular(xl));
  static const pillAll = BorderRadius.all(Radius.circular(pill));
}

abstract final class GigSizes {
  static const double buttonLarge = 48;
  static const double buttonMedium = 40;
  static const double buttonSmall = 36;
  static const double bottomNav = 64;
  static const double touchTarget = 44;
}
