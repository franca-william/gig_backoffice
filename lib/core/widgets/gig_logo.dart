import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../brand/gig_pin.dart';
import '../brand/gig_wordmark.dart';
import '../theme/theme.dart';

/// Versões do logo (manual da marca, seção 2).
enum GigLogoVariante {
  /// Principal: pin e "i" âmbar, letras `#EAEAEA`, sobre `#121212`.
  escuro,

  /// Sobre âmbar: tudo em `#121212`.
  ambar,

  /// Sobre branco ou claro: pin e letras `#121212`, miolo do pin e "i" âmbar.
  claro,
}

class _Cores {
  const _Cores(
      {required this.pin,
      required this.miolo,
      required this.barras,
      required this.letras,
      required this.i});

  final Color pin;
  final Color miolo;
  final Color barras;
  final Color letras;
  final Color i;

  static const _ambar = GigColors.primary;
  static const _noite = GigColors.background;

  static const escuro = _Cores(
      pin: _ambar,
      miolo: _noite,
      barras: _ambar,
      letras: GigColors.text,
      i: _ambar);
  static const ambar = _Cores(
      pin: _noite, miolo: _ambar, barras: _noite, letras: _noite, i: _noite);
  static const claro = _Cores(
      pin: _noite, miolo: _ambar, barras: _noite, letras: _noite, i: _ambar);

  static _Cores de(GigLogoVariante v) => switch (v) {
        GigLogoVariante.escuro => escuro,
        GigLogoVariante.ambar => ambar,
        GigLogoVariante.claro => claro,
      };
}

/// Desenha o logo (ou só o pin) em vetor. Sempre o vetor oficial: nunca recriar o nome com texto.
class GigLogoPainter extends CustomPainter {
  const GigLogoPainter(
      {this.variante = GigLogoVariante.escuro, this.comNome = true});

  final GigLogoVariante variante;
  final bool comNome;

  /// Proporção largura/altura do desenho.
  static double proporcao({required bool comNome}) =>
      GigWordmark.largura / (comNome ? GigWordmark.altura : GigPin.altura);

  @override
  void paint(Canvas canvas, Size size) {
    final cores = _Cores.de(variante);
    final alturaLogo = comNome ? GigWordmark.altura : GigPin.altura;
    final escala =
        math.min(size.width / GigWordmark.largura, size.height / alturaLogo);
    canvas
      ..save()
      ..translate((size.width - GigWordmark.largura * escala) / 2,
          (size.height - alturaLogo * escala) / 2)
      ..scale(escala);

    final tinta = Paint()..isAntiAlias = true;
    canvas.drawPath(GigPin.caminho(), tinta..color = cores.pin);
    canvas.drawCircle(
        GigPin.centroCirculo, GigPin.raioMiolo, tinta..color = cores.miolo);
    tinta.color = cores.barras;
    for (var i = 0; i < GigPin.alturasRelativas.length; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            GigPin.retanguloBarra(i, GigPin.alturasRelativas[i]),
            GigPin.raioBarra),
        tinta,
      );
    }
    if (comNome) {
      canvas
        ..drawPath(GigWordmark.letras(), tinta..color = cores.letras)
        ..drawPath(GigWordmark.barra(), tinta..color = cores.i)
        ..drawPath(GigWordmark.ponto(), tinta..color = cores.i);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(GigLogoPainter oldDelegate) =>
      oldDelegate.variante != variante || oldDelegate.comNome != comNome;
}

/// Logo completo: pin com a onda sonora e o nome "GiG" abaixo. Tamanho mínimo: 64 de largura.
class GigLogo extends StatelessWidget {
  const GigLogo(
      {super.key,
      this.largura = minimo,
      this.variante = GigLogoVariante.escuro})
      : assert(largura >= minimo,
            'O logo completo não pode ficar menor que 64 de largura (manual da marca).');

  static const minimo = 64.0;

  final double largura;
  final GigLogoVariante variante;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'GIG',
      image: true,
      excludeSemantics: true,
      child: SizedBox(
        width: largura,
        height: largura / GigLogoPainter.proporcao(comNome: true),
        child: CustomPaint(painter: GigLogoPainter(variante: variante)),
      ),
    );
  }
}

/// Símbolo isolado (só o pin), para cabeçalhos, favicon e quando o nome já aparece ao lado. Mínimo: 24.
class GigPinSymbol extends StatelessWidget {
  const GigPinSymbol(
      {super.key,
      this.largura = minimo,
      this.variante = GigLogoVariante.escuro})
      : assert(largura >= minimo,
            'O símbolo não pode ficar menor que 24 de largura (manual da marca).');

  static const minimo = 24.0;

  final double largura;
  final GigLogoVariante variante;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'GIG',
      image: true,
      excludeSemantics: true,
      child: SizedBox(
        width: largura,
        height: largura / GigLogoPainter.proporcao(comNome: false),
        child: CustomPaint(
            painter: GigLogoPainter(variante: variante, comNome: false)),
      ),
    );
  }
}
