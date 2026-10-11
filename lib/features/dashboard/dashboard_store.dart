import 'package:mobx/mobx.dart';

import '../../data/models/dashboard.dart';
import '../../data/repositories/repositories.dart';

/// Estado de uma aba: carregando, pronta (com [dado]) ou com [erro].
class EstadoAba {
  const EstadoAba({this.carregando = false, this.dado, this.erro, this.periodo});

  static const vazio = EstadoAba();

  final bool carregando;
  final Object? dado;
  final String? erro;

  /// Período com que [dado] foi carregado (nulo na aba Pontos de atenção).
  final int? periodo;

  bool get carregada => dado != null;

  DateTime? get geradoEm => switch (dado) {
        final Atencao a => a.geradoEm,
        final Marketplace m => m.geradoEm,
        final Crescimento c => c.geradoEm,
        final Curtidores c => c.geradoEm,
        final Qualidade q => q.geradoEm,
        _ => null,
      };
}

/// Dashboard em abas (MobX sem codegen, como o resto do backoffice).
///
/// - Cada aba carrega só quando é aberta pela primeira vez; trocar de aba e voltar usa o estado guardado.
/// - Trocar o período recarrega a aba atual (as outras recarregam quando forem abertas).
/// - Atualizar manda `atualizar=true` (ignora o cache de 5 min do backend).
/// - O total da aba Pontos de atenção é o contador da aba e do menu.
class DashboardStore {
  DashboardStore(this._repo);

  final DashboardRepository _repo;

  final aba = Observable<AbaDashboard>(AbaDashboard.atencao);
  final periodo = Observable<int>(PeriodoDashboard.padrao);
  final estados = ObservableMap<AbaDashboard, EstadoAba>();

  final Map<AbaDashboard, int> _versao = {};

  EstadoAba estado(AbaDashboard a) => estados[a] ?? EstadoAba.vazio;

  EstadoAba get atual => estado(aba.value);

  /// Pontos de atenção pendentes (aba e menu). Zero enquanto não carregou.
  late final contador = Computed<int>(() {
    final dado = estado(AbaDashboard.atencao).dado;
    return dado is Atencao ? dado.total : 0;
  });

  /// Vem da URL (`/dashboard?aba=...&periodo=...`). Carrega a aba se ainda não tem dados para este período.
  Future<void> abrir(AbaDashboard novaAba, int novoPeriodo) {
    runInAction(() {
      aba.value = novaAba;
      periodo.value = novoPeriodo;
    });
    final e = estado(novaAba);
    final precisaCarregar = !e.carregando && (!e.carregada || (novaAba.temPeriodo && e.periodo != novoPeriodo));
    return precisaCarregar ? carregar(novaAba) : Future.value();
  }

  /// Botão Atualizar: recarrega a aba atual ignorando o cache.
  Future<void> atualizar() => carregar(aba.value, atualizar: true);

  /// "Tentar de novo" depois de um erro.
  Future<void> tentarDeNovo() => carregar(aba.value);

  /// O menu lateral mostra o contador mesmo fora do dashboard (carrega a aba Pontos de atenção).
  Future<void> atualizarContador() {
    if (estado(AbaDashboard.atencao).carregando) return Future.value();
    return carregar(AbaDashboard.atencao);
  }

  Future<void> carregar(AbaDashboard a, {bool atualizar = false}) async {
    final versao = (_versao[a] ?? 0) + 1;
    _versao[a] = versao;
    final p = a.temPeriodo ? periodo.value : null;
    final anterior = estado(a);
    runInAction(() => estados[a] = EstadoAba(carregando: true, dado: anterior.dado, periodo: anterior.periodo));
    try {
      final Object dado = switch (a) {
        AbaDashboard.atencao => await _repo.atencao(),
        AbaDashboard.marketplace => await _repo.marketplace(p!, atualizar: atualizar),
        AbaDashboard.crescimento => await _repo.crescimento(p!, atualizar: atualizar),
        AbaDashboard.curtidores => await _repo.curtidores(p!, atualizar: atualizar),
        AbaDashboard.qualidade => await _repo.qualidade(p!, atualizar: atualizar),
      };
      if (_versao[a] != versao) return; // um pedido mais novo (outro período) já saiu
      runInAction(() => estados[a] = EstadoAba(dado: dado, periodo: p));
    } on SessaoExpiradaException {
      if (_versao[a] == versao) runInAction(() => estados[a] = EstadoAba.vazio);
    } catch (e) {
      if (_versao[a] == versao) runInAction(() => estados[a] = EstadoAba(erro: '$e', periodo: p));
    }
  }

  /// Sair: nada da sessão anterior fica na memória.
  void limpar() {
    runInAction(() {
      estados.clear();
      aba.value = AbaDashboard.atencao;
      periodo.value = PeriodoDashboard.padrao;
    });
    _versao.clear();
  }
}
