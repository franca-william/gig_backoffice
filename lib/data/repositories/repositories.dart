import 'dart:typed_data';

import '../models/dashboard.dart';
import '../models/denuncia.dart';
import '../models/impulso.dart';
import '../models/models.dart';
import '../models/usuario.dart';
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

/// E31 — outra pessoa da equipe já decidiu esta denúncia (409).
class DenunciaJaAnalisadaException implements Exception {
  const DenunciaJaAnalisadaException();
  @override
  String toString() => 'Outra pessoa da equipe acabou de decidir esta denúncia.';
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

/// E31 (E3 do backoffice) — denúncias de perfis. A decisão vale para todas as denúncias abertas sobre o mesmo perfil;
/// quem denunciou recebe "Analisamos sua denúncia" e quem foi denunciado, o aviso da equipe (menos no banimento).
abstract interface class DenunciaRepository {
  Future<PaginaDenuncias> listar(FiltroDenuncias filtro, {int pagina = 0});
  Future<ContagemDenuncias> contagem();
  Future<DenunciaDetalhe> detalhe(String id);

  /// Foto do retrato (cópia privada, baixada com o token). Cada abertura é auditada.
  Future<({Uint8List bytes, String contentType})> foto(String id);

  /// Lança [DenunciaJaAnalisadaException] (409) se outra pessoa decidiu antes.
  Future<DenunciaDetalhe> decidir(String id, DecisaoDenuncia decisao);
}

/// E1 — dashboard em abas. Uma chamada por aba; [atualizar] ignora o cache de 5 min do backend.
abstract interface class DashboardRepository {
  Future<Atencao> atencao();
  Future<Marketplace> marketplace(int periodo, {bool atualizar = false});
  Future<Crescimento> crescimento(int periodo, {bool atualizar = false});
  Future<Curtidores> curtidores(int periodo, {bool atualizar = false});
  Future<Qualidade> qualidade(int periodo, {bool atualizar = false});
}

/// E5 (backoffice) — consulta de usuários (somente leitura).
abstract interface class UsuarioRepository {
  Future<PaginaUsuarios> listar(FiltroUsuarios filtro, {int pagina = 0});
  Future<UsuarioDetalhe> detalhe(String id);
}

/// E40 — Impulsionar evento: textos de push para aprovar, impulsos (estorno só no Google Play), a flag "passível de
/// impulsionar" por casa (com histórico), pacotes e parâmetros. Toda alteração fica na auditoria do backend.
abstract interface class ImpulsoRepository {
  /// Número do menu: textos de push esperando a equipe.
  Future<int> textosEmAnalise();
  Future<List<TextoPush>> textos();
  Future<void> aprovarTexto(String campanhaId);
  Future<void> recusarTexto(String campanhaId, String motivo);
  Future<PaginaImpulsos> impulsos({SituacaoImpulso? situacao, String busca = '', int pagina = 0});
  Future<ImpulsoDetalhe> detalhe(String id);
  Future<void> estornar(String id);
  Future<({List<CasaImpulso> itens, int totalPaginas})> casas(
      {String busca = '', bool soHabilitadas = false, int pagina = 0});
  Future<List<HistoricoFlag>> historico(String casaId);
  Future<void> definirFlag(String casaId, {required bool habilitada, String? motivo});
  Future<List<ProdutoImpulso>> produtos();
  Future<ProdutoImpulso> ajustarProduto(String id, {int? alcance, required bool ativo});
  Future<List<ParametroImpulso>> parametros();
  Future<ParametroImpulso> definirParametro(String chave, int valor);
}
