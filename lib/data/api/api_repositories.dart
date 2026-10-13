import '../models/dashboard.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import 'backoffice_api.dart';

class ApiSessaoRepository implements SessaoRepository {
  ApiSessaoRepository(this._api);

  final BackofficeApi _api;

  @override
  Future<Membro> entrar(String login, String senha) async {
    final corpo = await _api.entrar(login.trim(), senha);
    return Membro.fromJson(corpo['usuario'] as Map<String, dynamic>? ?? const {});
  }

  @override
  Future<Membro?> restaurar() async {
    final corpo = await _api.renovar();
    if (corpo == null) return null;
    return Membro.fromJson(corpo['usuario'] as Map<String, dynamic>? ?? const {});
  }

  @override
  Future<void> sair() => _api.sair();
}

class ApiSugestaoRepository implements SugestaoRepository {
  ApiSugestaoRepository(this._api);

  final BackofficeApi _api;
  static const _base = '/api/backoffice/sugestoes';

  @override
  Future<PaginaSugestoes> listar(FiltroSugestoes filtro, {int pagina = 0}) async {
    final corpo = await _api.get(_base, query: {
      'situacao': filtro.situacao.api,
      if (filtro.perfil != null) 'perfil': filtro.perfil!.api,
      if (filtro.tipo != null) 'tipo': filtro.tipo!.api,
      if (filtro.busca.trim().isNotEmpty) 'busca': filtro.busca.trim(),
      'page': '$pagina',
    });
    return PaginaSugestoes.fromJson(corpo);
  }

  @override
  Future<ContagemSugestoes> contagem() async => ContagemSugestoes.fromJson(await _api.get('$_base/contagem'));

  @override
  Future<SugestaoDetalhe> detalhe(String id) async => SugestaoDetalhe.fromJson(await _api.get('$_base/$id'));

  @override
  Future<void> marcarEmAnalise(String id) => _api.post('$_base/$id/analise');

  @override
  Future<SugestaoDetalhe> responder(String id, String texto) async =>
      SugestaoDetalhe.fromJson(await _api.post('$_base/$id/resposta', corpo: {'texto': texto}));
}

class ApiDashboardRepository implements DashboardRepository {
  ApiDashboardRepository(this._api);

  final BackofficeApi _api;
  static const _base = '/api/backoffice/dashboard';

  Future<Map<String, dynamic>> _aba(String aba, int periodo, bool atualizar) => _api.get('$_base/$aba', query: {
        'periodo': '$periodo',
        if (atualizar) 'atualizar': 'true',
      });

  @override
  Future<Atencao> atencao() async => Atencao.fromJson(await _api.get('$_base/atencao'));

  @override
  Future<Marketplace> marketplace(int periodo, {bool atualizar = false}) async =>
      Marketplace.fromJson(await _aba('marketplace', periodo, atualizar));

  @override
  Future<Crescimento> crescimento(int periodo, {bool atualizar = false}) async =>
      Crescimento.fromJson(await _aba('crescimento', periodo, atualizar));

  @override
  Future<Curtidores> curtidores(int periodo, {bool atualizar = false}) async =>
      Curtidores.fromJson(await _aba('curtidores', periodo, atualizar));

  @override
  Future<Qualidade> qualidade(int periodo, {bool atualizar = false}) async =>
      Qualidade.fromJson(await _aba('qualidade', periodo, atualizar));
}
