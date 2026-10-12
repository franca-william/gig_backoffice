import 'dart:convert';
import 'dart:typed_data';

import '../models/verificacao.dart';
import '../repositories/repositories.dart';
import 'mock_repositories.dart';

/// E30 — 5 verificações de exemplo: 2 com documentos em análise (1 atrasada), 1 pedido sem CNPJ, 1 aprovada e 1 com
/// ajuste pedido. Os arquivos são uma imagem de 1 pixel e um PDF falso.
class MockVerificacaoRepository implements VerificacaoRepository {
  MockVerificacaoRepository({Relogio? relogio}) : _agora = relogio ?? DateTime.now {
    _semear();
  }

  final Relogio _agora;
  final Map<String, VerificacaoDetalhe> _dados = {};

  /// Arquivos abertos (como a auditoria do backend).
  final List<String> arquivosAbertos = [];

  /// Simula outra pessoa da equipe decidindo antes (409).
  final Set<String> analisadasPorOutraPessoa = {};

  static const tamanhoDaPagina = 20;
  static final imagem = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');
  static final pdf = Uint8List.fromList(utf8.encode('%PDF-1.4 exemplo'));

  void _semear() {
    final agora = _agora();
    List<ArquivoVerificacao> arquivos(String id, {bool cnhPdf = false, SituacaoArquivo situacao = SituacaoArquivo.pendente}) => [
          ArquivoVerificacao(
            id: '$id-frente',
            tipo: TipoArquivoVerificacao.frente,
            contentType: cnhPdf ? 'application/pdf' : 'image/jpeg',
            situacao: situacao,
            tamanho: 812345,
            sha256: 'a1b2c3',
          ),
          if (!cnhPdf)
            ArquivoVerificacao(id: '$id-verso', tipo: TipoArquivoVerificacao.verso, situacao: situacao, tamanho: 790112, sha256: 'd4e5f6'),
          ArquivoVerificacao(id: '$id-selfie', tipo: TipoArquivoVerificacao.selfie, situacao: situacao, tamanho: 1203344, sha256: '0718aa'),
          ArquivoVerificacao(
            id: '$id-comprovante',
            tipo: TipoArquivoVerificacao.comprovante,
            contentType: 'application/pdf',
            situacao: situacao,
            tamanho: 233001,
            sha256: 'bb9900',
          ),
        ];

    VerificacaoDetalhe v(String id, String casa, SituacaoVerificacao situacao, Duration atras,
        {TipoVerificacao tipo = TipoVerificacao.documentos, bool cnhPdf = false, String? cnpj = '11222333000181'}) {
      final enviada = agora.subtract(atras);
      return VerificacaoDetalhe(
        id: id,
        tipo: tipo,
        situacao: situacao,
        casaId: 'casa-$id',
        casa: casa,
        cidade: 'Fortaleza',
        estado: 'CE',
        bairro: 'Meireles',
        atuais: DadosDaCasa(cnpj: tipo == TipoVerificacao.semCnpj ? null : cnpj, endereco: 'Rua das Flores, 123'),
        enviados: DadosDaCasa(cnpj: tipo == TipoVerificacao.semCnpj ? null : cnpj, endereco: 'Rua das Flores, 123'),
        casaVerificada: situacao == SituacaoVerificacao.aprovada,
        tipoDocumento: tipo == TipoVerificacao.semCnpj ? null : (cnhPdf ? 'CNH' : 'RG'),
        tipoComprovante: tipo == TipoVerificacao.semCnpj ? null : 'CONTA_CONSUMO',
        contatoTelefone: tipo == TipoVerificacao.semCnpj ? '85999991234' : null,
        contatoMensagem: tipo == TipoVerificacao.semCnpj ? 'Bar de forró na Praia de Iracema há 5 anos.' : null,
        enviadaEm: enviada,
        prazoAnalise: enviada.add(const Duration(days: 3)),
        consentimentoEm: tipo == TipoVerificacao.semCnpj ? null : enviada,
        arquivos: tipo == TipoVerificacao.semCnpj
            ? const []
            : arquivos(id,
                cnhPdf: cnhPdf,
                situacao: situacao == SituacaoVerificacao.emAnalise ? SituacaoArquivo.pendente : SituacaoArquivo.aceito),
        analisadaEm: situacao == SituacaoVerificacao.emAnalise ? null : enviada.add(const Duration(days: 1)),
        analisadaPor: situacao == SituacaoVerificacao.emAnalise ? null : 'Bruno Equipe',
      );
    }

    for (final d in [
      v('v1', 'Bar do Zé', SituacaoVerificacao.emAnalise, const Duration(days: 4)), // atrasada
      v('v2', 'Blue Note Bar', SituacaoVerificacao.emAnalise, const Duration(hours: 5), cnhPdf: true),
      v('v3', 'Forró da Praia', SituacaoVerificacao.emAnalise, const Duration(days: 1), tipo: TipoVerificacao.semCnpj),
      v('v4', 'Casa Lua Nova', SituacaoVerificacao.aprovada, const Duration(days: 10)),
      v('v5', 'Pub do Centro', SituacaoVerificacao.reprovada, const Duration(days: 6)),
    ]) {
      _dados[d.id] = d;
    }
  }

  @override
  Future<PaginaVerificacoes> listar(FiltroVerificacoes filtro, {int pagina = 0}) async {
    final situacoes = switch (filtro.situacao) {
      FiltroVerificacao.emAnalise => {SituacaoVerificacao.emAnalise},
      FiltroVerificacao.aprovada => {SituacaoVerificacao.aprovada},
      FiltroVerificacao.reprovada => {SituacaoVerificacao.reprovada},
      FiltroVerificacao.substituida => {SituacaoVerificacao.substituida},
      FiltroVerificacao.todas => SituacaoVerificacao.values.where((s) => s != SituacaoVerificacao.rascunho).toSet(),
    };
    final busca = filtro.busca.trim().toLowerCase();
    final itens = _dados.values
        .where((d) => situacoes.contains(d.situacao))
        .where((d) => filtro.tipo == null || d.tipo == filtro.tipo)
        .where((d) => busca.isEmpty || d.casa.toLowerCase().contains(busca) || (d.enviados.cnpj ?? '').contains(busca))
        .toList()
      ..sort((a, b) {
        final ea = a.emAnalise ? 0 : 1;
        final eb = b.emAnalise ? 0 : 1;
        if (ea != eb) return ea - eb;
        if (a.emAnalise) return a.prazoAnalise!.compareTo(b.prazoAnalise!);
        return (b.analisadaEm ?? DateTime(0)).compareTo(a.analisadaEm ?? DateTime(0));
      });
    final inicio = pagina * tamanhoDaPagina;
    final fatia = itens.skip(inicio).take(tamanhoDaPagina).map(_resumo).toList();
    return PaginaVerificacoes(
      itens: fatia,
      pagina: pagina,
      total: itens.length,
      totalPaginas: (itens.length / tamanhoDaPagina).ceil(),
    );
  }

  @override
  Future<ContagemVerificacoes> contagem() async {
    final agora = _agora();
    final emAnalise = _dados.values.where((d) => d.emAnalise).toList();
    return ContagemVerificacoes(
      emAnalise: emAnalise.length,
      atrasadas: emAnalise.where((d) => d.prazoAnalise != null && agora.isAfter(d.prazoAnalise!)).length,
    );
  }

  @override
  Future<VerificacaoDetalhe> detalhe(String id) async {
    final d = _dados[id];
    if (d == null) throw const BackofficeException('Verificação não encontrada.');
    return d;
  }

  @override
  Future<({Uint8List bytes, String contentType})> arquivo(String id, String arquivoId) async {
    final a = (await detalhe(id)).arquivos.firstWhere((a) => a.id == arquivoId,
        orElse: () => throw const BackofficeException('Arquivo não encontrado.'));
    if (!a.disponivel) throw const BackofficeException('Arquivo já descartado.');
    arquivosAbertos.add(arquivoId);
    return (bytes: a.ehPdf ? pdf : imagem, contentType: a.contentType);
  }

  @override
  Future<VerificacaoDetalhe> aprovar(String id, {String? observacaoInterna}) async {
    final d = await _exigirEmAnalise(id);
    if (d.semCnpj && (observacaoInterna == null || observacaoInterna.trim().isEmpty)) {
      throw const BackofficeException('Registre na observação interna o que a equipe apurou sobre a casa.');
    }
    return _dados[id] = _copiar(
      d,
      situacao: SituacaoVerificacao.aprovada,
      casaVerificada: true,
      observacaoInterna: observacaoInterna,
      arquivos: [for (final a in d.arquivos) _arquivo(a, SituacaoArquivo.aceito)],
    );
  }

  @override
  Future<VerificacaoDetalhe> reprovar(String id,
      {List<RecusaDeArquivo> recusas = const [], String? mensagem, String? observacaoInterna}) async {
    final d = await _exigirEmAnalise(id);
    if (d.semCnpj && (mensagem == null || mensagem.trim().isEmpty)) {
      throw const BackofficeException('Escreva uma mensagem para a casa explicando a decisão.');
    }
    if (!d.semCnpj && recusas.isEmpty) {
      throw const BackofficeException('Escolha pelo menos um documento que precisa ser reenviado.');
    }
    final porArquivo = {for (final r in recusas) r.arquivoId: r};
    return _dados[id] = _copiar(
      d,
      situacao: SituacaoVerificacao.reprovada,
      mensagem: mensagem,
      observacaoInterna: observacaoInterna,
      arquivos: [
        for (final a in d.arquivos)
          porArquivo.containsKey(a.id)
              ? _arquivo(a, SituacaoArquivo.recusado, motivo: porArquivo[a.id]!.motivo, comentario: porArquivo[a.id]!.comentario)
              : _arquivo(a, SituacaoArquivo.aceito),
      ],
    );
  }

  Future<VerificacaoDetalhe> _exigirEmAnalise(String id) async {
    final d = await detalhe(id);
    if (!d.emAnalise || analisadasPorOutraPessoa.contains(id)) throw const VerificacaoJaAnalisadaException();
    return d;
  }

  VerificacaoDetalhe _copiar(VerificacaoDetalhe d,
          {required SituacaoVerificacao situacao,
          bool? casaVerificada,
          String? mensagem,
          String? observacaoInterna,
          required List<ArquivoVerificacao> arquivos}) =>
      VerificacaoDetalhe(
        id: d.id,
        tipo: d.tipo,
        situacao: situacao,
        casaId: d.casaId,
        casa: d.casa,
        cidade: d.cidade,
        estado: d.estado,
        bairro: d.bairro,
        atuais: d.atuais,
        enviados: d.enviados,
        casaVerificada: casaVerificada ?? d.casaVerificada,
        tipoDocumento: d.tipoDocumento,
        tipoComprovante: d.tipoComprovante,
        contatoTelefone: d.contatoTelefone,
        contatoMensagem: d.contatoMensagem,
        enviadaEm: d.enviadaEm,
        prazoAnalise: d.prazoAnalise,
        consentimentoEm: d.consentimentoEm,
        arquivos: arquivos,
        analisadaEm: _agora(),
        analisadaPor: MockSessaoRepository.membro.nome,
        mensagemParaCasa: mensagem,
        observacaoInterna: observacaoInterna ?? d.observacaoInterna,
      );

  static ArquivoVerificacao _arquivo(ArquivoVerificacao a, SituacaoArquivo situacao,
          {MotivoRecusa? motivo, String? comentario}) =>
      ArquivoVerificacao(
        id: a.id,
        tipo: a.tipo,
        situacao: situacao,
        contentType: a.contentType,
        tamanho: a.tamanho,
        sha256: a.sha256,
        disponivel: a.disponivel,
        motivo: motivo,
        motivoDescricao: motivo?.rotulo,
        comentario: comentario,
      );

  static VerificacaoResumo _resumo(VerificacaoDetalhe d) => VerificacaoResumo(
        id: d.id,
        tipo: d.tipo,
        situacao: d.situacao,
        casa: d.casa,
        cidade: d.cidade,
        estado: d.estado,
        cnpj: d.enviados.cnpj,
        enviadaEm: d.enviadaEm,
        prazoAnalise: d.prazoAnalise,
        analisadaEm: d.analisadaEm,
      );
}
