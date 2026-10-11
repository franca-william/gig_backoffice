/// Modelos do dashboard (E1 do backoffice). JSON de `/api/backoffice/dashboard/**`.
///
/// A API já manda percentuais, medianas e variações calculados; aqui é só leitura. Campos nulos não vêm no JSON.
library;

Map<String, dynamic> _mapa(Object? json) => json is Map<String, dynamic> ? json : const <String, dynamic>{};

List<Map<String, dynamic>> _lista(Object? json) =>
    json is List ? json.whereType<Map<String, dynamic>>().toList() : const [];

double? _decimal(Object? v) => v is num ? v.toDouble() : null;

int _inteiro(Object? v) => v is num ? v.toInt() : 0;

String _texto(Object? v) => v is String ? v : '';

String? _textoOuNulo(Object? v) => v is String && v.isNotEmpty ? v : null;

bool _logico(Object? v) => v is bool && v;

DateTime? _data(Object? v) => v is String ? DateTime.tryParse(v) : null;

/// Abas do dashboard, na ordem da tela. [url] é o valor de `?aba=`.
enum AbaDashboard {
  atencao('atencao', 'Pontos de atenção'),
  marketplace('marketplace', 'Saúde do marketplace'),
  crescimento('crescimento', 'Crescimento'),
  curtidores('curtidores', 'Curtidores'),
  qualidade('qualidade', 'Qualidade e confiança');

  const AbaDashboard(this.url, this.rotulo);

  final String url;
  final String rotulo;

  /// A aba Pontos de atenção é sempre "agora": sem seletor de período e sem cache.
  bool get temPeriodo => this != AbaDashboard.atencao;

  static AbaDashboard deUrl(String? valor) =>
      values.where((a) => a.url == valor).firstOrNull ?? AbaDashboard.atencao;
}

/// Períodos aceitos (dias). Outro valor na URL cai no padrão (30).
abstract final class PeriodoDashboard {
  static const opcoes = [7, 30, 90];
  static const padrao = 30;

  static int deUrl(String? valor) {
    final n = int.tryParse(valor ?? '');
    return opcoes.contains(n) ? n! : padrao;
  }
}

/// Número de um cartão comparado com o período anterior de mesmo tamanho.
class Indicador {
  const Indicador({this.valor, this.anterior, this.variacaoPercentual, this.variacaoPontos, this.novo = false});

  /// Nulo = sem dados no período (ex.: taxa sem nenhum evento).
  final double? valor;
  final double? anterior;

  /// Variação relativa em % (contagens, médias e medianas).
  final double? variacaoPercentual;

  /// Variação em pontos percentuais (cartões que já são %).
  final double? variacaoPontos;

  /// Base anterior zero: a tela mostra "novo" em vez de %.
  final bool novo;

  factory Indicador.fromJson(Object? json) {
    final m = _mapa(json);
    return Indicador(
      valor: _decimal(m['valor']),
      anterior: _decimal(m['anterior']),
      variacaoPercentual: _decimal(m['variacaoPercentual']),
      variacaoPontos: _decimal(m['variacaoPontos']),
      novo: _logico(m['novo']),
    );
  }
}

// ---------------------------------------------------------------------------------------------------- aba 1

class Atencao {
  const Atencao({
    required this.geradoEm,
    required this.total,
    required this.cartoes,
    required this.eventosEmRisco,
    required this.contratos,
  });

  final DateTime? geradoEm;

  /// Soma dos itens pendentes (contador da aba e do menu).
  final int total;
  final AtencaoCartoes cartoes;
  final List<EventoEmRisco> eventosEmRisco;
  final List<ContratoComProblema> contratos;

  bool get vazia => total == 0 && cartoes.sugestoesAtrasadas == 0;

  factory Atencao.fromJson(Map<String, dynamic> json) => Atencao(
        geradoEm: _data(json['geradoEm']),
        total: _inteiro(json['total']),
        cartoes: AtencaoCartoes.fromJson(_mapa(json['cartoes'])),
        eventosEmRisco: _lista(json['eventosEmRisco']).map(EventoEmRisco.fromJson).toList(),
        contratos: _lista(json['contratos']).map(ContratoComProblema.fromJson).toList(),
      );
}

class AtencaoCartoes {
  const AtencaoCartoes({
    this.sugestoesSemResposta = 0,
    this.sugestoesAtrasadas = 0,
    this.eventosEmRisco = 0,
    this.eventosCriticos = 0,
    this.contratosSemAssinatura = 0,
    this.contratosTravados = 0,
  });

  final int sugestoesSemResposta;
  final int sugestoesAtrasadas;
  final int eventosEmRisco;

  /// Eventos em risco que começam em até 48 h.
  final int eventosCriticos;
  final int contratosSemAssinatura;
  final int contratosTravados;

  factory AtencaoCartoes.fromJson(Map<String, dynamic> json) => AtencaoCartoes(
        sugestoesSemResposta: _inteiro(json['sugestoesSemResposta']),
        sugestoesAtrasadas: _inteiro(json['sugestoesAtrasadas']),
        eventosEmRisco: _inteiro(json['eventosEmRisco']),
        eventosCriticos: _inteiro(json['eventosCriticos']),
        contratosSemAssinatura: _inteiro(json['contratosSemAssinatura']),
        contratosTravados: _inteiro(json['contratosTravados']),
      );
}

class EventoEmRisco {
  const EventoEmRisco({
    required this.id,
    required this.titulo,
    required this.inicio,
    required this.casa,
    this.cidade,
    this.estado,
    required this.contato,
    required this.situacao,
    required this.propostasPendentes,
    required this.horasParaComecar,
    required this.critico,
  });

  final String id;
  final String titulo;

  /// Hora local do evento (sem fuso).
  final DateTime? inicio;
  final String casa;
  final String? cidade;
  final String? estado;

  /// E-mail de login da casa.
  final String contato;

  /// ABERTO, RESERVADO ou SEM_MUSICO.
  final String situacao;
  final int propostasPendentes;
  final int horasParaComecar;

  /// Começa em até 48 h.
  final bool critico;

  String get situacaoRotulo => switch (situacao) {
        'ABERTO' => 'Aberto',
        'RESERVADO' => 'Reservado',
        'SEM_MUSICO' => 'Sem músico',
        _ => situacao,
      };

  factory EventoEmRisco.fromJson(Map<String, dynamic> json) => EventoEmRisco(
        id: _texto(json['uuid']),
        titulo: _texto(json['titulo']),
        inicio: _data(json['inicio']),
        casa: _texto(json['casa']),
        cidade: _textoOuNulo(json['cidade']),
        estado: _textoOuNulo(json['estado']),
        contato: _texto(json['contato']),
        situacao: _texto(json['situacao']),
        propostasPendentes: _inteiro(json['propostasPendentes']),
        horasParaComecar: _inteiro(json['horasParaComecar']),
        critico: _logico(json['critico']),
      );
}

class ContratoComProblema {
  const ContratoComProblema({
    required this.numero,
    required this.travado,
    required this.situacao,
    required this.evento,
    this.inicioEvento,
    required this.casa,
    required this.musico,
    this.desde,
    this.faltaAssinar = const [],
  });

  final String numero;

  /// GERANDO há mais de 10 min (falha no PDF). Senão, sem assinatura.
  final bool travado;
  final String situacao;
  final String evento;
  final DateTime? inicioEvento;
  final String casa;
  final String musico;
  final DateTime? desde;

  /// CASA e/ou MUSICO.
  final List<String> faltaAssinar;

  String get quemFalta {
    if (travado) return 'Falha ao gerar o PDF';
    final nomes = faltaAssinar.map((p) => p == 'CASA' ? 'Casa' : 'Músico').toList();
    return nomes.isEmpty ? '—' : nomes.join(' e ');
  }

  factory ContratoComProblema.fromJson(Map<String, dynamic> json) => ContratoComProblema(
        numero: _texto(json['numero']),
        travado: json['tipo'] == 'TRAVADO',
        situacao: _texto(json['situacao']),
        evento: _texto(json['evento']),
        inicioEvento: _data(json['inicioEvento']),
        casa: _texto(json['casa']),
        musico: _texto(json['musico']),
        desde: _data(json['desde']),
        faltaAssinar: json['faltaAssinar'] is List
            ? (json['faltaAssinar'] as List).whereType<String>().toList()
            : const [],
      );
}

// ---------------------------------------------------------------------------------------------------- aba 2

class Marketplace {
  const Marketplace({
    required this.geradoEm,
    required this.periodo,
    required this.taxaPreenchimento,
    required this.tempoAteFecharHoras,
    required this.propostasPorEvento,
    required this.eventosSemProposta,
    required this.aceitePropostas,
    required this.aceiteConvites,
    required this.canceladosAntesDoMusico,
    required this.canceladosDepoisDeConfirmado,
    required this.eventosComMusicoProprio,
    required this.funil,
    required this.porEstilo,
  });

  final DateTime? geradoEm;
  final int periodo;
  final Indicador taxaPreenchimento;
  final Indicador tempoAteFecharHoras;
  final Indicador propostasPorEvento;
  final Indicador eventosSemProposta;
  final Indicador aceitePropostas;
  final Indicador aceiteConvites;
  final Indicador canceladosAntesDoMusico;
  final Indicador canceladosDepoisDeConfirmado;
  final Indicador eventosComMusicoProprio;
  final Funil funil;
  final List<EstiloNoMarketplace> porEstilo;

  bool get vazio => funil.criados == 0 && taxaPreenchimento.valor == null && porEstilo.isEmpty;

  factory Marketplace.fromJson(Map<String, dynamic> json) {
    final c = _mapa(json['cartoes']);
    return Marketplace(
      geradoEm: _data(json['geradoEm']),
      periodo: _inteiro(json['periodo']),
      taxaPreenchimento: Indicador.fromJson(c['taxaPreenchimento']),
      tempoAteFecharHoras: Indicador.fromJson(c['tempoAteFecharHoras']),
      propostasPorEvento: Indicador.fromJson(c['propostasPorEvento']),
      eventosSemProposta: Indicador.fromJson(c['eventosSemProposta']),
      aceitePropostas: Indicador.fromJson(c['aceitePropostas']),
      aceiteConvites: Indicador.fromJson(c['aceiteConvites']),
      canceladosAntesDoMusico: Indicador.fromJson(c['canceladosAntesDoMusico']),
      canceladosDepoisDeConfirmado: Indicador.fromJson(c['canceladosDepoisDeConfirmado']),
      eventosComMusicoProprio: Indicador.fromJson(c['eventosComMusicoProprio']),
      funil: Funil.fromJson(_mapa(json['funil'])),
      porEstilo: _lista(json['porEstilo']).map(EstiloNoMarketplace.fromJson).toList(),
    );
  }
}

class Funil {
  const Funil({this.criados = 0, this.comProposta = 0, this.confirmados = 0, this.realizados = 0});

  final int criados;
  final int comProposta;
  final int confirmados;
  final int realizados;

  factory Funil.fromJson(Map<String, dynamic> json) => Funil(
        criados: _inteiro(json['criados']),
        comProposta: _inteiro(json['comProposta']),
        confirmados: _inteiro(json['confirmados']),
        realizados: _inteiro(json['realizados']),
      );
}

class EstiloNoMarketplace {
  const EstiloNoMarketplace({
    required this.estilo,
    required this.eventos,
    required this.preenchidos,
    this.taxaPreenchimento,
    this.cacheMinimoMediana,
    this.cacheMaximoMediana,
    this.cachePagoMediana,
  });

  final String estilo;
  final int eventos;
  final int preenchidos;
  final double? taxaPreenchimento;
  final double? cacheMinimoMediana;
  final double? cacheMaximoMediana;
  final double? cachePagoMediana;

  factory EstiloNoMarketplace.fromJson(Map<String, dynamic> json) => EstiloNoMarketplace(
        estilo: _texto(json['estilo']),
        eventos: _inteiro(json['eventos']),
        preenchidos: _inteiro(json['preenchidos']),
        taxaPreenchimento: _decimal(json['taxaPreenchimento']),
        cacheMinimoMediana: _decimal(json['cacheMinimoMediana']),
        cacheMaximoMediana: _decimal(json['cacheMaximoMediana']),
        cachePagoMediana: _decimal(json['cachePagoMediana']),
      );
}

// ---------------------------------------------------------------------------------------------------- aba 3

enum PerfilDashboard {
  musico('MUSICO', 'Músicos'),
  estabelecimento('ESTABELECIMENTO', 'Casas'),
  curtidor('CURTIDOR', 'Curtidores');

  const PerfilDashboard(this.api, this.rotulo);

  final String api;
  final String rotulo;
}

class Crescimento {
  const Crescimento({
    required this.geradoEm,
    required this.periodo,
    required this.porPerfil,
    required this.semanas,
    required this.cidades,
  });

  final DateTime? geradoEm;
  final int periodo;
  final Map<PerfilDashboard, CrescimentoDoPerfil> porPerfil;
  final List<Semana> semanas;
  final List<Cidade> cidades;

  CrescimentoDoPerfil perfil(PerfilDashboard p) => porPerfil[p] ?? const CrescimentoDoPerfil();

  bool get vazio => porPerfil.values.every((p) => (p.novos.valor ?? 0) == 0);

  factory Crescimento.fromJson(Map<String, dynamic> json) {
    final perfis = _mapa(json['porPerfil']);
    return Crescimento(
      geradoEm: _data(json['geradoEm']),
      periodo: _inteiro(json['periodo']),
      porPerfil: {
        for (final p in PerfilDashboard.values) p: CrescimentoDoPerfil.fromJson(_mapa(perfis[p.api])),
      },
      semanas: _lista(json['semanas']).map(Semana.fromJson).toList(),
      cidades: _lista(json['cidades']).map(Cidade.fromJson).toList(),
    );
  }
}

class CrescimentoDoPerfil {
  const CrescimentoDoPerfil({this.novos = const Indicador(), this.total = 0, this.ativos = 0, this.percentualAtivos});

  final Indicador novos;
  final int total;

  /// Entraram no app nos últimos 30 dias.
  final int ativos;
  final double? percentualAtivos;

  factory CrescimentoDoPerfil.fromJson(Map<String, dynamic> json) => CrescimentoDoPerfil(
        novos: Indicador.fromJson(json['novos']),
        total: _inteiro(json['total']),
        ativos: _inteiro(json['ativos']),
        percentualAtivos: _decimal(json['percentualAtivos']),
      );
}

class Semana {
  const Semana({
    required this.inicio,
    this.musicos = 0,
    this.estabelecimentos = 0,
    this.curtidores = 0,
    this.eventos = 0,
  });

  /// Segunda-feira da semana.
  final DateTime inicio;
  final int musicos;
  final int estabelecimentos;
  final int curtidores;
  final int eventos;

  int de(PerfilDashboard p) => switch (p) {
        PerfilDashboard.musico => musicos,
        PerfilDashboard.estabelecimento => estabelecimentos,
        PerfilDashboard.curtidor => curtidores,
      };

  factory Semana.fromJson(Map<String, dynamic> json) => Semana(
        inicio: _data(json['inicio']) ?? DateTime(2000),
        musicos: _inteiro(json['musicos']),
        estabelecimentos: _inteiro(json['estabelecimentos']),
        curtidores: _inteiro(json['curtidores']),
        eventos: _inteiro(json['eventos']),
      );
}

class Cidade {
  const Cidade({
    required this.cidade,
    this.estado,
    this.musicos = 0,
    this.estabelecimentos = 0,
    this.curtidores = 0,
    this.eventosFuturos = 0,
  });

  final String cidade;
  final String? estado;
  final int musicos;
  final int estabelecimentos;
  final int curtidores;
  final int eventosFuturos;

  String get nome => estado == null ? cidade : '$cidade/$estado';

  factory Cidade.fromJson(Map<String, dynamic> json) => Cidade(
        cidade: _texto(json['cidade']),
        estado: _textoOuNulo(json['estado']),
        musicos: _inteiro(json['musicos']),
        estabelecimentos: _inteiro(json['estabelecimentos']),
        curtidores: _inteiro(json['curtidores']),
        eventosFuturos: _inteiro(json['eventosFuturos']),
      );
}

// ---------------------------------------------------------------------------------------------------- aba 4

class Curtidores {
  const Curtidores({
    required this.geradoEm,
    required this.periodo,
    required this.vou,
    required this.fui,
    required this.conversaoVouFui,
    required this.eventosComPublico,
    required this.curtidoresAtivos,
    required this.curtidoresTotal,
    this.percentualAtivos,
    required this.estilos,
    required this.topCasas,
    required this.topEventos,
  });

  final DateTime? geradoEm;
  final int periodo;
  final Indicador vou;
  final Indicador fui;
  final Indicador conversaoVouFui;
  final Indicador eventosComPublico;
  final int curtidoresAtivos;
  final int curtidoresTotal;
  final double? percentualAtivos;
  final List<EstiloProcurado> estilos;
  final List<CasaComPublico> topCasas;
  final List<EventoComPublico> topEventos;

  bool get vazio => (vou.valor ?? 0) == 0 && estilos.isEmpty && topEventos.isEmpty;

  factory Curtidores.fromJson(Map<String, dynamic> json) {
    final c = _mapa(json['cartoes']);
    return Curtidores(
      geradoEm: _data(json['geradoEm']),
      periodo: _inteiro(json['periodo']),
      vou: Indicador.fromJson(c['vou']),
      fui: Indicador.fromJson(c['fui']),
      conversaoVouFui: Indicador.fromJson(c['conversaoVouFui']),
      eventosComPublico: Indicador.fromJson(c['eventosComPublico']),
      curtidoresAtivos: _inteiro(c['curtidoresAtivos']),
      curtidoresTotal: _inteiro(c['curtidoresTotal']),
      percentualAtivos: _decimal(c['percentualAtivos']),
      estilos: _lista(json['estilos']).map(EstiloProcurado.fromJson).toList(),
      topCasas: _lista(json['topCasas']).map(CasaComPublico.fromJson).toList(),
      topEventos: _lista(json['topEventos']).map(EventoComPublico.fromJson).toList(),
    );
  }
}

class EstiloProcurado {
  const EstiloProcurado({required this.estilo, this.curtidores = 0, this.eventosFuturos = 0, this.destaque = false});

  final String estilo;
  final int curtidores;

  /// Eventos nos próximos 30 dias.
  final int eventosFuturos;

  /// Muita procura e pouca oferta.
  final bool destaque;

  factory EstiloProcurado.fromJson(Map<String, dynamic> json) => EstiloProcurado(
        estilo: _texto(json['estilo']),
        curtidores: _inteiro(json['curtidores']),
        eventosFuturos: _inteiro(json['eventosFuturos']),
        destaque: _logico(json['destaque']),
      );
}

class CasaComPublico {
  const CasaComPublico({required this.casa, this.cidade, this.estado, this.eventos = 0, this.publico = 0});

  final String casa;
  final String? cidade;
  final String? estado;
  final int eventos;
  final int publico;

  factory CasaComPublico.fromJson(Map<String, dynamic> json) => CasaComPublico(
        casa: _texto(json['casa']),
        cidade: _textoOuNulo(json['cidade']),
        estado: _textoOuNulo(json['estado']),
        eventos: _inteiro(json['eventos']),
        publico: _inteiro(json['publico']),
      );
}

class EventoComPublico {
  const EventoComPublico({
    required this.titulo,
    this.inicio,
    required this.casa,
    this.cidade,
    this.estado,
    this.vou = 0,
  });

  final String titulo;
  final DateTime? inicio;
  final String casa;
  final String? cidade;
  final String? estado;
  final int vou;

  factory EventoComPublico.fromJson(Map<String, dynamic> json) => EventoComPublico(
        titulo: _texto(json['titulo']),
        inicio: _data(json['inicio']),
        casa: _texto(json['casa']),
        cidade: _textoOuNulo(json['cidade']),
        estado: _textoOuNulo(json['estado']),
        vou: _inteiro(json['vou']),
      );
}

// ---------------------------------------------------------------------------------------------------- aba 5

enum TipoAvaliacaoDashboard {
  casaAvaliouMusico('CASA_AVALIOU_MUSICO', 'Casa → músico'),
  musicoAvaliouCasa('MUSICO_AVALIOU_CASA', 'Músico → casa'),
  curtidorAvaliouCasa('CURTIDOR_AVALIOU_CASA', 'Curtidor → casa');

  const TipoAvaliacaoDashboard(this.api, this.rotulo);

  final String api;
  final String rotulo;

  static TipoAvaliacaoDashboard? deApi(Object? valor) => values.where((t) => t.api == valor).firstOrNull;
}

class Qualidade {
  const Qualidade({
    required this.geradoEm,
    required this.periodo,
    required this.notas,
    required this.eventosAvaliados,
    required this.contratos,
    required this.conversas,
    required this.distribuicao,
    required this.alertas,
  });

  final DateTime? geradoEm;
  final int periodo;
  final List<NotaPorTipo> notas;
  final EventosAvaliados eventosAvaliados;
  final ContratosAssinados contratos;
  final Conversas conversas;
  final Map<TipoAvaliacaoDashboard, List<int>> distribuicao;
  final List<NotaBaixa> alertas;

  bool get vazio =>
      notas.every((n) => (n.quantidade.valor ?? 0) == 0) &&
      eventosAvaliados.eventos == 0 &&
      contratos.gerados == 0 &&
      (conversas.solicitacoes.valor ?? 0) == 0 &&
      alertas.isEmpty;

  factory Qualidade.fromJson(Map<String, dynamic> json) => Qualidade(
        geradoEm: _data(json['geradoEm']),
        periodo: _inteiro(json['periodo']),
        notas: _lista(json['notas']).map(NotaPorTipo.fromJson).whereType<NotaPorTipo>().toList(),
        eventosAvaliados: EventosAvaliados.fromJson(_mapa(json['eventosAvaliados'])),
        contratos: ContratosAssinados.fromJson(_mapa(json['contratos'])),
        conversas: Conversas.fromJson(_mapa(json['conversas'])),
        distribuicao: {
          for (final d in _lista(json['distribuicao']))
            if (TipoAvaliacaoDashboard.deApi(d['tipo']) != null)
              TipoAvaliacaoDashboard.deApi(d['tipo'])!:
                  d['notas'] is List ? (d['notas'] as List).map(_inteiro).toList() : const <int>[],
        },
        alertas: _lista(json['alertas']).map(NotaBaixa.fromJson).toList(),
      );
}

class NotaPorTipo {
  const NotaPorTipo({required this.tipo, required this.media, required this.quantidade});

  final TipoAvaliacaoDashboard tipo;
  final Indicador media;
  final Indicador quantidade;

  static NotaPorTipo? fromJson(Map<String, dynamic> json) {
    final tipo = TipoAvaliacaoDashboard.deApi(json['tipo']);
    if (tipo == null) return null;
    return NotaPorTipo(
        tipo: tipo, media: Indicador.fromJson(json['media']), quantidade: Indicador.fromJson(json['quantidade']));
  }
}

class EventosAvaliados {
  const EventosAvaliados({this.eventos = 0, this.pelaCasa = const Indicador(), this.peloMusico = const Indicador()});

  final int eventos;
  final Indicador pelaCasa;
  final Indicador peloMusico;

  factory EventosAvaliados.fromJson(Map<String, dynamic> json) => EventosAvaliados(
        eventos: _inteiro(json['eventos']),
        pelaCasa: Indicador.fromJson(json['pelaCasa']),
        peloMusico: Indicador.fromJson(json['peloMusico']),
      );
}

class ContratosAssinados {
  const ContratosAssinados({this.gerados = 0, this.assinados = 0, this.percentualAssinados = const Indicador()});

  final int gerados;
  final int assinados;
  final Indicador percentualAssinados;

  factory ContratosAssinados.fromJson(Map<String, dynamic> json) => ContratosAssinados(
        gerados: _inteiro(json['gerados']),
        assinados: _inteiro(json['assinados']),
        percentualAssinados: Indicador.fromJson(json['percentualAssinados']),
      );
}

class Conversas {
  const Conversas({
    this.solicitacoes = const Indicador(),
    this.percentualAceitas,
    this.percentualRecusadas,
    this.percentualSemResposta,
  });

  final Indicador solicitacoes;
  final double? percentualAceitas;
  final double? percentualRecusadas;

  /// Pendentes há mais de 7 dias.
  final double? percentualSemResposta;

  factory Conversas.fromJson(Map<String, dynamic> json) => Conversas(
        solicitacoes: Indicador.fromJson(json['solicitacoes']),
        percentualAceitas: _decimal(json['percentualAceitas']),
        percentualRecusadas: _decimal(json['percentualRecusadas']),
        percentualSemResposta: _decimal(json['percentualSemResposta']),
      );
}

class NotaBaixa {
  const NotaBaixa({
    required this.nome,
    required this.perfil,
    this.cidade,
    this.estado,
    required this.media,
    required this.quantidade,
    this.ultimoComentario,
  });

  final String nome;

  /// MUSICO ou ESTABELECIMENTO.
  final String perfil;
  final String? cidade;
  final String? estado;
  final double media;
  final int quantidade;
  final String? ultimoComentario;

  String get perfilRotulo => perfil == 'MUSICO' ? 'Músico' : 'Casa';

  factory NotaBaixa.fromJson(Map<String, dynamic> json) => NotaBaixa(
        nome: _texto(json['nome']),
        perfil: _texto(json['perfil']),
        cidade: _textoOuNulo(json['cidade']),
        estado: _textoOuNulo(json['estado']),
        media: _decimal(json['media']) ?? 0,
        quantidade: _inteiro(json['quantidade']),
        ultimoComentario: _textoOuNulo(json['ultimoComentario']),
      );
}
