import '../models/impulso.dart';
import '../repositories/repositories.dart';
import 'mock_repositories.dart';

/// E40 — impulsos de exemplo: 3 casas (uma habilitada), 3 impulsos (card no ar, notificação com texto em análise e
/// um reembolsado), os 4 produtos e os parâmetros padrão.
class MockImpulsoRepository implements ImpulsoRepository {
  MockImpulsoRepository({Relogio? relogio}) : _agora = relogio ?? DateTime.now {
    final agora = _agora();
    _casas.addAll([
      const CasaImpulso(id: 'c1', nome: 'Bar do Zé', cidade: 'Fortaleza', estado: 'CE', verificada: true,
          habilitada: true, impulsosPagos: 3),
      const CasaImpulso(id: 'c2', nome: 'Casa do Samba', cidade: 'Recife', estado: 'PE'),
      const CasaImpulso(id: 'c3', nome: 'Pub da Esquina', cidade: 'Fortaleza', estado: 'CE', verificada: true),
    ]);
    _historico['c1'] = [
      HistoricoFlag(quando: agora.subtract(const Duration(days: 10)), valorNovo: true, alteradoPor: 'Equipe GiG',
          motivo: 'Casa parceira'),
    ];
    _impulsos.addAll([
      ImpulsoResumo(id: 'i1', produto: 'CARD_HOME', nomeProduto: 'Card de destaque na Home',
          situacao: SituacaoImpulso.pago, casa: 'Bar do Zé', evento: 'Forró do Zé',
          dataEvento: agora.add(const Duration(days: 4)), loja: 'GOOGLE_PLAY', ambiente: 'PRODUCAO',
          pagoEm: agora.subtract(const Duration(hours: 5))),
      ImpulsoResumo(id: 'i2', produto: 'PUSH_PROXIMOS', nomeProduto: 'Notificação para até 200 curtidores',
          situacao: SituacaoImpulso.pago, casa: 'Bar do Zé', evento: 'Samba de Roda',
          dataEvento: agora.add(const Duration(days: 2)), loja: 'APP_STORE', ambiente: 'PRODUCAO',
          pagoEm: agora.subtract(const Duration(hours: 2)), push: SituacaoPush.emAnalise),
      ImpulsoResumo(id: 'i3', produto: 'CARD_HOME', nomeProduto: 'Card de destaque na Home',
          situacao: SituacaoImpulso.estornado, casa: 'Bar do Zé', evento: 'Rock na Laje',
          dataEvento: agora.subtract(const Duration(days: 3)), loja: 'GOOGLE_PLAY', ambiente: 'PRODUCAO',
          pagoEm: agora.subtract(const Duration(days: 6))),
    ]);
    _textos.add(TextoPush(
      campanhaId: 't1',
      impulsoId: 'i2',
      casa: 'Bar do Zé',
      evento: 'Samba de Roda',
      dataEvento: agora.add(const Duration(days: 2)),
      titulo: 'Hoje tem roda de samba!',
      texto: 'Chega cedo que lota. Primeira cerveja por nossa conta.',
      tituloModelo: 'Samba de Roda no Bar do Zé 🎶',
      textoModelo: 'Sáb 17/10 às 21h · Samba. Toque para ver quem vai.',
      prazo: agora.add(const Duration(days: 2)).subtract(const Duration(hours: 6)),
    ));
  }

  final Relogio _agora;
  final _casas = <CasaImpulso>[];
  final _historico = <String, List<HistoricoFlag>>{};
  final _impulsos = <ImpulsoResumo>[];
  final _textos = <TextoPush>[];
  final _produtos = <ProdutoImpulso>[
    const ProdutoImpulso(id: 'p1', codigo: 'CARD_HOME', produtoLojaId: 'impulso_card_home',
        nome: 'Card de destaque na Home', precoReferenciaCentavos: 1790, ativo: true),
    const ProdutoImpulso(id: 'p2', codigo: 'PUSH_PROXIMOS', produtoLojaId: 'impulso_push_200',
        nome: 'Notificação para até 200 curtidores', alcance: 200, precoReferenciaCentavos: 1000, ativo: true),
    const ProdutoImpulso(id: 'p3', codigo: 'PUSH_PROXIMOS', produtoLojaId: 'impulso_push_500',
        nome: 'Notificação para até 500 curtidores', alcance: 500, precoReferenciaCentavos: 2490, ativo: true),
    const ProdutoImpulso(id: 'p4', codigo: 'PUSH_PROXIMOS', produtoLojaId: 'impulso_push_1000',
        nome: 'Notificação para até 1.000 curtidores', alcance: 1000, precoReferenciaCentavos: 4990, ativo: true),
  ];
  final _parametros = <ParametroImpulso>[
    const ParametroImpulso(chave: 'card_home.visiveis_por_vez', valor: 3, minimo: 1, maximo: 10),
    const ParametroImpulso(chave: 'pedido.expira_minutos', valor: 30, minimo: 5, maximo: 240),
    const ParametroImpulso(chave: 'push.limite_por_curtidor_dia', valor: 1, minimo: 1, maximo: 5),
    const ParametroImpulso(chave: 'push.limite_por_curtidor_semana', valor: 3, minimo: 1, maximo: 20),
    const ParametroImpulso(chave: 'push.prazo_aprovacao_horas', valor: 6, minimo: 1, maximo: 72),
    const ParametroImpulso(chave: 'push.silencio_fim_hora', valor: 9, minimo: 0, maximo: 23),
    const ParametroImpulso(chave: 'push.silencio_inicio_hora', valor: 23, minimo: 0, maximo: 23),
  ];

  /// Ids das casas com a flag (testes).
  Iterable<String> get habilitadas => _casas.where((c) => c.habilitada).map((c) => c.id);

  Future<void> _rede() => Future<void>.delayed(const Duration(milliseconds: 50));

  @override
  Future<int> textosEmAnalise() async {
    await _rede();
    return _textos.length;
  }

  @override
  Future<List<TextoPush>> textos() async {
    await _rede();
    return List.of(_textos)..sort((a, b) => a.dataEvento.compareTo(b.dataEvento));
  }

  @override
  Future<void> aprovarTexto(String campanhaId) async {
    await _rede();
    _textos.removeWhere((t) => t.campanhaId == campanhaId);
  }

  @override
  Future<void> recusarTexto(String campanhaId, String motivo) async {
    await _rede();
    if (motivo.trim().length < 3) throw const BackofficeException('Explique o motivo da recusa.');
    _textos.removeWhere((t) => t.campanhaId == campanhaId);
  }

  @override
  Future<PaginaImpulsos> impulsos({SituacaoImpulso? situacao, String busca = '', int pagina = 0}) async {
    await _rede();
    final b = busca.trim().toLowerCase();
    final itens = _impulsos
        .where((i) => (situacao == null || i.situacao == situacao) &&
            (b.isEmpty || i.casa.toLowerCase().contains(b) || i.evento.toLowerCase().contains(b)))
        .toList();
    return PaginaImpulsos(itens: itens, pagina: 0, totalPaginas: itens.isEmpty ? 0 : 1, total: itens.length);
  }

  @override
  Future<ImpulsoDetalhe> detalhe(String id) async {
    await _rede();
    final r = _impulsos.firstWhere((i) => i.id == id);
    return ImpulsoDetalhe(
      resumo: r,
      casaId: 'c1',
      alcanceContratado: r.ehCard ? null : 200,
      pushTitulo: r.ehCard ? null : 'Hoje tem roda de samba!',
      pushTexto: r.ehCard ? null : 'Chega cedo que lota.',
      pushEditado: !r.ehCard,
      impressoes: r.ehCard ? 420 : 0,
      toques: r.ehCard ? 37 : 0,
      presencas: r.ehCard ? 9 : 0,
      idTransacao: r.loja == 'GOOGLE_PLAY' ? 'GPA.3312-4410-5521-${r.id}' : '2000000${r.id.hashCode.abs()}',
      compraEstornada: r.situacao == SituacaoImpulso.estornado,
      podeEstornar: r.loja == 'GOOGLE_PLAY' && r.situacao != SituacaoImpulso.estornado,
    );
  }

  @override
  Future<void> estornar(String id) async {
    await _rede();
    final i = _impulsos.indexWhere((x) => x.id == id);
    final r = _impulsos[i];
    if (r.loja == 'APP_STORE') {
      throw const BackofficeException('Compras da App Store só são reembolsadas pela Apple, a pedido do cliente.');
    }
    _impulsos[i] = ImpulsoResumo(id: r.id, produto: r.produto, nomeProduto: r.nomeProduto,
        situacao: SituacaoImpulso.estornado, casa: r.casa, evento: r.evento, dataEvento: r.dataEvento, loja: r.loja,
        ambiente: r.ambiente, pagoEm: r.pagoEm, push: r.push);
  }

  @override
  Future<({List<CasaImpulso> itens, int totalPaginas})> casas(
      {String busca = '', bool soHabilitadas = false, int pagina = 0}) async {
    await _rede();
    final b = busca.trim().toLowerCase();
    final itens = _casas
        .where((c) => (!soHabilitadas || c.habilitada) &&
            (b.isEmpty || c.nome.toLowerCase().contains(b) || (c.cidade ?? '').toLowerCase().contains(b)))
        .toList()
      ..sort((a, b) => a.habilitada == b.habilitada ? a.nome.compareTo(b.nome) : (a.habilitada ? -1 : 1));
    return (itens: itens, totalPaginas: itens.isEmpty ? 0 : 1);
  }

  @override
  Future<List<HistoricoFlag>> historico(String casaId) async {
    await _rede();
    return List.of(_historico[casaId] ?? const []);
  }

  @override
  Future<void> definirFlag(String casaId, {required bool habilitada, String? motivo}) async {
    await _rede();
    final i = _casas.indexWhere((c) => c.id == casaId);
    if (_casas[i].habilitada == habilitada) return;
    _casas[i] = _casas[i].comHabilitada(habilitada);
    (_historico[casaId] ??= []).insert(
        0, HistoricoFlag(quando: _agora(), valorNovo: habilitada, alteradoPor: 'Equipe GiG', motivo: motivo));
  }

  @override
  Future<List<ProdutoImpulso>> produtos() async {
    await _rede();
    return List.of(_produtos);
  }

  @override
  Future<ProdutoImpulso> ajustarProduto(String id, {int? alcance, required bool ativo}) async {
    await _rede();
    final i = _produtos.indexWhere((p) => p.id == id);
    final p = _produtos[i];
    final novo = ProdutoImpulso(id: p.id, codigo: p.codigo, produtoLojaId: p.produtoLojaId, nome: p.nome,
        alcance: p.codigo == 'PUSH_PROXIMOS' ? (alcance ?? p.alcance) : null,
        precoReferenciaCentavos: p.precoReferenciaCentavos, ativo: ativo);
    _produtos[i] = novo;
    return novo;
  }

  @override
  Future<List<ParametroImpulso>> parametros() async {
    await _rede();
    return List.of(_parametros);
  }

  @override
  Future<ParametroImpulso> definirParametro(String chave, int valor) async {
    await _rede();
    final i = _parametros.indexWhere((p) => p.chave == chave);
    final p = _parametros[i];
    if (valor < p.minimo || valor > p.maximo) {
      throw BackofficeException('Use um valor entre ${p.minimo} e ${p.maximo}.');
    }
    return _parametros[i] = ParametroImpulso(chave: chave, valor: valor, minimo: p.minimo, maximo: p.maximo);
  }
}
