/// Datas no fuso do navegador (a equipe está no Brasil). Sem `intl` para não depender de inicializar locale.
abstract final class Formatar {
  // ignore: non_constant_identifier_names
  static String _2(int n) => n.toString().padLeft(2, '0');

  /// 10/10/2026
  static String data(DateTime d) {
    final l = d.toLocal();
    return '${_2(l.day)}/${_2(l.month)}/${l.year}';
  }

  /// 10/10/2026 14:05
  static String dataHora(DateTime d) {
    final l = d.toLocal();
    return '${data(l)} ${_2(l.hour)}:${_2(l.minute)}';
  }

  /// 14:05
  static String hora(DateTime d) {
    final l = d.toLocal();
    return '${_2(l.hour)}:${_2(l.minute)}';
  }

  /// Número em pt-BR: 1.234 · 3,5 · 1.050,0 (sem `intl`).
  static String numero(num valor, {int casas = 0}) {
    final negativo = valor < 0;
    final texto = valor.abs().toStringAsFixed(casas);
    final partes = texto.split('.');
    final inteiro = partes[0];
    final grupos = StringBuffer();
    for (var i = 0; i < inteiro.length; i++) {
      if (i > 0 && (inteiro.length - i) % 3 == 0) grupos.write('.');
      grupos.write(inteiro[i]);
    }
    final decimal = partes.length > 1 ? ',${partes[1]}' : '';
    return '${negativo ? '-' : ''}$grupos$decimal';
  }

  /// Uma casa decimal só quando precisa: 50 · 33,3.
  static String compacto(num valor) =>
      valor == valor.roundToDouble() ? numero(valor) : numero(valor, casas: 1);

  /// 72,5%
  static String percentual(num valor) => '${compacto(valor)}%';

  /// R$ 1.050
  static String moeda(num valor) => 'R\$ ${numero(valor)}';

  /// Duração em horas: "36 h" abaixo de 48 h, senão "3,5 dias".
  static String duracaoEmHoras(num horas) =>
      horas < 48 ? '${numero(horas)} h' : '${compacto((horas / 24 * 10).round() / 10)} dias';

  /// "começa em 5 h" / "começa em 3 dias"
  static String comecaEm(int horas) {
    if (horas < 1) return 'começa em menos de 1 h';
    if (horas < 48) return 'começa em $horas h';
    return 'começa em ${horas ~/ 24} dias';
  }

  /// "há 25 min" / "há 3 h" / "há 2 dias"
  static String ha(DateTime desde, DateTime agora) {
    final d = agora.difference(desde);
    if (d.inMinutes < 60) return 'há ${d.inMinutes < 1 ? 1 : d.inMinutes} min';
    if (d.inHours < 48) return 'há ${d.inHours} h';
    return 'há ${d.inDays} dias';
  }

  /// 16/12
  static String diaCurto(DateTime d) => '${_2(d.day)}/${_2(d.month)}';
}
