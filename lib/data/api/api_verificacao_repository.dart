import 'dart:typed_data';

import '../models/verificacao.dart';
import '../repositories/repositories.dart';
import 'backoffice_api.dart';

/// E30 — verificações dos estabelecimentos (`/api/backoffice/verificacoes/**`).
class ApiVerificacaoRepository implements VerificacaoRepository {
  ApiVerificacaoRepository(this._api);

  final BackofficeApi _api;
  static const _base = '/api/backoffice/verificacoes';

  @override
  Future<PaginaVerificacoes> listar(FiltroVerificacoes filtro, {int pagina = 0}) async =>
      PaginaVerificacoes.fromJson(await _api.get(_base, query: {
        'situacao': filtro.situacao.api,
        if (filtro.tipo != null) 'tipo': filtro.tipo!.api,
        if (filtro.busca.trim().isNotEmpty) 'busca': filtro.busca.trim(),
        'page': '$pagina',
      }));

  @override
  Future<ContagemVerificacoes> contagem() async => ContagemVerificacoes.fromJson(await _api.get('$_base/contagem'));

  @override
  Future<VerificacaoDetalhe> detalhe(String id) async => VerificacaoDetalhe.fromJson(await _api.get('$_base/$id'));

  @override
  Future<({Uint8List bytes, String contentType})> arquivo(String id, String arquivoId) =>
      _api.bytes('$_base/$id/documentos/$arquivoId/arquivo');

  @override
  Future<VerificacaoDetalhe> aprovar(String id, {String? observacaoInterna}) async =>
      VerificacaoDetalhe.fromJson(await _api.post('$_base/$id/aprovacao', corpo: {
        if (observacaoInterna != null && observacaoInterna.trim().isNotEmpty)
          'observacaoInterna': observacaoInterna.trim(),
      }));

  @override
  Future<VerificacaoDetalhe> reprovar(String id,
          {List<RecusaDeArquivo> recusas = const [], String? mensagem, String? observacaoInterna}) async =>
      VerificacaoDetalhe.fromJson(await _api.post('$_base/$id/reprovacao', corpo: {
        'documentos': [for (final r in recusas) r.toJson()],
        if (mensagem != null && mensagem.trim().isNotEmpty) 'mensagem': mensagem.trim(),
        if (observacaoInterna != null && observacaoInterna.trim().isNotEmpty)
          'observacaoInterna': observacaoInterna.trim(),
      }));
}
