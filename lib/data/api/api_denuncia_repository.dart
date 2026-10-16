import 'dart:typed_data';

import '../models/denuncia.dart';
import '../repositories/repositories.dart';
import 'backoffice_api.dart';

/// E31 (E3 do backoffice) — denúncias (`/api/backoffice/denuncias/**`).
class ApiDenunciaRepository implements DenunciaRepository {
  ApiDenunciaRepository(this._api);

  final BackofficeApi _api;
  static const _base = '/api/backoffice/denuncias';

  @override
  Future<PaginaDenuncias> listar(FiltroDenuncias filtro, {int pagina = 0}) async =>
      PaginaDenuncias.fromJson(await _api.get(_base, query: {
        'situacao': filtro.situacao.api,
        if (filtro.gravidade != null) 'gravidade': filtro.gravidade!.api,
        if (filtro.busca.trim().isNotEmpty) 'busca': filtro.busca.trim(),
        'page': '$pagina',
      }));

  @override
  Future<ContagemDenuncias> contagem() async => ContagemDenuncias.fromJson(await _api.get('$_base/contagem'));

  @override
  Future<DenunciaDetalhe> detalhe(String id) async => DenunciaDetalhe.fromJson(await _api.get('$_base/$id'));

  @override
  Future<({Uint8List bytes, String contentType})> foto(String id) => _api.bytes('$_base/$id/foto');

  @override
  Future<DenunciaDetalhe> decidir(String id, DecisaoDenuncia decisao) async =>
      DenunciaDetalhe.fromJson(await _api.post('$_base/$id/decisao', corpo: decisao.toJson()));
}
