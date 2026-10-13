import 'package:mobx/mobx.dart';

import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';

/// Lista de sugestões + contador do menu ("Sugestões (N)").
class SugestoesStore {
  SugestoesStore(this._repo);

  final SugestaoRepository _repo;

  final filtro = Observable<FiltroSugestoes>(const FiltroSugestoes());
  final pagina = Observable<PaginaSugestoes>(PaginaSugestoes.vazia);
  final contagem = Observable<ContagemSugestoes>(const ContagemSugestoes());
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
      await atualizarContagem();
    } on SessaoExpiradaException {
      // o app já volta para o login
    } catch (e) {
      if (versao == _versao) runInAction(() => erro.value = '$e');
    } finally {
      if (versao == _versao) runInAction(() => carregando.value = false);
    }
  }

  Future<void> atualizarContagem() async {
    try {
      final c = await _repo.contagem();
      runInAction(() => contagem.value = c);
    } catch (_) {
      // o número do menu é melhor esforço
    }
  }

  Future<void> aplicar(FiltroSugestoes novo) {
    runInAction(() => filtro.value = novo);
    return carregar();
  }

  void limpar() {
    runInAction(() {
      filtro.value = const FiltroSugestoes();
      pagina.value = PaginaSugestoes.vazia;
      contagem.value = const ContagemSugestoes();
    });
  }
}
