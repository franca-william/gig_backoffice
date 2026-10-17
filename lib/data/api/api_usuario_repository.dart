import '../models/usuario.dart';
import '../repositories/repositories.dart';
import 'backoffice_api.dart';

/// E5 (backoffice) — consulta de usuários (`/api/backoffice/usuarios/**`).
class ApiUsuarioRepository implements UsuarioRepository {
  ApiUsuarioRepository(this._api);

  final BackofficeApi _api;
  static const _base = '/api/backoffice/usuarios';

  @override
  Future<PaginaUsuarios> listar(FiltroUsuarios filtro, {int pagina = 0}) async =>
      PaginaUsuarios.fromJson(await _api.get(_base, query: {
        if (filtro.busca.trim().isNotEmpty) 'busca': filtro.busca.trim(),
        if (filtro.perfil != null) 'perfil': filtro.perfil!.api,
        'page': '$pagina',
      }));

  @override
  Future<UsuarioDetalhe> detalhe(String id) async => UsuarioDetalhe.fromJson(await _api.get('$_base/$id'));
}
