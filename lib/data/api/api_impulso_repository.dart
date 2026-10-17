import '../models/impulso.dart';
import '../repositories/repositories.dart';
import 'backoffice_api.dart';

/// E40 — impulsos (`/api/backoffice/impulsos/**`).
class ApiImpulsoRepository implements ImpulsoRepository {
  ApiImpulsoRepository(this._api);

  final BackofficeApi _api;
  static const _base = '/api/backoffice/impulsos';

  @override
  Future<int> textosEmAnalise() async =>
      ((await _api.get('$_base/contagem'))['textosEmAnalise'] as num?)?.toInt() ?? 0;

  @override
  Future<List<TextoPush>> textos() async {
    final pagina = await _api.get('$_base/textos', query: {'page': '0'});
    return [for (final t in (pagina['itens'] as List<dynamic>? ?? const [])) TextoPush.fromJson(t as Map<String, dynamic>)];
  }

  @override
  Future<void> aprovarTexto(String campanhaId) => _api.post('$_base/textos/$campanhaId/aprovacao');

  @override
  Future<void> recusarTexto(String campanhaId, String motivo) =>
      _api.post('$_base/textos/$campanhaId/recusa', corpo: {'motivo': motivo.trim()});

  @override
  Future<PaginaImpulsos> impulsos({SituacaoImpulso? situacao, String busca = '', int pagina = 0}) async =>
      PaginaImpulsos.fromJson(await _api.get(_base, query: {
        if (situacao != null) 'situacao': situacao.api,
        if (busca.trim().isNotEmpty) 'busca': busca.trim(),
        'page': '$pagina',
      }));

  @override
  Future<ImpulsoDetalhe> detalhe(String id) async => ImpulsoDetalhe.fromJson(await _api.get('$_base/$id'));

  @override
  Future<void> estornar(String id) => _api.post('$_base/$id/estorno');

  @override
  Future<({List<CasaImpulso> itens, int totalPaginas})> casas(
      {String busca = '', bool soHabilitadas = false, int pagina = 0}) async {
    final j = await _api.get('$_base/casas', query: {
      if (busca.trim().isNotEmpty) 'busca': busca.trim(),
      if (soHabilitadas) 'habilitadas': 'true',
      'page': '$pagina',
    });
    return (
      itens: [for (final c in (j['itens'] as List<dynamic>? ?? const [])) CasaImpulso.fromJson(c as Map<String, dynamic>)],
      totalPaginas: (j['totalPaginas'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<List<HistoricoFlag>> historico(String casaId) async => [
        for (final h in await _api.getLista('$_base/casas/$casaId/historico'))
          HistoricoFlag.fromJson(h as Map<String, dynamic>),
      ];

  @override
  Future<void> definirFlag(String casaId, {required bool habilitada, String? motivo}) =>
      _api.put('$_base/casas/$casaId/flag', corpo: {
        'habilitada': habilitada,
        if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo.trim(),
      });

  @override
  Future<List<ProdutoImpulso>> produtos() async => [
        for (final p in await _api.getLista('$_base/produtos')) ProdutoImpulso.fromJson(p as Map<String, dynamic>),
      ];

  @override
  Future<ProdutoImpulso> ajustarProduto(String id, {int? alcance, required bool ativo}) async =>
      ProdutoImpulso.fromJson(await _api.put('$_base/produtos/$id', corpo: {
        if (alcance != null) 'alcance': alcance,
        'ativo': ativo,
      }));

  @override
  Future<List<ParametroImpulso>> parametros() async => [
        for (final p in await _api.getLista('$_base/parametros')) ParametroImpulso.fromJson(p as Map<String, dynamic>),
      ];

  @override
  Future<ParametroImpulso> definirParametro(String chave, int valor) async =>
      ParametroImpulso.fromJson(await _api.put('$_base/parametros/$chave', corpo: {'valor': valor}));
}
