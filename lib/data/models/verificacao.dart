import 'models.dart';

/// E30 — verificação do estabelecimento vista pela equipe.

enum SituacaoVerificacao {
  rascunho('RASCUNHO', 'Rascunho'),
  emAnalise('EM_ANALISE', 'Em análise'),
  aprovada('APROVADA', 'Aprovada'),
  reprovada('REPROVADA', 'Ajuste pedido'),
  substituida('SUBSTITUIDA', 'Selo perdido');

  const SituacaoVerificacao(this.api, this.rotulo);

  final String api;
  final String rotulo;

  static SituacaoVerificacao deApi(String? valor) =>
      values.where((s) => s.api == valor).firstOrNull ?? SituacaoVerificacao.emAnalise;
}

enum TipoVerificacao {
  documentos('DOCUMENTOS', 'Documentos'),
  semCnpj('SEM_CNPJ', 'Sem CNPJ — contato');

  const TipoVerificacao(this.api, this.rotulo);

  final String api;
  final String rotulo;

  static TipoVerificacao deApi(String? valor) =>
      values.where((t) => t.api == valor).firstOrNull ?? TipoVerificacao.documentos;
}

/// Chips de situação da tela (mesmos valores do `FiltroSituacao` da API).
enum FiltroVerificacao {
  emAnalise('EM_ANALISE', 'Em análise'),
  aprovada('APROVADA', 'Aprovadas'),
  reprovada('REPROVADA', 'Ajuste pedido'),
  substituida('SUBSTITUIDA', 'Selo perdido'),
  todas('TODAS', 'Todas');

  const FiltroVerificacao(this.api, this.rotulo);

  final String api;
  final String rotulo;
}

enum TipoArquivoVerificacao {
  frente('DOCUMENTO_FRENTE', 'Frente do documento'),
  verso('DOCUMENTO_VERSO', 'Verso do documento'),
  selfie('SELFIE_DOCUMENTO', 'Selfie com o documento'),
  comprovante('COMPROVANTE', 'Comprovante');

  const TipoArquivoVerificacao(this.api, this.rotulo);

  final String api;
  final String rotulo;

  static TipoArquivoVerificacao deApi(String? valor) =>
      values.where((t) => t.api == valor).firstOrNull ?? TipoArquivoVerificacao.frente;
}

enum SituacaoArquivo {
  pendente('PENDENTE', 'Novo'),
  aceito('ACEITO', 'Aceito'),
  recusado('RECUSADO', 'Recusado');

  const SituacaoArquivo(this.api, this.rotulo);

  final String api;
  final String rotulo;

  static SituacaoArquivo deApi(String? valor) => values.where((s) => s.api == valor).firstOrNull ?? SituacaoArquivo.pendente;
}

/// Motivos fixos do "Pedir ajuste" (a casa vê o texto completo, que vem do backend).
enum MotivoRecusa {
  ilegivel('ILEGIVEL', 'Ilegível'),
  vencido('VENCIDO', 'Documento vencido'),
  documentoDiferenteNaSelfie('DOCUMENTO_DIFERENTE_NA_SELFIE', 'Documento da selfie é outro'),
  rostoNaoConfere('ROSTO_NAO_CONFERE', 'Rosto não confere'),
  cnpjInativo('CNPJ_INATIVO', 'CNPJ inativo'),
  comprovanteAntigo('COMPROVANTE_ANTIGO', 'Conta com mais de 90 dias'),
  enderecoNaoConfere('ENDERECO_NAO_CONFERE', 'Endereço não confere'),
  nomeNaoConfere('NOME_NAO_CONFERE', 'Não está em nome da casa'),
  suspeitaDeAdulteracao('SUSPEITA_DE_ADULTERACAO', 'Suspeita de edição'),
  outro('OUTRO', 'Outro (explique no comentário)');

  const MotivoRecusa(this.api, this.rotulo);

  final String api;
  final String rotulo;

  static MotivoRecusa? deApi(String? valor) => values.where((m) => m.api == valor).firstOrNull;
}

DateTime? _data(Object? v) => v == null ? null : DateTime.parse(v as String);

/// Prazo de 3 dias úteis: "Atrasada" quando passou e ainda está em análise; "Vence hoje" no último dia.
Prazo prazoDaVerificacao(SituacaoVerificacao situacao, DateTime? prazo, DateTime agora) {
  if (situacao != SituacaoVerificacao.emAnalise || prazo == null) return Prazo.noPrazo;
  if (agora.isAfter(prazo)) return Prazo.atrasada;
  final p = prazo.toLocal();
  final a = agora.toLocal();
  if (p.year == a.year && p.month == a.month && p.day == a.day) return Prazo.venceHoje;
  return Prazo.noPrazo;
}

/// 12.345.678/0001-95 (só dígitos na API).
String formatarCnpj(String? cnpj) {
  if (cnpj == null || cnpj.length != 14) return cnpj ?? '—';
  return '${cnpj.substring(0, 2)}.${cnpj.substring(2, 5)}.${cnpj.substring(5, 8)}/${cnpj.substring(8, 12)}-${cnpj.substring(12)}';
}

class FiltroVerificacoes {
  const FiltroVerificacoes({this.situacao = FiltroVerificacao.emAnalise, this.tipo, this.busca = ''});

  final FiltroVerificacao situacao;
  final TipoVerificacao? tipo;
  final String busca;

  FiltroVerificacoes copyWith({FiltroVerificacao? situacao, TipoVerificacao? tipo, bool limparTipo = false, String? busca}) =>
      FiltroVerificacoes(
        situacao: situacao ?? this.situacao,
        tipo: limparTipo ? null : (tipo ?? this.tipo),
        busca: busca ?? this.busca,
      );
}

class VerificacaoResumo {
  const VerificacaoResumo({
    required this.id,
    required this.tipo,
    required this.situacao,
    required this.casa,
    this.cidade,
    this.estado,
    this.cnpj,
    this.enviadaEm,
    this.prazoAnalise,
    this.analisadaEm,
  });

  final String id;
  final TipoVerificacao tipo;
  final SituacaoVerificacao situacao;
  final String casa;
  final String? cidade;
  final String? estado;
  final String? cnpj;
  final DateTime? enviadaEm;
  final DateTime? prazoAnalise;
  final DateTime? analisadaEm;

  String get cidadeUf => [cidade, estado].whereType<String>().where((t) => t.isNotEmpty).join('/');

  factory VerificacaoResumo.fromJson(Map<String, dynamic> json) => VerificacaoResumo(
        id: json['uuid'] as String,
        tipo: TipoVerificacao.deApi(json['tipo'] as String?),
        situacao: SituacaoVerificacao.deApi(json['situacao'] as String?),
        casa: json['casa'] as String? ?? '—',
        cidade: json['cidade'] as String?,
        estado: json['estado'] as String?,
        cnpj: json['cnpj'] as String?,
        enviadaEm: _data(json['enviadaEm']),
        prazoAnalise: _data(json['prazoAnalise']),
        analisadaEm: _data(json['analisadaEm']),
      );
}

class ArquivoVerificacao {
  const ArquivoVerificacao({
    required this.id,
    required this.tipo,
    this.situacao = SituacaoArquivo.pendente,
    this.contentType = 'image/jpeg',
    this.tamanho = 0,
    this.sha256 = '',
    this.disponivel = true,
    this.motivo,
    this.motivoDescricao,
    this.comentario,
  });

  final String id;
  final TipoArquivoVerificacao tipo;
  final SituacaoArquivo situacao;
  final String contentType;
  final int tamanho;
  final String sha256;

  /// `false` depois do descarte (LGPD): o conteúdo não existe mais.
  final bool disponivel;
  final MotivoRecusa? motivo;
  final String? motivoDescricao;
  final String? comentario;

  bool get ehPdf => contentType == 'application/pdf';

  factory ArquivoVerificacao.fromJson(Map<String, dynamic> json) => ArquivoVerificacao(
        id: json['uuid'] as String,
        tipo: TipoArquivoVerificacao.deApi(json['tipo'] as String?),
        situacao: SituacaoArquivo.deApi(json['situacao'] as String?),
        contentType: json['contentType'] as String? ?? 'image/jpeg',
        tamanho: (json['tamanho'] as num?)?.toInt() ?? 0,
        sha256: json['sha256'] as String? ?? '',
        disponivel: json['disponivel'] as bool? ?? true,
        motivo: MotivoRecusa.deApi(json['motivo'] as String?),
        motivoDescricao: json['motivoDescricao'] as String?,
        comentario: json['comentario'] as String?,
      );
}

/// Dados da casa (atuais) ou do envio (retrato).
class DadosDaCasa {
  const DadosDaCasa({this.cnpj, this.razaoSocial, this.endereco});

  final String? cnpj;
  final String? razaoSocial;
  final String? endereco;

  factory DadosDaCasa.fromJson(Map<String, dynamic>? json) => DadosDaCasa(
        cnpj: json?['cnpj'] as String?,
        razaoSocial: json?['razaoSocial'] as String?,
        endereco: json?['endereco'] as String?,
      );
}

class VerificacaoDetalhe {
  const VerificacaoDetalhe({
    required this.id,
    required this.tipo,
    required this.situacao,
    required this.casaId,
    required this.casa,
    this.cidade,
    this.estado,
    this.bairro,
    this.atuais = const DadosDaCasa(),
    this.enviados = const DadosDaCasa(),
    this.casaVerificada = false,
    this.tipoDocumento,
    this.tipoComprovante,
    this.contatoTelefone,
    this.contatoMensagem,
    this.enviadaEm,
    this.prazoAnalise,
    this.consentimentoEm,
    this.arquivos = const [],
    this.analisadaEm,
    this.analisadaPor,
    this.mensagemParaCasa,
    this.observacaoInterna,
  });

  final String id;
  final TipoVerificacao tipo;
  final SituacaoVerificacao situacao;
  final String casaId;
  final String casa;
  final String? cidade;
  final String? estado;
  final String? bairro;
  final DadosDaCasa atuais;
  final DadosDaCasa enviados;
  final bool casaVerificada;

  /// `RG`, `CIN` ou `CNH`.
  final String? tipoDocumento;

  /// `CONTA_CONSUMO` ou `ALVARA`.
  final String? tipoComprovante;
  final String? contatoTelefone;
  final String? contatoMensagem;
  final DateTime? enviadaEm;
  final DateTime? prazoAnalise;
  final DateTime? consentimentoEm;
  final List<ArquivoVerificacao> arquivos;
  final DateTime? analisadaEm;
  final String? analisadaPor;
  final String? mensagemParaCasa;
  final String? observacaoInterna;

  bool get emAnalise => situacao == SituacaoVerificacao.emAnalise;
  bool get semCnpj => tipo == TipoVerificacao.semCnpj;

  /// Os dados da casa mudaram depois do envio (a equipe analisa o retrato, mas precisa saber).
  bool get dadosMudaram =>
      (enviados.cnpj != null && atuais.cnpj != null && enviados.cnpj != atuais.cnpj) ||
      (enviados.endereco != null && atuais.endereco != null && enviados.endereco!.trim() != atuais.endereco!.trim());

  String get rotuloDocumento => switch (tipoDocumento) {
        'RG' => 'RG',
        'CIN' => 'CIN (nova identidade)',
        'CNH' => 'CNH',
        _ => '—',
      };

  String get rotuloComprovante => switch (tipoComprovante) {
        'CONTA_CONSUMO' => 'Conta de consumo',
        'ALVARA' => 'Alvará de funcionamento',
        _ => '—',
      };

  ArquivoVerificacao? arquivo(TipoArquivoVerificacao tipo) => arquivos.where((a) => a.tipo == tipo).firstOrNull;

  factory VerificacaoDetalhe.fromJson(Map<String, dynamic> json) {
    final casa = json['casa'] as Map<String, dynamic>? ?? const {};
    final contato = json['contato'] as Map<String, dynamic>?;
    final devolutiva = json['devolutiva'] as Map<String, dynamic>?;
    return VerificacaoDetalhe(
      id: json['uuid'] as String,
      tipo: TipoVerificacao.deApi(json['tipo'] as String?),
      situacao: SituacaoVerificacao.deApi(json['situacao'] as String?),
      casaId: casa['uuid'] as String? ?? '',
      casa: casa['nome'] as String? ?? '—',
      cidade: casa['cidade'] as String?,
      estado: casa['estado'] as String?,
      bairro: casa['bairro'] as String?,
      atuais: DadosDaCasa.fromJson(casa),
      casaVerificada: casa['verificada'] as bool? ?? false,
      enviados: DadosDaCasa.fromJson(json['enviados'] as Map<String, dynamic>?),
      tipoDocumento: json['tipoDocumento'] as String?,
      tipoComprovante: json['tipoComprovante'] as String?,
      contatoTelefone: contato?['telefone'] as String?,
      contatoMensagem: contato?['mensagem'] as String?,
      enviadaEm: _data(json['enviadaEm']),
      prazoAnalise: _data(json['prazoAnalise']),
      consentimentoEm: _data(json['consentimentoEm']),
      arquivos: [
        for (final a in (json['documentos'] as List<dynamic>? ?? const []))
          ArquivoVerificacao.fromJson(a as Map<String, dynamic>),
      ],
      analisadaEm: _data(devolutiva?['em']),
      analisadaPor: devolutiva?['por'] as String?,
      mensagemParaCasa: devolutiva?['mensagemParaCasa'] as String?,
      observacaoInterna: json['observacaoInterna'] as String?,
    );
  }
}

class PaginaVerificacoes {
  const PaginaVerificacoes({required this.itens, required this.pagina, required this.total, required this.totalPaginas});

  final List<VerificacaoResumo> itens;
  final int pagina;
  final int total;
  final int totalPaginas;

  static const vazia = PaginaVerificacoes(itens: [], pagina: 0, total: 0, totalPaginas: 0);

  factory PaginaVerificacoes.fromJson(Map<String, dynamic> json) => PaginaVerificacoes(
        itens: [
          for (final i in (json['itens'] as List<dynamic>? ?? const []))
            VerificacaoResumo.fromJson(i as Map<String, dynamic>),
        ],
        pagina: (json['pagina'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        totalPaginas: (json['totalPaginas'] as num?)?.toInt() ?? 0,
      );
}

class ContagemVerificacoes {
  const ContagemVerificacoes({this.emAnalise = 0, this.atrasadas = 0});

  final int emAnalise;
  final int atrasadas;

  factory ContagemVerificacoes.fromJson(Map<String, dynamic> json) => ContagemVerificacoes(
        emAnalise: (json['emAnalise'] as num?)?.toInt() ?? 0,
        atrasadas: (json['atrasadas'] as num?)?.toInt() ?? 0,
      );
}

/// Pedido de ajuste em um arquivo.
class RecusaDeArquivo {
  const RecusaDeArquivo({required this.arquivoId, required this.motivo, this.comentario});

  final String arquivoId;
  final MotivoRecusa motivo;
  final String? comentario;

  Map<String, dynamic> toJson() => {
        'uuid': arquivoId,
        'motivo': motivo.api,
        if (comentario != null && comentario!.trim().isNotEmpty) 'comentario': comentario!.trim(),
      };
}
