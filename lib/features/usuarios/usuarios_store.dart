import 'package:mobx/mobx.dart';

import '../../data/models/usuario.dart';
import '../../data/repositories/repositories.dart';

/// E5 (backoffice) — consulta de usuários (busca por nome/e-mail, filtro por perfil, paginação).
class UsuariosStore {
  UsuariosStore(this._repo);

  final UsuarioRepository _repo;

  final filtro = Observable<FiltroUsuarios>(const FiltroUsuarios());
  final pagina = Observable<PaginaUsuarios>(PaginaUsuarios.vazia);
  final carregando = Observable<bool>(false);
  final erro = Observable<String?>(null);

  int _versao = 0;

  Future<void> carregar({int numeroPagina = 0}) async {
    final versao = ++_versao;
    runInAction(() {
      carregando.value = true;
      erro.value = null;
    });
    try {
      final resultado = await _repo.listar(filtro.value, pagina: numeroPagina);
      if (versao != _versao) return; // um filtro mais novo já foi pedido
      runInAction(() => pagina.value = resultado);
    } on SessaoExpiradaException {
      // o app já volta para o login
    } on Exception catch (e) {
      if (versao == _versao) runInAction(() => erro.value = '$e');
    } finally {
      if (versao == _versao) runInAction(() => carregando.value = false);
    }
  }

  Future<void> aplicar(FiltroUsuarios novo) {
    runInAction(() => filtro.value = novo);
    return carregar();
  }

  void limpar() {
    runInAction(() {
      filtro.value = const FiltroUsuarios();
      pagina.value = PaginaUsuarios.vazia;
    });
  }
}
