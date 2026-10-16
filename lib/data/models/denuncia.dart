import 'models.dart';

/// E31 (E3 do backoffice) — denúncias de perfis vistas pela equipe.

enum GravidadeDenuncia {
  alta('ALTA', 'Alta'),
  media('MEDIA', 'Média'),
  baixa('BAIXA', 'Baixa');

  const GravidadeDenuncia(this.api, this.rotulo);

  final String api;
  final String rotulo;

  static GravidadeDenuncia deApi(String? valor) =>
      values.where((g) => g.api == valor).firstOrNull ?? GravidadeDenuncia.baixa;
}

enum SituacaoDenuncia {
  aberta('ABERTA', 'Aberta'),
  emAnalise('EM_ANALISE', 'Em análise'),
  procedente('PROCEDENTE', 'Procedente'),
  improcedente('IMPROCEDENTE', 'Improcedente');

  const SituacaoDenuncia(this.api, this.rotulo);

  final String api;
  final String rotulo;

  bool get aberta => this == SituacaoDenuncia.aberta || this == SituacaoDenuncia.emAnalise;

  static SituacaoDenuncia deApi(String? valor) =>
      values.where((s) => s.api == valor).firstOrNull ?? SituacaoDenuncia.aberta;
}

/// O que a equipe faz com o perfil.
enum AcaoDenuncia {
  nenhuma('NENHUMA', 'Sem ação'),
  conteudoRemovido('CONTEUDO_REMOVIDO', 'Conteúdo removido'),
  advertencia('ADVERTENCIA', 'Advertência'),
  suspensao('SUSPENSAO', 'Suspensão'),
  banimento('BANIMENTO', 'Banimento');

  const AcaoDenuncia(this.api, this.rotulo);

  final String api;
  final String rotulo;

  static AcaoDenuncia? deApi(String? valor) => values.where((a) => a.api == valor).firstOrNull;
}

/// Chips de situação da fila (mesmos valores do `FiltroSituacao` da API).
enum FiltroDenuncia {
  abertas('ABERTAS', 'Abertas'),
  procedente('PROCEDENTE', 'Procedentes'),
  improcedente('IMPROCEDENTE', 'Improcedentes'),
  todas('TODAS', 'Todas');

  const FiltroDenuncia(this.api, this.rotulo);

  final String api;
  final String rotulo;
}

/// Perfil denunciado, como aparece na tela.
String rotuloDoPerfil(String? perfil) => switch (perfil) {
      'MUSICO' => 'Músico',
      'ESTABELECIMENTO' => 'Casa',
      'CURTIDOR' => 'Curtidor',
      _ => '—',
    };

/// Origem da denúncia, como aparece na tela.
String rotuloDaOrigem(String? origem) => switch (origem) {
      'PERFIL' => 'Perfil',
      'CONVERSA' => 'Conversa',
      'QUEM_VAI' => 'Quem vai',
      'EVENTO' => 'Evento',
      'CANDIDATURA' => 'Candidatura',
      _ => '—',
    };

DateTime? _data(Object? v) => v == null ? null : DateTime.parse(v as String);

/// Prazo de análise (24 h alta / 3 dias úteis demais): "Atrasada" quando passou e ainda está aberta; "Vence hoje" no
/// último dia.
Prazo prazoDaDenuncia(SituacaoDenuncia situacao, DateTime? prazo, DateTime agora) {
  if (!situacao.aberta || prazo == null) return Prazo.noPrazo;
  if (agora.isAfter(prazo)) return Prazo.atrasada;
  final p = prazo.toLocal();
  final a = agora.toLocal();
  if (p.year == a.year && p.month == a.month && p.day == a.day) return Prazo.venceHoje;
  return Prazo.noPrazo;
}

class FiltroDenuncias {
  const FiltroDenuncias({this.situacao = FiltroDenuncia.abertas, this.gravidade, this.busca = ''});

  final FiltroDenuncia situacao;
  final GravidadeDenuncia? gravidade;
  final String busca;

  FiltroDenuncias copyWith(
          {FiltroDenuncia? situacao, GravidadeDenuncia? gravidade, bool limparGravidade = false, String? busca}) =>
      FiltroDenuncias(
        situacao: situacao ?? this.situacao,
        gravidade: limparGravidade ? null : (gravidade ?? this.gravidade),
        busca: busca ?? this.busca,
      );
}

class DenunciaResumo {
  const DenunciaResumo({
    required this.id,
    required this.tipo,
    required this.tipoDescricao,
    required this.gravidade,
    required this.situacao,
    required this.perfil,
    required this.denunciado,
    required this.criadaEm,
    required this.prazoAnalise,
    this.acao,
    this.origem,
    this.cidade,
    this.estado,
    this.analisadaEm,
  });

  final String id;
  final String tipo;
  final String tipoDescricao;
  final GravidadeDenuncia gravidade;
  final SituacaoDenuncia situacao;
  final AcaoDenuncia? acao;
  final String? origem;

  /// MUSICO, ESTABELECIMENTO ou CURTIDOR.
  final String perfil;
  final String denunciado;
  final String? cidade;
  final String? estado;
  final DateTime criadaEm;
  final DateTime prazoAnalise;
  final DateTime? analisadaEm;

  String get cidadeUf => [cidade, estado].whereType<String>().where((t) => t.isNotEmpty).join('/');

  factory DenunciaResumo.fromJson(Map<String, dynamic> json) => DenunciaResumo(
        id: json['uuid'] as String,
        tipo: json['tipo'] as String? ?? '',
        tipoDescricao: json['tipoDescricao'] as String? ?? '',
        gravidade: GravidadeDenuncia.deApi(json['gravidade'] as String?),
        situacao: SituacaoDenuncia.deApi(json['situacao'] as String?),
        acao: AcaoDenuncia.deApi(json['acao'] as String?),
        origem: json['origem'] as String?,
        perfil: json['perfilDenunciado'] as String? ?? '',
        denunciado: json['denunciado'] as String? ?? '—',
        cidade: json['cidade'] as String?,
        estado: json['estado'] as String?,
        criadaEm: _data(json['criadaEm']) ?? DateTime.now(),
        prazoAnalise: _data(json['prazoAnalise']) ?? DateTime.now(),
        analisadaEm: _data(json['analisadaEm']),
      );
}

class PaginaDenuncias {
  const PaginaDenuncias({required this.itens, required this.pagina, required this.total, required this.totalPaginas});

  final List<DenunciaResumo> itens;
  final int pagina;
  final int total;
  final int totalPaginas;

  static const vazia = PaginaDenuncias(itens: [], pagina: 0, total: 0, totalPaginas: 0);

  factory PaginaDenuncias.fromJson(Map<String, dynamic> json) => PaginaDenuncias(
        itens: [
          for (final i in (json['itens'] as List<dynamic>? ?? const []))
            DenunciaResumo.fromJson(i as Map<String, dynamic>),
        ],
        pagina: (json['pagina'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        totalPaginas: (json['totalPaginas'] as num?)?.toInt() ?? 0,
      );
}

class ContagemDenuncias {
  const ContagemDenuncias({this.abertas = 0, this.altas = 0, this.atrasadas = 0});

  final int abertas;
  final int altas;
  final int atrasadas;

  factory ContagemDenuncias.fromJson(Map<String, dynamic> json) => ContagemDenuncias(
        abertas: (json['abertas'] as num?)?.toInt() ?? 0,
        altas: (json['altas'] as num?)?.toInt() ?? 0,
        atrasadas: (json['atrasadas'] as num?)?.toInt() ?? 0,
      );
}

/// O que estava no perfil na hora da denúncia (a foto vem pela rota da foto, com o token).
class RetratoDenunciado {
  const RetratoDenunciado({required this.nome, this.sobre, this.cidade, this.estado, this.temFoto = false});

  final String nome;
  final String? sobre;
  final String? cidade;
  final String? estado;
  final bool temFoto;

  factory RetratoDenunciado.fromJson(Map<String, dynamic>? json) => RetratoDenunciado(
        nome: json?['nome'] as String? ?? '—',
        sobre: json?['sobre'] as String?,
        cidade: json?['cidade'] as String?,
        estado: json?['estado'] as String?,
        temFoto: json?['temFoto'] as bool? ?? false,
      );
}

/// O perfil como está agora.
class PerfilAtual {
  const PerfilAtual({
    required this.perfil,
    required this.nome,
    this.perfilId,
    this.sobre,
    this.cidade,
    this.estado,
    this.fotoUrl,
    this.fotoOculta = false,
    this.suspensoAte,
    this.banidoEm,
  });

  final String perfil;
  final String? perfilId;
  final String nome;
  final String? sobre;
  final String? cidade;
  final String? estado;
  final String? fotoUrl;
  final bool fotoOculta;
  final DateTime? suspensoAte;
  final DateTime? banidoEm;

  factory PerfilAtual.fromJson(Map<String, dynamic>? json) => PerfilAtual(
        perfil: json?['perfil'] as String? ?? '',
        perfilId: json?['perfilUuid'] as String?,
        nome: json?['nome'] as String? ?? '—',
        sobre: json?['sobre'] as String?,
        cidade: json?['cidade'] as String?,
        estado: json?['estado'] as String?,
        fotoUrl: json?['fotoUrl'] as String?,
        fotoOculta: json?['fotoOculta'] as bool? ?? false,
        suspensoAte: _data(json?['suspensoAte']),
        banidoEm: _data(json?['banidoEm']),
      );
}

class HistoricoDenuncia {
  const HistoricoDenuncia({
    required this.id,
    required this.tipoDescricao,
    required this.gravidade,
    required this.situacao,
    required this.criadaEm,
    this.acao,
  });

  final String id;
  final String tipoDescricao;
  final GravidadeDenuncia gravidade;
  final SituacaoDenuncia situacao;
  final AcaoDenuncia? acao;
  final DateTime criadaEm;

  factory HistoricoDenuncia.fromJson(Map<String, dynamic> json) => HistoricoDenuncia(
        id: json['uuid'] as String,
        tipoDescricao: json['tipoDescricao'] as String? ?? '',
        gravidade: GravidadeDenuncia.deApi(json['gravidade'] as String?),
        situacao: SituacaoDenuncia.deApi(json['situacao'] as String?),
        acao: AcaoDenuncia.deApi(json['acao'] as String?),
        criadaEm: _data(json['criadaEm']) ?? DateTime.now(),
      );
}

class DecisaoTomada {
  const DecisaoTomada({
    required this.procedente,
    required this.acao,
    required this.analisadaEm,
    this.diasSuspensao,
    this.fotoRemovida = false,
    this.sobreRemovido = false,
    this.observacaoInterna,
    this.mensagemParaDenunciado,
    this.analisadaPor,
  });

  final bool procedente;
  final AcaoDenuncia acao;
  final int? diasSuspensao;
  final bool fotoRemovida;
  final bool sobreRemovido;
  final String? observacaoInterna;
  final String? mensagemParaDenunciado;
  final DateTime analisadaEm;
  final String? analisadaPor;

  factory DecisaoTomada.fromJson(Map<String, dynamic> json) => DecisaoTomada(
        procedente: json['procedente'] as bool? ?? false,
        acao: AcaoDenuncia.deApi(json['acao'] as String?) ?? AcaoDenuncia.nenhuma,
        diasSuspensao: (json['diasSuspensao'] as num?)?.toInt(),
        fotoRemovida: json['fotoRemovida'] as bool? ?? false,
        sobreRemovido: json['sobreRemovido'] as bool? ?? false,
        observacaoInterna: json['observacaoInterna'] as String?,
        mensagemParaDenunciado: json['mensagemParaDenunciado'] as String?,
        analisadaEm: _data(json['analisadaEm']) ?? DateTime.now(),
        analisadaPor: json['analisadaPor'] as String?,
      );
}

class DenunciaDetalhe {
  const DenunciaDetalhe({
    required this.id,
    required this.tipo,
    required this.tipoDescricao,
    required this.gravidade,
    required this.situacao,
    required this.criadaEm,
    required this.prazoAnalise,
    required this.retrato,
    required this.atual,
    this.origem,
    this.comentario,
    this.denunciante,
    this.perfilDenunciante,
    this.totalDoPerfil = 1,
    this.pessoasDistintas = 1,
    this.historico = const [],
    this.decisao,
  });

  final String id;
  final String tipo;
  final String tipoDescricao;
  final GravidadeDenuncia gravidade;
  final SituacaoDenuncia situacao;
  final String? origem;
  final String? comentario;
  final DateTime criadaEm;
  final DateTime prazoAnalise;

  /// Nome de quem denunciou — só a equipe vê (nulo se a conta foi excluída).
  final String? denunciante;
  final String? perfilDenunciante;
  final RetratoDenunciado retrato;
  final PerfilAtual atual;
  final int totalDoPerfil;
  final int pessoasDistintas;
  final List<HistoricoDenuncia> historico;
  final DecisaoTomada? decisao;

  bool get aberta => situacao.aberta;

  factory DenunciaDetalhe.fromJson(Map<String, dynamic> json) {
    final denunciante = json['denunciante'] as Map<String, dynamic>?;
    final decisao = json['decisao'] as Map<String, dynamic>?;
    return DenunciaDetalhe(
      id: json['uuid'] as String,
      tipo: json['tipo'] as String? ?? '',
      tipoDescricao: json['tipoDescricao'] as String? ?? '',
      gravidade: GravidadeDenuncia.deApi(json['gravidade'] as String?),
      situacao: SituacaoDenuncia.deApi(json['situacao'] as String?),
      origem: json['origem'] as String?,
      comentario: json['comentario'] as String?,
      criadaEm: _data(json['criadaEm']) ?? DateTime.now(),
      prazoAnalise: _data(json['prazoAnalise']) ?? DateTime.now(),
      denunciante: denunciante?['nome'] as String?,
      perfilDenunciante: denunciante?['perfil'] as String?,
      retrato: RetratoDenunciado.fromJson(json['retrato'] as Map<String, dynamic>?),
      atual: PerfilAtual.fromJson(json['atual'] as Map<String, dynamic>?),
      totalDoPerfil: (json['totalDoPerfil'] as num?)?.toInt() ?? 1,
      pessoasDistintas: (json['pessoasDistintas'] as num?)?.toInt() ?? 1,
      historico: [
        for (final h in (json['historico'] as List<dynamic>? ?? const []))
          HistoricoDenuncia.fromJson(h as Map<String, dynamic>),
      ],
      decisao: decisao == null ? null : DecisaoTomada.fromJson(decisao),
    );
  }
}

/// Decisão da equipe (corpo do POST .../decisao).
class DecisaoDenuncia {
  const DecisaoDenuncia({
    required this.procedente,
    this.acao,
    this.removerFoto = false,
    this.removerSobre = false,
    this.diasSuspensao,
    this.observacaoInterna,
    this.mensagemParaDenunciado,
  });

  /// Improcedente: sem ação.
  const DecisaoDenuncia.improcedente({this.observacaoInterna})
      : procedente = false,
        acao = null,
        removerFoto = false,
        removerSobre = false,
        diasSuspensao = null,
        mensagemParaDenunciado = null;

  final bool procedente;
  final AcaoDenuncia? acao;
  final bool removerFoto;
  final bool removerSobre;
  final int? diasSuspensao;
  final String? observacaoInterna;
  final String? mensagemParaDenunciado;

  Map<String, dynamic> toJson() => {
        'procedente': procedente,
        if (acao != null) 'acao': acao!.api,
        'removerFoto': removerFoto,
        'removerSobre': removerSobre,
        if (diasSuspensao != null) 'diasSuspensao': diasSuspensao,
        if (observacaoInterna != null && observacaoInterna!.trim().isNotEmpty)
          'observacaoInterna': observacaoInterna!.trim(),
        if (mensagemParaDenunciado != null && mensagemParaDenunciado!.trim().isNotEmpty)
          'mensagemParaDenunciado': mensagemParaDenunciado!.trim(),
      };
}
