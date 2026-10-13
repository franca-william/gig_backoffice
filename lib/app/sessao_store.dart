import 'package:mobx/mobx.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';

/// Sessão do backoffice. MobX sem codegen (Observable + Computed + runInAction), como no app.
class SessaoStore {
  SessaoStore(this._repo);

  final SessaoRepository _repo;

  final membro = Observable<Membro?>(null);

  /// Aviso para a tela de login ("Sua sessão expirou. Entre de novo.").
  final aviso = Observable<String?>(null);

  late final logado = Computed<bool>(() => membro.value != null);

  /// Ao abrir/recarregar a página: tenta renovar pelo cookie (o navegador manda sozinho).
  Future<void> restaurar() async {
    Membro? m;
    try {
      m = await _repo.restaurar();
    } catch (_) {
      m = null;
    }
    runInAction(() => membro.value = m);
  }

  /// Lança [CredenciaisInvalidasException].
  Future<void> entrar(String login, String senha) async {
    final m = await _repo.entrar(login, senha);
    runInAction(() {
      membro.value = m;
      aviso.value = null;
    });
  }

  Future<void> sair() async {
    try {
      await _repo.sair();
    } finally {
      runInAction(() => membro.value = null);
    }
  }

  /// A renovação falhou no meio do uso (cookie vencido ou acesso desligado): volta para o login.
  void expirou() {
    if (membro.value == null) return;
    runInAction(() {
      membro.value = null;
      aviso.value = 'Sua sessão expirou. Entre de novo.';
    });
  }
}
