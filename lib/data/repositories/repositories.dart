import '../models/dashboard.dart';
import '../models/models.dart';

/// Erros que as telas tratam.
class CredenciaisInvalidasException implements Exception {
  const CredenciaisInvalidasException();
  @override
  String toString() => 'E-mail ou senha inválidos.';
}

class SessaoExpiradaException implements Exception {
  const SessaoExpiradaException();
  @override
  String toString() => 'Sua sessão expirou. Entre de novo.';
}

class SugestaoJaRespondidaException implements Exception {
  const SugestaoJaRespondidaException();
  @override
  String toString() => 'Outra pessoa da equipe acabou de responder esta sugestão.';
}

class BackofficeException implements Exception {
  const BackofficeException(this.mensagem);
  final String mensagem;
  @override
  String toString() => mensagem;
}

/// Sessão do backoffice. O refresh token mora num cookie HttpOnly (o código nunca o vê);
/// o access token fica só em memória, dentro da implementação.
abstract interface class SessaoRepository {
  /// Lança [CredenciaisInvalidasException] (senha errada, sem acesso ou bloqueado — mesma mensagem).
  Future<Membro> entrar(String login, String senha);

  /// Tenta renovar pelo cookie (ao abrir/recarregar a página). Nulo = sem sessão.
  Future<Membro?> restaurar();

  Future<void> sair();
}

abstract interface class SugestaoRepository {
  Future<PaginaSugestoes> listar(FiltroSugestoes filtro, {int pagina = 0});
  Future<ContagemSugestoes> contagem();
  Future<SugestaoDetalhe> detalhe(String id);
  Future<void> marcarEmAnalise(String id);

  /// Lança [SugestaoJaRespondidaException] (409) se outra pessoa respondeu antes.
  Future<SugestaoDetalhe> responder(String id, String texto);
}

/// E1 — dashboard em abas. Uma chamada por aba; [atualizar] ignora o cache de 5 min do backend.
abstract interface class DashboardRepository {
  Future<Atencao> atencao();
  Future<Marketplace> marketplace(int periodo, {bool atualizar = false});
  Future<Crescimento> crescimento(int periodo, {bool atualizar = false});
  Future<Curtidores> curtidores(int periodo, {bool atualizar = false});
  Future<Qualidade> qualidade(int periodo, {bool atualizar = false});
}
