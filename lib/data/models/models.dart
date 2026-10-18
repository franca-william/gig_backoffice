/// Modelos do backoffice (E29). JSON puro da API `/api/backoffice/**`.
library;

/// Quem está logado no backoffice.
class Membro {
  const Membro({required this.nome, required this.login});

  final String nome;
  final String login;

  String get primeiroNome {
    final partes = nome.trim().split(RegExp(r'\s+'));
    return partes.isEmpty || partes.first.isEmpty ? nome : partes.first;
  }

  factory Membro.fromJson(Map<String, dynamic> json) =>
      Membro(nome: json['nome'] as String? ?? '', login: json['login'] as String? ?? '');
}

enum PerfilSugestao {
  musico('MUSICO', 'Músico'),
  estabelecimento('ESTABELECIMENTO', 'Casa'),
  curtidor('CURTIDOR', 'Curtidor');

  const PerfilSugestao(this.api, this.rotulo);
  final String api;
  final String rotulo;

  static PerfilSugestao? deApi(String? valor) => values.where((p) => p.api == valor).firstOrNull;
}

enum TipoSugestao {
  ideia('IDEIA', 'Ideia'),
  melhoria('MELHORIA', 'Melhoria'),
  problema('PROBLEMA', 'Problema'),
  outro('OUTRO', 'Outro');

  const TipoSugestao(this.api, this.rotulo);
  final String api;
  final String rotulo;

  static TipoSugestao? deApi(String? valor) => values.where((t) => t.api == valor).firstOrNull;
}

enum SituacaoSugestao {
  recebida('RECEBIDA', 'Recebida'),
  emAnalise('EM_ANALISE', 'Em análise'),
  respondida('RESPONDIDA', 'Respondida');

  const SituacaoSugestao(this.api, this.rotulo);
  final String api;
  final String rotulo;

  static SituacaoSugestao deApi(String? valor) =>
      values.where((s) => s.api == valor).firstOrNull ?? SituacaoSugestao.recebida;
}

/// Chips de situação da tela (o padrão é "Sem resposta" = Recebida + Em análise).
enum FiltroSituacao {
  semResposta('SEM_RESPOSTA', 'Sem resposta'),
  recebida('RECEBIDA', 'Recebidas'),
  emAnalise('EM_ANALISE', 'Em análise'),
  respondida('RESPONDIDA', 'Respondidas'),
  todas('TODAS', 'Todas');

  const FiltroSituacao(this.api, this.rotulo);
  final String api;
  final String rotulo;

  bool aceita(SituacaoSugestao s) => switch (this) {
        FiltroSituacao.semResposta => s != SituacaoSugestao.respondida,
        FiltroSituacao.recebida => s == SituacaoSugestao.recebida,
        FiltroSituacao.emAnalise => s == SituacaoSugestao.emAnalise,
        FiltroSituacao.respondida => s == SituacaoSugestao.respondida,
        FiltroSituacao.todas => true,
      };
}

class FiltroSugestoes {
  const FiltroSugestoes({this.situacao = FiltroSituacao.semResposta, this.perfil, this.tipo, this.busca = ''});

  final FiltroSituacao situacao;
  final PerfilSugestao? perfil;
  final TipoSugestao? tipo;
  final String busca;

  FiltroSugestoes copyWith({
    FiltroSituacao? situacao,
    PerfilSugestao? perfil,
    bool limparPerfil = false,
    TipoSugestao? tipo,
    bool limparTipo = false,
    String? busca,
  }) =>
      FiltroSugestoes(
        situacao: situacao ?? this.situacao,
        perfil: limparPerfil ? null : (perfil ?? this.perfil),
        tipo: limparTipo ? null : (tipo ?? this.tipo),
        busca: busca ?? this.busca,
      );
}

/// Etiqueta de prazo (2 dias após o envio, E28).
enum Prazo { noPrazo, venceHoje, atrasada }

Prazo prazoDe(SituacaoSugestao situacao, DateTime prazoResposta, DateTime agora) {
  if (situacao == SituacaoSugestao.respondida) return Prazo.noPrazo;
  if (agora.isAfter(prazoResposta)) return Prazo.atrasada;
  final p = prazoResposta.toLocal();
  final a = agora.toLocal();
  if (p.year == a.year && p.month == a.month && p.day == a.day) return Prazo.venceHoje;
  return Prazo.noPrazo;
}

/// Linha da tabela.
class SugestaoResumo {
  const SugestaoResumo({
    required this.id,
    required this.enviadaEm,
    required this.prazoResposta,
    required this.nome,
    required this.perfil,
    required this.tipo,
    required this.inicioDoTexto,
    required this.situacao,
  });

  final String id;
  final DateTime enviadaEm;
  final DateTime prazoResposta;

  /// Nulo = conta excluída ("Usuário excluído").
  final String? nome;
  final PerfilSugestao? perfil;
  final TipoSugestao? tipo;
  final String inicioDoTexto;
  final SituacaoSugestao situacao;

  String get nomeExibido => nome ?? 'Usuário excluído';

  factory SugestaoResumo.fromJson(Map<String, dynamic> json) => SugestaoResumo(
        id: json['uuid'] as String,
        enviadaEm: DateTime.parse(json['enviadaEm'] as String),
        prazoResposta: DateTime.parse(json['prazoResposta'] as String),
        nome: json['nome'] as String?,
        perfil: PerfilSugestao.deApi(json['perfil'] as String?),
        tipo: TipoSugestao.deApi(json['tipo'] as String?),
        inicioDoTexto: json['inicioDoTexto'] as String? ?? '',
        situacao: SituacaoSugestao.deApi(json['situacao'] as String?),
      );
}

class Aparelho {
  const Aparelho({this.versaoApp, this.build, this.sistema, this.versaoSistema, this.modelo, this.idioma});

  final String? versaoApp;
  final String? build;
  final String? sistema;
  final String? versaoSistema;
  final String? modelo;
  final String? idioma;

  bool get vazio => [versaoApp, build, sistema, versaoSistema, modelo, idioma].every((v) => v == null);

  factory Aparelho.fromJson(Map<String, dynamic>? json) => json == null
      ? const Aparelho()
      : Aparelho(
          versaoApp: json['versaoApp'] as String?,
          build: json['build'] as String?,
          sistema: json['sistema'] as String?,
          versaoSistema: json['versaoSistema'] as String?,
          modelo: json['modelo'] as String?,
          idioma: json['idioma'] as String?,
        );
}

class SugestaoDetalhe {
  const SugestaoDetalhe({
    required this.id,
    required this.enviadaEm,
    required this.prazoResposta,
    required this.nome,
    required this.perfil,
    required this.tipo,
    required this.texto,
    required this.situacao,
    this.aparelho = const Aparelho(),
    this.emAnaliseDesde,
    this.emAnalisePor,
    this.resposta,
    this.respondidaEm,
    this.respondidaPor,
    this.implementadaEm,
  });

  final String id;
  final DateTime enviadaEm;
  final DateTime prazoResposta;
  final String? nome;
  final PerfilSugestao? perfil;
  final TipoSugestao? tipo;
  final String texto;
  final SituacaoSugestao situacao;
  final Aparelho aparelho;
  final DateTime? emAnaliseDesde;
  final String? emAnalisePor;
  final String? resposta;
  final DateTime? respondidaEm;
  final String? respondidaPor;

  /// E39 — quando a equipe marcou como implementada (null = ainda não).
  final DateTime? implementadaEm;

  bool get implementada => implementadaEm != null;

  String get nomeExibido => nome ?? 'Usuário excluído';
  bool get respondida => situacao == SituacaoSugestao.respondida;

  /// "Oi, {primeiro nome}! Obrigado pela sugestão. " (editável).
  String get inicioSugerido {
    final primeiro = nome?.trim().split(RegExp(r'\s+')).first ?? '';
    return primeiro.isEmpty ? 'Oi! Obrigado pela sugestão. ' : 'Oi, $primeiro! Obrigado pela sugestão. ';
  }

  static DateTime? _data(Object? v) => v == null ? null : DateTime.parse(v as String);

  factory SugestaoDetalhe.fromJson(Map<String, dynamic> json) => SugestaoDetalhe(
        id: json['uuid'] as String,
        enviadaEm: DateTime.parse(json['enviadaEm'] as String),
        prazoResposta: DateTime.parse(json['prazoResposta'] as String),
        nome: json['nome'] as String?,
        perfil: PerfilSugestao.deApi(json['perfil'] as String?),
        tipo: TipoSugestao.deApi(json['tipo'] as String?),
        texto: json['texto'] as String? ?? '',
        situacao: SituacaoSugestao.deApi(json['situacao'] as String?),
        aparelho: Aparelho.fromJson(json['aparelho'] as Map<String, dynamic>?),
        emAnaliseDesde: _data(json['emAnaliseDesde']),
        emAnalisePor: json['emAnalisePor'] as String?,
        resposta: json['resposta'] as String?,
        respondidaEm: _data(json['respondidaEm']),
        respondidaPor: json['respondidaPor'] as String?,
        implementadaEm: _data(json['implementadaEm']),
      );
}

class PaginaSugestoes {
  const PaginaSugestoes({required this.itens, required this.pagina, required this.total, required this.totalPaginas});

  final List<SugestaoResumo> itens;
  final int pagina;
  final int total;
  final int totalPaginas;

  static const vazia = PaginaSugestoes(itens: [], pagina: 0, total: 0, totalPaginas: 0);

  factory PaginaSugestoes.fromJson(Map<String, dynamic> json) => PaginaSugestoes(
        itens: (json['itens'] as List<dynamic>? ?? [])
            .map((e) => SugestaoResumo.fromJson(e as Map<String, dynamic>))
            .toList(),
        pagina: (json['pagina'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        totalPaginas: (json['totalPaginas'] as num?)?.toInt() ?? 0,
      );
}

class ContagemSugestoes {
  const ContagemSugestoes({this.semResposta = 0, this.atrasadas = 0});

  final int semResposta;
  final int atrasadas;

  factory ContagemSugestoes.fromJson(Map<String, dynamic> json) => ContagemSugestoes(
        semResposta: (json['semResposta'] as num?)?.toInt() ?? 0,
        atrasadas: (json['atrasadas'] as num?)?.toInt() ?? 0,
      );
}
