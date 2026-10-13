import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../repositories/repositories.dart';
import 'cliente_http.dart';

/// Endereço da API. Em produção o Nginx serve o backoffice e a API no MESMO endereço, então a base é vazia
/// (`/api/...`). No dev: `flutter run -d chrome --web-port 5173 --dart-define=GIG_API=http://localhost:8080`.
const String gigApiBase = String.fromEnvironment('GIG_API');

/// Fala com `/api/backoffice/**` (como o `GigApi` do app).
///
/// - Access token SÓ em memória (nada guardado no armazenamento do navegador).
/// - O refresh token vai no cookie `gig_bo_sessao` (HttpOnly): o navegador manda sozinho nas rotas de sessão.
/// - Todas as chamadas levam `X-GiG-Backoffice: 1`.
/// - 401 numa chamada comum → renova pelo cookie UMA vez e repete; se não der, avisa [aoExpirar].
class BackofficeApi {
  BackofficeApi({String base = gigApiBase, http.Client? cliente})
      : _base = base.endsWith('/') ? base.substring(0, base.length - 1) : base,
        _cliente = cliente ?? criarClienteHttp();

  static const cabecalhoBackoffice = 'X-GiG-Backoffice';
  static const caminhoSessao = '/api/backoffice/sessao';

  final String _base;
  final http.Client _cliente;
  String? _accessToken;
  Future<Map<String, dynamic>?>? _renovacaoEmAndamento;

  /// Chamado quando a sessão acabou de vez (renovação falhou) — o app volta para o login.
  void Function()? aoExpirar;

  bool get temToken => _accessToken != null;

  Uri _uri(String caminho, [Map<String, String>? query]) {
    final uri = Uri.parse('$_base$caminho');
    return query == null || query.isEmpty
        ? uri
        : uri.replace(queryParameters: query);
  }

  Map<String, String> _cabecalhos({bool comToken = true, bool json = false}) =>
      {
        'Accept': 'application/json',
        cabecalhoBackoffice: '1',
        if (json) 'Content-Type': 'application/json',
        if (comToken && _accessToken != null)
          'Authorization': 'Bearer $_accessToken',
      };

  // ---------- sessão ----------

  Future<Map<String, dynamic>> entrar(String login, String senha) async {
    final resposta = await _cliente.post(_uri(caminhoSessao),
        headers: _cabecalhos(comToken: false, json: true),
        body: jsonEncode({'login': login, 'senha': senha}));
    if (resposta.statusCode == 401) throw const CredenciaisInvalidasException();
    final corpo = _json(resposta);
    _accessToken = corpo['accessToken'] as String?;
    return corpo;
  }

  /// Renova pelo cookie. Nulo = sem sessão (sem cookie, vencido ou acesso desligado).
  /// Chamadas simultâneas compartilham a mesma renovação (o refresh gira e não pode ser usado duas vezes).
  Future<Map<String, dynamic>?> renovar() {
    return _renovacaoEmAndamento ??=
        _renovar().whenComplete(() => _renovacaoEmAndamento = null);
  }

  Future<Map<String, dynamic>?> _renovar() async {
    try {
      final resposta = await _cliente.post(_uri('$caminhoSessao/renovacao'),
          headers: _cabecalhos(comToken: false));
      if (resposta.statusCode != 200) {
        _accessToken = null;
        return null;
      }
      final corpo = _json(resposta);
      _accessToken = corpo['accessToken'] as String?;
      return corpo;
    } on http.ClientException {
      _accessToken = null;
      return null;
    }
  }

  Future<void> sair() async {
    try {
      await _cliente.delete(_uri(caminhoSessao),
          headers: _cabecalhos(comToken: false));
    } finally {
      _accessToken = null;
    }
  }

  // ---------- chamadas autenticadas ----------

  Future<Map<String, dynamic>> get(String caminho,
          {Map<String, String>? query}) =>
      _autenticada(
          () => _cliente.get(_uri(caminho, query), headers: _cabecalhos()));

  Future<Map<String, dynamic>> post(String caminho, {Object? corpo}) =>
      _autenticada(() => _cliente.post(
            _uri(caminho),
            headers: _cabecalhos(json: corpo != null),
            body: corpo == null ? null : jsonEncode(corpo),
          ));

  /// E30 — conteúdo binário (arquivo da verificação), com a mesma renovação de sessão das outras chamadas.
  Future<({Uint8List bytes, String contentType})> bytes(String caminho) async {
    final resposta =
        await _autenticadaBruta(() => _cliente.get(_uri(caminho), headers: {
              ..._cabecalhos(),
              'Accept': '*/*',
            }));
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      _json(resposta); // lança o erro com a mensagem do backend
    }
    return (
      bytes: resposta.bodyBytes,
      contentType:
          resposta.headers['content-type'] ?? 'application/octet-stream'
    );
  }

  Future<Map<String, dynamic>> _autenticada(
          Future<http.Response> Function() chamar) async =>
      _json(await _autenticadaBruta(chamar));

  Future<http.Response> _autenticadaBruta(
      Future<http.Response> Function() chamar) async {
    if (_accessToken == null && await renovar() == null) {
      _expirou();
    }
    var resposta = await chamar();
    if (resposta.statusCode == 401) {
      if (await renovar() == null) _expirou();
      resposta = await chamar();
      if (resposta.statusCode == 401) _expirou();
    }
    if (resposta.statusCode == 403) {
      // Token válido, mas o acesso ao backoffice foi desligado no banco.
      _accessToken = null;
      _expirou();
    }
    return resposta;
  }

  Never _expirou() {
    _accessToken = null;
    aoExpirar?.call();
    throw const SessaoExpiradaException();
  }

  Map<String, dynamic> _json(http.Response resposta) {
    final texto = utf8.decode(resposta.bodyBytes);
    final Object? corpo = texto.isEmpty ? null : jsonDecode(texto);
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      return corpo is Map<String, dynamic> ? corpo : <String, dynamic>{};
    }
    final problema =
        corpo is Map<String, dynamic> ? corpo : const <String, dynamic>{};
    if (resposta.statusCode == 409 &&
        problema['codigo'] == 'sugestao-ja-respondida') {
      throw const SugestaoJaRespondidaException();
    }
    if (resposta.statusCode == 409 &&
        problema['codigo'] == 'verificacao-ja-analisada') {
      throw const VerificacaoJaAnalisadaException();
    }
    throw BackofficeException(problema['detail'] as String? ??
        'Não foi possível completar (erro ${resposta.statusCode}).');
  }
}
