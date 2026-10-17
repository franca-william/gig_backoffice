/// E40 — Impulsionar evento no backoffice: casas com a flag "passível de impulsionar", impulsos, textos de push para
/// aprovar, produtos (pacotes) e parâmetros.

enum SituacaoImpulso {
  aguardandoPagamento('AGUARDANDO_PAGAMENTO', 'Aguardando pagamento'),
  pago('PAGO', 'Em andamento'),
  expirado('EXPIRADO', 'Expirado'),
  encerradoPorCancelamento('ENCERRADO_POR_CANCELAMENTO', 'Evento cancelado'),
  estornado('ESTORNADO_PELA_LOJA', 'Reembolsado'),
  concluido('CONCLUIDO', 'Concluído');

  const SituacaoImpulso(this.api, this.rotulo);
  final String api;
  final String rotulo;

  static SituacaoImpulso deApi(String? v) => values.firstWhere((s) => s.api == v, orElse: () => pago);
}

enum SituacaoPush {
  aguardandoPagamento('AGUARDANDO_PAGAMENTO', 'Aguardando pagamento'),
  emAnalise('EM_ANALISE', 'Em análise'),
  recusada('RECUSADA', 'Recusada'),
  aprovada('APROVADA', 'Na fila'),
  enviando('ENVIANDO', 'Enviando'),
  concluida('CONCLUIDA', 'Enviada'),
  cancelada('CANCELADA', 'Cancelada');

  const SituacaoPush(this.api, this.rotulo);
  final String api;
  final String rotulo;

  static SituacaoPush? deApi(String? v) => v == null ? null : values.where((s) => s.api == v).firstOrNull;
}

DateTime? _data(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

class CasaImpulso {
  const CasaImpulso({
    required this.id,
    required this.nome,
    this.cidade,
    this.estado,
    this.verificada = false,
    this.habilitada = false,
    this.impulsosPagos = 0,
  });

  final String id;
  final String nome;
  final String? cidade;
  final String? estado;
  final bool verificada;
  final bool habilitada;
  final int impulsosPagos;

  String get local => [cidade, estado].whereType<String>().join(' / ');

  CasaImpulso comHabilitada(bool v) => CasaImpulso(
      id: id, nome: nome, cidade: cidade, estado: estado, verificada: verificada, habilitada: v,
      impulsosPagos: impulsosPagos);

  factory CasaImpulso.fromJson(Map<String, dynamic> j) => CasaImpulso(
        id: j['uuid'] as String,
        nome: j['nome'] as String? ?? '',
        cidade: j['cidade'] as String?,
        estado: j['estado'] as String?,
        verificada: j['verificada'] as bool? ?? false,
        habilitada: j['habilitada'] as bool? ?? false,
        impulsosPagos: (j['impulsosPagos'] as num?)?.toInt() ?? 0,
      );
}

class HistoricoFlag {
  const HistoricoFlag({required this.quando, required this.valorNovo, this.alteradoPor, this.motivo});

  final DateTime quando;
  final bool valorNovo;
  final String? alteradoPor;
  final String? motivo;

  factory HistoricoFlag.fromJson(Map<String, dynamic> j) => HistoricoFlag(
        quando: _data(j['quando']) ?? DateTime(1970),
        valorNovo: j['valorNovo'] as bool? ?? false,
        alteradoPor: j['alteradoPor'] as String?,
        motivo: j['motivo'] as String?,
      );
}

class ImpulsoResumo {
  const ImpulsoResumo({
    required this.id,
    required this.produto,
    required this.nomeProduto,
    required this.situacao,
    required this.casa,
    required this.evento,
    this.dataEvento,
    this.loja,
    this.ambiente,
    this.pagoEm,
    this.push,
  });

  final String id;

  /// CARD_HOME | PUSH_PROXIMOS
  final String produto;
  final String nomeProduto;
  final SituacaoImpulso situacao;
  final String casa;
  final String evento;
  final DateTime? dataEvento;
  final String? loja;
  final String? ambiente;
  final DateTime? pagoEm;
  final SituacaoPush? push;

  bool get ehCard => produto == 'CARD_HOME';

  factory ImpulsoResumo.fromJson(Map<String, dynamic> j) => ImpulsoResumo(
        id: j['uuid'] as String,
        produto: j['produto'] as String? ?? 'CARD_HOME',
        nomeProduto: j['nomeProduto'] as String? ?? '',
        situacao: SituacaoImpulso.deApi(j['situacao'] as String?),
        casa: j['casa'] as String? ?? '',
        evento: j['evento'] as String? ?? '',
        dataEvento: _data(j['dataEvento']),
        loja: j['loja'] as String?,
        ambiente: j['ambiente'] as String?,
        pagoEm: _data(j['pagoEm']),
        push: SituacaoPush.deApi(j['push'] as String?),
      );
}

class PaginaImpulsos {
  const PaginaImpulsos({required this.itens, required this.pagina, required this.totalPaginas, required this.total});

  static const vazia = PaginaImpulsos(itens: [], pagina: 0, totalPaginas: 0, total: 0);

  final List<ImpulsoResumo> itens;
  final int pagina;
  final int totalPaginas;
  final int total;

  factory PaginaImpulsos.fromJson(Map<String, dynamic> j) => PaginaImpulsos(
        itens: [for (final i in (j['itens'] as List<dynamic>? ?? const [])) ImpulsoResumo.fromJson(i as Map<String, dynamic>)],
        pagina: (j['pagina'] as num?)?.toInt() ?? 0,
        totalPaginas: (j['totalPaginas'] as num?)?.toInt() ?? 0,
        total: (j['total'] as num?)?.toInt() ?? 0,
      );
}

class ImpulsoDetalhe {
  const ImpulsoDetalhe({
    required this.resumo,
    required this.casaId,
    this.alcanceContratado,
    this.pushTitulo,
    this.pushTexto,
    this.pushEditado = false,
    this.motivoRecusa,
    this.enviados = 0,
    this.entregues = 0,
    this.impressoes = 0,
    this.toques = 0,
    this.presencas = 0,
    this.idTransacao,
    this.compraEstornada = false,
    this.podeEstornar = false,
  });

  final ImpulsoResumo resumo;
  final String casaId;
  final int? alcanceContratado;
  final String? pushTitulo;
  final String? pushTexto;
  final bool pushEditado;
  final String? motivoRecusa;
  final int enviados;
  final int entregues;
  final int impressoes;
  final int toques;
  final int presencas;
  final String? idTransacao;
  final bool compraEstornada;
  final bool podeEstornar;

  factory ImpulsoDetalhe.fromJson(Map<String, dynamic> j) {
    final i = j['impulso'] as Map<String, dynamic>? ?? const {};
    final evento = i['evento'] as Map<String, dynamic>? ?? const {};
    final push = i['push'] as Map<String, dynamic>?;
    final metricas = i['metricas'] as Map<String, dynamic>? ?? const {};
    final compra = j['compra'] as Map<String, dynamic>?;
    int n(Object? v) => (v as num?)?.toInt() ?? 0;
    return ImpulsoDetalhe(
      resumo: ImpulsoResumo(
        id: i['uuid'] as String? ?? '',
        produto: i['produto'] as String? ?? 'CARD_HOME',
        nomeProduto: i['nomeProduto'] as String? ?? '',
        situacao: SituacaoImpulso.deApi(i['situacao'] as String?),
        casa: j['casa'] as String? ?? '',
        evento: evento['titulo'] as String? ?? '',
        dataEvento: _data(evento['data']),
        loja: compra?['loja'] as String?,
        ambiente: compra?['ambiente'] as String?,
        pagoEm: _data(i['pagoEm']),
        push: SituacaoPush.deApi(push?['situacao'] as String?),
      ),
      casaId: j['casaUuid'] as String? ?? '',
      alcanceContratado: (i['alcanceContratado'] as num?)?.toInt(),
      pushTitulo: push?['titulo'] as String?,
      pushTexto: push?['texto'] as String?,
      pushEditado: push?['editado'] as bool? ?? false,
      motivoRecusa: push?['motivoRecusa'] as String?,
      enviados: n(push?['enviados']),
      entregues: n(push?['entregues']),
      impressoes: n(metricas['impressoes']),
      toques: n(metricas['toques']),
      presencas: n(metricas['presencas']),
      idTransacao: compra?['idTransacao'] as String?,
      compraEstornada: compra?['estornada'] as bool? ?? false,
      podeEstornar: j['podeEstornar'] as bool? ?? false,
    );
  }
}

class TextoPush {
  const TextoPush({
    required this.campanhaId,
    required this.impulsoId,
    required this.casa,
    required this.evento,
    required this.dataEvento,
    required this.titulo,
    required this.texto,
    required this.tituloModelo,
    required this.textoModelo,
    required this.prazo,
  });

  final String campanhaId;
  final String impulsoId;
  final String casa;
  final String evento;
  final DateTime dataEvento;
  final String titulo;
  final String texto;
  final String tituloModelo;
  final String textoModelo;

  /// Hora local: sem aprovação até aqui, vai o texto automático.
  final DateTime prazo;

  factory TextoPush.fromJson(Map<String, dynamic> j) {
    final dia = j['dataEvento'] as String? ?? '1970-01-01';
    final hora = j['horarioInicio'] as String? ?? '00:00';
    return TextoPush(
      campanhaId: j['campanha'] as String,
      impulsoId: j['impulso'] as String? ?? '',
      casa: j['casa'] as String? ?? '',
      evento: j['evento'] as String? ?? '',
      dataEvento: DateTime.tryParse('${dia}T$hora:00') ?? DateTime(1970),
      titulo: j['titulo'] as String? ?? '',
      texto: j['texto'] as String? ?? '',
      tituloModelo: j['tituloModelo'] as String? ?? '',
      textoModelo: j['textoModelo'] as String? ?? '',
      prazo: DateTime.tryParse(j['prazo'] as String? ?? '') ?? DateTime(1970),
    );
  }
}

class ProdutoImpulso {
  const ProdutoImpulso({
    required this.id,
    required this.codigo,
    required this.produtoLojaId,
    required this.nome,
    required this.precoReferenciaCentavos,
    required this.ativo,
    this.alcance,
  });

  final String id;
  final String codigo;
  final String produtoLojaId;
  final String nome;
  final int? alcance;
  final int precoReferenciaCentavos;
  final bool ativo;

  factory ProdutoImpulso.fromJson(Map<String, dynamic> j) => ProdutoImpulso(
        id: j['uuid'] as String,
        codigo: j['codigo'] as String? ?? '',
        produtoLojaId: j['produtoLojaId'] as String? ?? '',
        nome: j['nome'] as String? ?? '',
        alcance: (j['alcance'] as num?)?.toInt(),
        precoReferenciaCentavos: (j['precoReferenciaCentavos'] as num?)?.toInt() ?? 0,
        ativo: j['ativo'] as bool? ?? false,
      );
}

class ParametroImpulso {
  const ParametroImpulso({required this.chave, required this.valor, required this.minimo, required this.maximo});

  final String chave;
  final int valor;
  final int minimo;
  final int maximo;

  /// Rótulo da tela para cada chave.
  String get rotulo => switch (chave) {
        'card_home.visiveis_por_vez' => 'Destaques na Home ao mesmo tempo',
        'push.limite_por_curtidor_dia' => 'Notificações por curtidor por dia',
        'push.limite_por_curtidor_semana' => 'Notificações por curtidor por semana',
        'push.silencio_inicio_hora' => 'Silêncio começa (hora)',
        'push.silencio_fim_hora' => 'Silêncio termina (hora)',
        'push.prazo_aprovacao_horas' => 'Prazo para aprovar o texto (horas antes do evento)',
        'pedido.expira_minutos' => 'Validade do pedido sem pagamento (minutos)',
        _ => chave,
      };

  factory ParametroImpulso.fromJson(Map<String, dynamic> j) => ParametroImpulso(
        chave: j['chave'] as String,
        valor: (j['valor'] as num).toInt(),
        minimo: (j['minimo'] as num?)?.toInt() ?? 0,
        maximo: (j['maximo'] as num?)?.toInt() ?? 0,
      );
}
