import 'dart:math' as math;
import 'dart:ui';

/// Pin do GIG, versão principal (manual da marca, seção 2): gota com miolo e onda sonora de 5 barras.
/// Construção: círculo de raio R, ponta a 2,25 R do centro, miolo de 66% de R.
///
/// Medidas em dp com R = 37. É a MESMA geometria do PNG da splash nativa (assets/splash/gig_pin.png) e dos
/// ícones do app, por isso o frame 0 da splash animada é idêntico ao da camada nativa.
abstract final class GigPin {
  static const raio = 37.0;
  static const largura = 2 * raio; // 74
  static const altura = raio + 2.25 * raio; // 120,25
  static const centro = Offset(largura / 2, altura / 2);
  static const centroCirculo = Offset(raio, raio);
  static const raioMiolo = 0.66 * raio;

  /// Alturas relativas das 5 barras (manual: 45%, 80%, 100%, 70% e 40%).
  static const alturasRelativas = [0.45, 0.80, 1.00, 0.70, 0.40];
  static const alturaMaxBarra = 1.15 * raioMiolo;
  static const larguraBarra = 4.4;
  static const espacoBarras = 3.2;

  /// Gota: círculo + ponta para baixo.
  static Path caminho() {
    const ponta = raio + 2.25 * raio;
    const dy = ponta - raio;
    const cosPhi = raio / dy;
    final sinPhi = math.sqrt(1 - cosPhi * cosPhi);
    final tx = raio * sinPhi;
    const ty = raio * cosPhi;
    final inicio = math.atan2(ty, tx);
    final varredura = -(math.pi + 2 * inicio);
    return Path()
      ..moveTo(raio, ponta)
      ..lineTo(raio + tx, raio + ty)
      ..arcTo(Rect.fromCircle(center: centroCirculo, radius: raio), inicio,
          varredura, false)
      ..close();
  }

  /// Retângulo da barra [i] (0..4) com altura relativa [alturaRel] (1 = [alturaMaxBarra]), centrada no miolo.
  static Rect retanguloBarra(int i, double alturaRel) {
    const total = 5 * larguraBarra + 4 * espacoBarras;
    final x0 = raio - total / 2 + i * (larguraBarra + espacoBarras);
    final h = alturaRel * alturaMaxBarra;
    return Rect.fromLTWH(x0, raio - h / 2, larguraBarra, h);
  }

  /// Raio dos cantos das barras (pontas redondas).
  static const raioBarra = Radius.circular(larguraBarra / 2);
}
