/// Marca "GiG": em texto em caixa alta o nome continua **GiG** (nunca "GIG").
extension MarcaTexto on String {
  /// Maiúsculas preservando a marca: "fora do GiG" → "FORA DO GiG"; "GiGs abertas" → "GiGs ABERTAS".
  String get emCaixaAlta =>
      toUpperCase().replaceAllMapped(RegExp(r'\bGIG(S?)\b'), (m) => 'GiG${m[1]!.toLowerCase()}');
}
