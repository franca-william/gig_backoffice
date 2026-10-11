abstract final class Rotas {
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const sugestoes = '/sugestoes';
  static String sugestao(String id) => '/sugestoes/$id';

  /// `/dashboard?aba=marketplace&periodo=30` (E1: a aba e o período ficam na URL).
  static String dashboardCom({required String aba, required int periodo}) =>
      Uri(path: dashboard, queryParameters: {'aba': aba, 'periodo': '$periodo'}).toString();
}
