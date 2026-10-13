import 'dart:typed_data';

import '../models/dashboard.dart';
import '../models/models.dart';
import '../models/verificacao.dart';

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
  String toString() =>
      'Outra pessoa da equipe acabou de responder esta sugestão.';
}

/// E30 — outra pessoa da equipe já deu a devolutiva desta verificação (409).
class VerificacaoJaAnalisadaException implements Exception {
  const VerificacaoJaAnalisadaException();
  @override
  String toString() =>
      'Outra pessoa da equipe acabou de dar a devolutiva desta verificação.';
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

/// E30 — verificação dos estabelecimentos. Toda devolutiva (aprovar, pedir ajuste, recusar) notifica a casa no app.
abstract interface class VerificacaoRepository {
  Future<PaginaVerificacoes> listar(FiltroVerificacoes filtro,
      {int pagina = 0});
  Future<ContagemVerificacoes> contagem();
  Future<VerificacaoDetalhe> detalhe(String id);

  /// Conteúdo do arquivo (imagem ou PDF), baixado com o token: o arquivo nunca tem URL. Cada abertura é auditada.
  Future<({Uint8List bytes, String contentType})> arquivo(
      String id, String arquivoId);

  /// Lança [VerificacaoJaAnalisadaException] (409) se outra pessoa decidiu antes.
  Future<VerificacaoDetalhe> aprovar(String id, {String? observacaoInterna});

  /// Pedido com documentos: [recusas] (pelo menos uma). Sem CNPJ: [mensagem] obrigatória.
  Future<VerificacaoDetalhe> reprovar(String id,
      {List<RecusaDeArquivo> recusas = const [],
      String? mensagem,
      String? observacaoInterna});
}

/// E1 — dashboard em abas. Uma chamada por aba; [atualizar] ignora o cache de 5 min do backend.
abstract interface class DashboardRepository {
  Future<Atencao> atencao();
  Future<Marketplace> marketplace(int periodo, {bool atualizar = false});
  Future<Crescimento> crescimento(int periodo, {bool atualizar = false});
  Future<Curtidores> curtidores(int periodo, {bool atualizar = false});
  Future<Qualidade> qualidade(int periodo, {bool atualizar = false});
}
