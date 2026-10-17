import 'package:mobx/mobx.dart';

import '../../data/models/impulso.dart';
import '../../data/repositories/repositories.dart';

enum AbaImpulsos {
  textos('Textos para aprovar'),
  impulsos('Impulsos'),
  casas('Casas'),
  configuracoes('Pacotes e parâmetros');

  const AbaImpulsos(this.rotulo);
  final String rotulo;
}

/// E40 — tela "Impulsos" do backoffice + número do menu (textos de push esperando a equipe).
class ImpulsosStore {
  ImpulsosStore(this._repo);

  final ImpulsoRepository _repo;

  final aba = Observable<AbaImpulsos>(AbaImpulsos.textos);
  final textosEmAnalise = Observable<int>(0);
  final textos = Observable<List<TextoPush>>(const []);
  final impulsos = Observable<PaginaImpulsos>(PaginaImpulsos.vazia);
  final situacao = Observable<SituacaoImpulso?>(null);
  final busca = Observable<String>('');
  final casas = Observable<List<CasaImpulso>>(const []);
  final buscaCasas = Observable<String>('');
  final soHabilitadas = Observable<bool>(false);
  final produtos = Observable<List<ProdutoImpulso>>(const []);
  final parametros = Observable<List<ParametroImpulso>>(const []);
  final carregando = Observable<bool>(false);
  final erro = Observable<String?>(null);

  Future<void> trocarAba(AbaImpulsos nova) {
    runInAction(() => aba.value = nova);
    return carregar();
  }

  Future<void> carregar() async {
    runInAction(() {
      carregando.value = true;
      erro.value = null;
    });
    try {
      switch (aba.value) {
        case AbaImpulsos.textos:
          final lista = await _repo.textos();
          runInAction(() => textos.value = lista);
        case AbaImpulsos.impulsos:
          final pagina = await _repo.impulsos(situacao: situacao.value, busca: busca.value);
          runInAction(() => impulsos.value = pagina);
        case AbaImpulsos.casas:
          final r = await _repo.casas(busca: buscaCasas.value, soHabilitadas: soHabilitadas.value);
          runInAction(() => casas.value = r.itens);
        case AbaImpulsos.configuracoes:
          final p = await _repo.produtos();
          final q = await _repo.parametros();
          runInAction(() {
            produtos.value = p;
            parametros.value = q;
          });
      }
      await atualizarContagem();
    } on SessaoExpiradaException {
      // o app já volta para o login
    } catch (e) {
      runInAction(() => erro.value = '$e');
    } finally {
      runInAction(() => carregando.value = false);
    }
  }

  Future<void> atualizarContagem() async {
    try {
      final n = await _repo.textosEmAnalise();
      runInAction(() => textosEmAnalise.value = n);
    } catch (_) {
      // o número do menu é melhor esforço
    }
  }

  Future<void> filtrarImpulsos({SituacaoImpulso? novaSituacao, bool limparSituacao = false, String? novaBusca}) {
    runInAction(() {
      if (limparSituacao) {
        situacao.value = null;
      } else if (novaSituacao != null) {
        situacao.value = novaSituacao;
      }
      if (novaBusca != null) busca.value = novaBusca;
    });
    return carregar();
  }

  Future<void> filtrarCasas({String? novaBusca, bool? habilitadas}) {
    runInAction(() {
      if (novaBusca != null) buscaCasas.value = novaBusca;
      if (habilitadas != null) soHabilitadas.value = habilitadas;
    });
    return carregar();
  }

  Future<void> aprovar(String campanhaId) async {
    await _repo.aprovarTexto(campanhaId);
    await carregar();
  }

  Future<void> recusar(String campanhaId, String motivo) async {
    await _repo.recusarTexto(campanhaId, motivo);
    await carregar();
  }

  Future<void> definirFlag(String casaId, bool habilitada, String? motivo) async {
    await _repo.definirFlag(casaId, habilitada: habilitada, motivo: motivo);
    await carregar();
  }

  Future<List<HistoricoFlag>> historico(String casaId) => _repo.historico(casaId);

  Future<void> ajustarProduto(String id, {int? alcance, required bool ativo}) async {
    await _repo.ajustarProduto(id, alcance: alcance, ativo: ativo);
    await carregar();
  }

  Future<void> definirParametro(String chave, int valor) async {
    await _repo.definirParametro(chave, valor);
    await carregar();
  }

  Future<ImpulsoDetalhe> detalhe(String id) => _repo.detalhe(id);

  Future<void> estornar(String id) => _repo.estornar(id);

  void limpar() {
    runInAction(() {
      aba.value = AbaImpulsos.textos;
      textosEmAnalise.value = 0;
      textos.value = const [];
      impulsos.value = PaginaImpulsos.vazia;
      situacao.value = null;
      busca.value = '';
      casas.value = const [];
      buscaCasas.value = '';
      soHabilitadas.value = false;
      produtos.value = const [];
      parametros.value = const [];
    });
  }
}
