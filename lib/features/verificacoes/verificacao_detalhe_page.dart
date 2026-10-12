import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/di.dart';
import '../../app/rotas.dart';
import '../../app/sessao_store.dart';
import '../../core/formatar.dart';
import '../../core/theme/theme.dart';
import '../../core/web/abrir_no_navegador.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/gig_button.dart';
import '../../core/widgets/gig_toast.dart';
import '../../data/mock/mock_repositories.dart';
import '../../data/models/verificacao.dart';
import '../../data/repositories/repositories.dart';
import '../sugestoes/widgets.dart';
import 'verificacoes_page.dart';
import 'verificacoes_store.dart';

/// E30 — detalhe de uma verificação: arquivos à esquerda (documento × selfie lado a lado, depois o comprovante);
/// dados, o que conferir, observação interna e a devolutiva à direita. Toda devolutiva notifica a casa no app.
class VerificacaoDetalhePage extends StatefulWidget {
  const VerificacaoDetalhePage({super.key, required this.id});

  /// Consulta pública do CNPJ na Receita Federal (o CNPJ vai copiado para colar lá).
  static const consultaCnpj = 'https://solucoes.receita.fazenda.gov.br/Servicos/cnpjreva/Cadastro_Solicitacao.asp';

  final String id;

  @override
  State<VerificacaoDetalhePage> createState() => _VerificacaoDetalhePageState();
}

class _VerificacaoDetalhePageState extends State<VerificacaoDetalhePage> {
  final _repo = getIt<VerificacaoRepository>();
  final _observacao = TextEditingController();
  VerificacaoDetalhe? _v;
  String? _erro;
  bool _decidindo = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void didUpdateWidget(covariant VerificacaoDetalhePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _v = null;
      _carregar();
    }
  }

  @override
  void dispose() {
    _observacao.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final v = await _repo.detalhe(widget.id);
      if (!mounted) return;
      setState(() {
        _v = v;
        _erro = null;
        if (_observacao.text.isEmpty) _observacao.text = v.observacaoInterna ?? '';
      });
    } on SessaoExpiradaException {
      // volta para o login
    } catch (e) {
      if (mounted) setState(() => _erro = '$e');
    }
  }

  Future<void> _decidir(Future<VerificacaoDetalhe> Function() acao, String sucesso) async {
    setState(() => _decidindo = true);
    try {
      final v = await acao();
      if (!mounted) return;
      setState(() => _v = v);
      GigToast.show(sucesso, type: GigToastType.success);
      getIt<VerificacoesStore>().atualizarContagem();
    } on VerificacaoJaAnalisadaException catch (e) {
      GigToast.show('$e', type: GigToastType.error);
      await _carregar();
    } catch (e) {
      GigToast.show('$e', type: GigToastType.error);
    } finally {
      if (mounted) setState(() => _decidindo = false);
    }
  }

  Future<void> _aprovar(VerificacaoDetalhe v) async {
    if (v.semCnpj && _observacao.text.trim().isEmpty) {
      GigToast.show('Registre na observação interna o que a equipe apurou sobre a casa.', type: GigToastType.error);
      return;
    }
    final confirmou = await showGigConfirmDialog(
      context,
      title: 'Aprovar verificação',
      message: '${v.casa} ganha o selo Verificado. A casa vai receber uma notificação no app.',
      confirmLabel: 'Aprovar',
    );
    if (!confirmou || !mounted) return;
    await _decidir(() => _repo.aprovar(v.id, observacaoInterna: _observacao.text),
        'Verificação aprovada. A casa foi notificada no app.');
  }

  Future<void> _pedirAjuste(VerificacaoDetalhe v) async {
    final pedido = await showDialog<_Ajuste>(
      context: context,
      barrierColor: GigColors.scrim,
      builder: (_) => _DialogoAjuste(verificacao: v),
    );
    if (pedido == null || !mounted) return;
    await _decidir(
      () => _repo.reprovar(v.id, recusas: pedido.recusas, mensagem: pedido.mensagem, observacaoInterna: _observacao.text),
      v.semCnpj ? 'Pedido recusado. A casa foi notificada no app.' : 'Ajuste pedido. A casa foi notificada no app.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = _v;
    return ListView(
      padding: const EdgeInsets.all(GigSpacing.xxxl),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.go(Rotas.verificacoes),
            icon: const Icon(LucideIcons.arrowLeft, size: 16),
            label: const Text('Voltar para Verificações'),
          ),
        ),
        const SizedBox(height: GigSpacing.md),
        if (_erro != null)
          Text(_erro!, style: GigTypography.body)
        else if (v == null)
          const Center(child: Padding(padding: EdgeInsets.all(GigSpacing.huge), child: CircularProgressIndicator()))
        else ...[
          _cabecalho(v),
          const SizedBox(height: GigSpacing.xl),
          LayoutBuilder(builder: (context, c) {
            final esquerda = v.semCnpj ? _Contato(v: v) : _Arquivos(v: v, repo: _repo);
            final direita = _direita(v);
            if (c.maxWidth < 900) {
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                esquerda,
                const SizedBox(height: GigSpacing.xxl),
                direita,
              ]);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: esquerda),
              const SizedBox(width: GigSpacing.xxl),
              Expanded(flex: 2, child: direita),
            ]);
          }),
        ],
      ],
    );
  }

  Widget _cabecalho(VerificacaoDetalhe v) {
    final prazo = prazoDaVerificacao(v.situacao, v.prazoAnalise, getIt<Relogio>()());
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: GigSpacing.sm, runSpacing: GigSpacing.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
        EtiquetaVerificacao(situacao: v.situacao),
        EtiquetaPrazo(prazo: prazo),
        if (v.semCnpj) const Etiqueta(texto: 'Sem CNPJ — contato', cor: GigColors.info),
        if (v.casaVerificada) const Etiqueta(texto: 'Casa com selo', cor: GigColors.success),
      ]),
      const SizedBox(height: GigSpacing.md),
      Text(v.casa, style: GigTypography.h1),
      Text(
        [
          [v.bairro, v.cidade, v.estado].whereType<String>().where((t) => t.isNotEmpty).join(', '),
          if (v.enviadaEm != null) 'enviada em ${Formatar.dataHora(v.enviadaEm!)}',
          if (v.prazoAnalise != null) 'prazo ${Formatar.dataHora(v.prazoAnalise!)}',
        ].where((t) => t.isNotEmpty).join(' · '),
        style: GigTypography.small,
      ),
    ]);
  }

  Widget _direita(VerificacaoDetalhe v) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (!v.semCnpj) ...[
        _Painel(titulo: 'Dados enviados', child: _Dados(v: v)),
        const SizedBox(height: GigSpacing.lg),
        const _Painel(titulo: 'O que conferir', child: _OQueConferir()),
        const SizedBox(height: GigSpacing.lg),
      ],
      _Painel(
        titulo: 'Observação interna',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
            v.semCnpj
                ? 'Obrigatória para aprovar: registre o que a equipe apurou (ligação, visita, redes...). Só a equipe vê.'
                : 'Só a equipe vê. Vai junto com a devolutiva.',
            style: GigTypography.small,
          ),
          const SizedBox(height: GigSpacing.sm),
          TextField(
            key: const Key('observacao-interna'),
            controller: _observacao,
            enabled: v.emAnalise,
            minLines: 3,
            maxLines: 8,
            maxLength: 2000,
            decoration: const InputDecoration(hintText: 'Ex.: liguei no telefone do Google Maps e confirmei.'),
          ),
        ]),
      ),
      const SizedBox(height: GigSpacing.lg),
      if (v.emAnalise) ...[
        GigButton(
          key: const Key('aprovar-verificacao'),
          label: 'Aprovar',
          icon: LucideIcons.shieldCheck,
          loading: _decidindo,
          onPressed: _decidindo ? null : () => _aprovar(v),
        ),
        const SizedBox(height: GigSpacing.sm),
        GigButton.outline(
          key: const Key('pedir-ajuste'),
          label: v.semCnpj ? 'Recusar' : 'Pedir ajuste',
          icon: v.semCnpj ? LucideIcons.x : LucideIcons.refreshCw,
          onPressed: _decidindo ? null : () => _pedirAjuste(v),
        ),
        const SizedBox(height: GigSpacing.xs),
        Text('A casa recebe uma notificação no app com a devolutiva.', style: GigTypography.caption, textAlign: TextAlign.center),
      ] else
        _Devolutiva(v: v),
    ]);
  }
}

// ---------------------------------------------------------------- arquivos

class _Arquivos extends StatelessWidget {
  const _Arquivos({required this.v, required this.repo});

  final VerificacaoDetalhe v;
  final VerificacaoRepository repo;

  @override
  Widget build(BuildContext context) {
    final frente = v.arquivo(TipoArquivoVerificacao.frente);
    final verso = v.arquivo(TipoArquivoVerificacao.verso);
    final selfie = v.arquivo(TipoArquivoVerificacao.selfie);
    final comprovante = v.arquivo(TipoArquivoVerificacao.comprovante);
    Widget cartao(ArquivoVerificacao? a, String titulo) => a == null
        ? _Painel(titulo: titulo, child: Text('Não enviado.', style: GigTypography.bodyMuted))
        : _CartaoArquivo(verificacaoId: v.id, arquivo: a, repo: repo, titulo: titulo);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Documento: ${v.rotuloDocumento} · Comprovante: ${v.rotuloComprovante}', style: GigTypography.small),
      const SizedBox(height: GigSpacing.md),
      // Documento e selfie lado a lado: é a comparação do rosto.
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: cartao(frente, 'Frente do documento')),
        const SizedBox(width: GigSpacing.lg),
        Expanded(child: cartao(selfie, 'Selfie com o documento')),
      ]),
      const SizedBox(height: GigSpacing.lg),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: verso != null || (frente != null && !frente.ehPdf)
              ? cartao(verso, 'Verso do documento')
              : _Painel(titulo: 'Verso do documento', child: Text('CNH digital em PDF: sem verso.', style: GigTypography.bodyMuted)),
        ),
        const SizedBox(width: GigSpacing.lg),
        Expanded(child: cartao(comprovante, 'Comprovante · ${v.rotuloComprovante}')),
      ]),
    ]);
  }
}

/// Um arquivo: baixa os bytes com o token (nunca há URL), mostra a imagem com marca d'água ou o botão do PDF.
class _CartaoArquivo extends StatefulWidget {
  const _CartaoArquivo({required this.verificacaoId, required this.arquivo, required this.repo, required this.titulo});

  final String verificacaoId;
  final ArquivoVerificacao arquivo;
  final VerificacaoRepository repo;
  final String titulo;

  @override
  State<_CartaoArquivo> createState() => _CartaoArquivoState();
}

class _CartaoArquivoState extends State<_CartaoArquivo> {
  Future<({Uint8List bytes, String contentType})>? _conteudo;
  int _quartos = 0;

  @override
  void initState() {
    super.initState();
    // PDF só baixa quando a pessoa pede (cada abertura fica na auditoria).
    if (widget.arquivo.disponivel && !widget.arquivo.ehPdf) _conteudo = _baixar();
  }

  Future<({Uint8List bytes, String contentType})> _baixar() =>
      widget.repo.arquivo(widget.verificacaoId, widget.arquivo.id);

  Future<void> _abrirPdf() async {
    try {
      final c = await (_conteudo ??= _baixar());
      abrirBytesEmNovaAba(c.bytes, c.contentType);
    } catch (e) {
      GigToast.show('$e', type: GigToastType.error);
    }
  }

  void _ampliar(Uint8List bytes) {
    showDialog<void>(
      context: context,
      barrierColor: GigColors.scrim,
      builder: (contexto) => Dialog(
        backgroundColor: GigColors.background,
        insetPadding: const EdgeInsets.all(GigSpacing.xxl),
        child: Stack(children: [
          InteractiveViewer(
            maxScale: 6,
            child: Center(child: _Imagem(bytes: bytes, quartos: _quartos)),
          ),
          Positioned(
            top: GigSpacing.sm,
            right: GigSpacing.sm,
            child: IconButton(
              tooltip: 'Fechar',
              onPressed: () => Navigator.pop(contexto),
              icon: const Icon(LucideIcons.x),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.arquivo;
    final corSituacao = switch (a.situacao) {
      SituacaoArquivo.aceito => GigColors.success,
      SituacaoArquivo.recusado => GigColors.danger,
      SituacaoArquivo.pendente => GigColors.info,
    };
    return _Painel(
      key: Key('arquivo-${a.tipo.api}'),
      titulo: widget.titulo,
      acao: Etiqueta(texto: a.situacao.rotulo, cor: corSituacao),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (!a.disponivel)
          Text('Arquivo descartado (LGPD). Hash: ${a.sha256}', style: GigTypography.bodyMuted)
        else if (a.ehPdf)
          GigButton.outline(
            key: Key('abrir-pdf-${a.tipo.api}'),
            label: 'Abrir PDF',
            icon: LucideIcons.fileText,
            onPressed: _abrirPdf,
          )
        else
          FutureBuilder<({Uint8List bytes, String contentType})>(
            future: _conteudo,
            builder: (context, s) {
              if (s.hasError) return Text('${s.error}', style: GigTypography.bodyMuted);
              if (!s.hasData) {
                return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
              }
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                InkWell(
                  onTap: () => _ampliar(s.data!.bytes),
                  child: SizedBox(
                    height: 260,
                    child: ClipRRect(
                      borderRadius: GigRadius.button,
                      child: ColoredBox(color: GigColors.background, child: _Imagem(bytes: s.data!.bytes, quartos: _quartos)),
                    ),
                  ),
                ),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  IconButton(
                    tooltip: 'Girar',
                    onPressed: () => setState(() => _quartos = (_quartos + 1) % 4),
                    icon: const Icon(LucideIcons.rotateCw, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Ampliar',
                    onPressed: () => _ampliar(s.data!.bytes),
                    icon: const Icon(LucideIcons.maximize2, size: 18),
                  ),
                ]),
              ]);
            },
          ),
        const SizedBox(height: GigSpacing.xs),
        Text('${(a.tamanho / 1024).round()} KB · ${a.contentType}', style: GigTypography.caption),
        if (a.situacao == SituacaoArquivo.recusado) ...[
          const SizedBox(height: GigSpacing.sm),
          Text('Motivo: ${a.motivo?.rotulo ?? a.motivoDescricao ?? '—'}', style: GigTypography.body),
          if (a.comentario != null) Text('“${a.comentario}”', style: GigTypography.bodyMuted),
        ],
      ]),
    );
  }
}

/// Imagem com a marca d'água "GiG — uso interno — {quem está vendo}" (desestimula print e repasse).
class _Imagem extends StatelessWidget {
  const _Imagem({required this.bytes, required this.quartos});

  final Uint8List bytes;
  final int quartos;

  @override
  Widget build(BuildContext context) {
    final quem = getIt.isRegistered<SessaoStore>() ? getIt<SessaoStore>().membro.value?.nome ?? '' : '';
    return Stack(fit: StackFit.passthrough, alignment: Alignment.center, children: [
      RotatedBox(
        quarterTurns: quartos,
        child: Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true, filterQuality: FilterQuality.medium),
      ),
      IgnorePointer(
        child: Center(
          child: Transform.rotate(
            angle: -0.5,
            child: Text(
              'GiG — uso interno${quem.isEmpty ? '' : ' — $quem'}',
              key: const Key('marca-dagua'),
              textAlign: TextAlign.center,
              style: GigTypography.h3.copyWith(color: GigColors.text.withAlpha(70)),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ---------------------------------------------------------------- sem CNPJ

class _Contato extends StatelessWidget {
  const _Contato({required this.v});

  final VerificacaoDetalhe v;

  @override
  Widget build(BuildContext context) {
    return _Painel(
      key: const Key('contato-sem-cnpj'),
      titulo: 'Pedido de contato (casa sem CNPJ)',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('A casa não tem CNPJ e pediu o selo. Entre em contato, confira se ela existe mesmo e registre o que '
            'apurou na observação interna.', style: GigTypography.small),
        const SizedBox(height: GigSpacing.md),
        _Dado('Telefone', _telefone(v.contatoTelefone)),
        _Dado('Endereço', v.atuais.endereco ?? v.enviados.endereco),
        const SizedBox(height: GigSpacing.md),
        Text('MENSAGEM DA CASA', style: GigTypography.fieldLabel),
        const SizedBox(height: GigSpacing.xs),
        SelectableText(v.contatoMensagem ?? '—', style: GigTypography.bodyLarge),
      ]),
    );
  }

  static String? _telefone(String? d) {
    if (d == null || d.length < 10) return d;
    final resto = d.substring(2);
    final corte = resto.length - 4;
    return '(${d.substring(0, 2)}) ${resto.substring(0, corte)}-${resto.substring(corte)}';
  }
}

// ---------------------------------------------------------------- painéis da direita

class _Dados extends StatelessWidget {
  const _Dados({required this.v});

  final VerificacaoDetalhe v;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (v.dadosMudaram) ...[
        Container(
          key: const Key('dados-mudaram'),
          padding: const EdgeInsets.all(GigSpacing.sm),
          decoration: BoxDecoration(
            color: GigColors.primarySoft,
            borderRadius: GigRadius.button,
            border: Border.all(color: GigColors.primaryBorder),
          ),
          child: Text('A casa mudou CNPJ ou endereço depois do envio. Atual: '
              '${formatarCnpj(v.atuais.cnpj)} · ${v.atuais.endereco ?? '—'}', style: GigTypography.small),
        ),
        const SizedBox(height: GigSpacing.sm),
      ],
      _Dado('CNPJ', formatarCnpj(v.enviados.cnpj)),
      _Dado('Razão social', v.enviados.razaoSocial),
      _Dado('Endereço', v.enviados.endereco),
      _Dado('Consentimento', v.consentimentoEm == null ? null : Formatar.dataHora(v.consentimentoEm!)),
      const SizedBox(height: GigSpacing.sm),
      Wrap(spacing: GigSpacing.sm, runSpacing: GigSpacing.sm, children: [
        OutlinedButton.icon(
          key: const Key('copiar-cnpj'),
          onPressed: v.enviados.cnpj == null
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: v.enviados.cnpj!));
                  GigToast.show('CNPJ copiado.');
                },
          icon: const Icon(LucideIcons.copy, size: 14),
          label: const Text('Copiar CNPJ'),
        ),
        OutlinedButton.icon(
          key: const Key('consultar-receita'),
          onPressed: () => abrirEnderecoEmNovaAba(VerificacaoDetalhePage.consultaCnpj),
          icon: const Icon(LucideIcons.externalLink, size: 14),
          label: const Text('Consultar na Receita'),
        ),
      ]),
    ]);
  }
}

class _OQueConferir extends StatelessWidget {
  const _OQueConferir();

  static const _itens = [
    'CNPJ ativo na consulta da Receita Federal.',
    'Rosto da selfie igual ao da foto do documento, e o documento da selfie é o mesmo enviado.',
    'Documento legível, dentro da validade e sem sinais de edição.',
    'Comprovante em nome do estabelecimento ou no endereço cadastrado; conta com até 90 dias.',
    'Endereço do comprovante e da Receita batem com o do app.',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final t in _itens)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: GigSpacing.xxs),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Icon(LucideIcons.checkSquare, size: 14, color: GigColors.primary),
            ),
            const SizedBox(width: GigSpacing.sm),
            Expanded(child: Text(t, style: GigTypography.body)),
          ]),
        ),
    ]);
  }
}

class _Devolutiva extends StatelessWidget {
  const _Devolutiva({required this.v});

  final VerificacaoDetalhe v;

  @override
  Widget build(BuildContext context) {
    return _Painel(
      key: const Key('devolutiva'),
      titulo: 'Devolutiva',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        EtiquetaVerificacao(situacao: v.situacao),
        const SizedBox(height: GigSpacing.sm),
        Text(
          'Por ${v.analisadaPor ?? '—'} em ${v.analisadaEm == null ? '—' : Formatar.dataHora(v.analisadaEm!)} · a casa '
          'foi notificada no app',
          style: GigTypography.small,
        ),
        if (v.mensagemParaCasa != null) ...[
          const SizedBox(height: GigSpacing.md),
          Text('MENSAGEM PARA A CASA', style: GigTypography.fieldLabel),
          const SizedBox(height: GigSpacing.xs),
          SelectableText(v.mensagemParaCasa!, style: GigTypography.body),
        ],
      ]),
    );
  }
}

class _Dado extends StatelessWidget {
  const _Dado(this.rotulo, this.valor);

  final String rotulo;
  final String? valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GigSpacing.xxs),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 120, child: Text(rotulo, style: GigTypography.small)),
        Expanded(child: SelectableText(valor == null || valor!.isEmpty ? '—' : valor!, style: GigTypography.body)),
      ]),
    );
  }
}

class _Painel extends StatelessWidget {
  const _Painel({super.key, required this.titulo, required this.child, this.acao});

  final String titulo;
  final Widget child;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GigSpacing.xl),
      decoration: BoxDecoration(
        color: GigColors.surface,
        borderRadius: GigRadius.card,
        border: Border.all(color: GigColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(titulo.toUpperCase(), style: GigTypography.fieldLabel)),
          if (acao != null) acao!,
        ]),
        const SizedBox(height: GigSpacing.md),
        child,
      ]),
    );
  }
}

// ---------------------------------------------------------------- pedir ajuste / recusar

class _Ajuste {
  const _Ajuste(this.recusas, this.mensagem);

  final List<RecusaDeArquivo> recusas;
  final String? mensagem;
}

/// Escolhe os arquivos a reenviar (motivo obrigatório em cada) e a mensagem para a casa, com a prévia do que ela vê.
/// No pedido sem CNPJ, só a mensagem (obrigatória).
class _DialogoAjuste extends StatefulWidget {
  const _DialogoAjuste({required this.verificacao});

  final VerificacaoDetalhe verificacao;

  @override
  State<_DialogoAjuste> createState() => _DialogoAjusteState();
}

class _DialogoAjusteState extends State<_DialogoAjuste> {
  final Map<String, MotivoRecusa?> _escolhidos = {};
  final Map<String, TextEditingController> _comentarios = {};
  final _mensagem = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mensagem.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in _comentarios.values) {
      c.dispose();
    }
    _mensagem.dispose();
    super.dispose();
  }

  bool get _semCnpj => widget.verificacao.semCnpj;

  bool get _valido => _semCnpj
      ? _mensagem.text.trim().isNotEmpty
      : _escolhidos.isNotEmpty && _escolhidos.values.every((m) => m != null);

  String get _previa {
    final n = _escolhidos.length;
    if (_semCnpj) return 'Não foi possível verificar sua casa agora · Toque para ver a mensagem da equipe.';
    return 'Precisamos de um ajuste na sua verificação · $n ${n == 1 ? 'documento precisa' : 'documentos precisam'} '
        'ser reenviado${n == 1 ? '' : 's'}. Toque para ver o que corrigir.';
  }

  void _confirmar() {
    final recusas = [
      for (final e in _escolhidos.entries)
        RecusaDeArquivo(arquivoId: e.key, motivo: e.value!, comentario: _comentarios[e.key]?.text),
    ];
    Navigator.pop(context, _Ajuste(recusas, _mensagem.text.trim().isEmpty ? null : _mensagem.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.verificacao;
    return Dialog(
      backgroundColor: GigColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: GigRadius.card, side: BorderSide(color: GigColors.border)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(GigSpacing.xxl),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Text(_semCnpj ? 'Recusar pedido' : 'Pedir ajuste', style: GigTypography.h2),
            const SizedBox(height: GigSpacing.xs),
            Text(
              _semCnpj
                  ? 'A casa lê a mensagem no app, assinada como Equipe GiG.'
                  : 'Escolha o que a casa precisa reenviar. O resto fica aprovado e não precisa mandar de novo.',
              style: GigTypography.small,
            ),
            const SizedBox(height: GigSpacing.lg),
            Flexible(
              child: ListView(shrinkWrap: true, children: [
                if (!_semCnpj)
                  for (final a in v.arquivos) _linhaArquivo(a),
                const SizedBox(height: GigSpacing.md),
                TextField(
                  key: const Key('mensagem-para-casa'),
                  controller: _mensagem,
                  minLines: 2,
                  maxLines: 5,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    labelText: _semCnpj ? 'Mensagem para a casa (obrigatória)' : 'Mensagem para a casa (opcional)',
                  ),
                ),
                const SizedBox(height: GigSpacing.sm),
                Container(
                  key: const Key('previa-notificacao'),
                  padding: const EdgeInsets.all(GigSpacing.md),
                  decoration: BoxDecoration(
                    color: GigColors.background,
                    borderRadius: GigRadius.button,
                    border: Border.all(color: GigColors.border),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(LucideIcons.bell, size: 16, color: GigColors.primary),
                    const SizedBox(width: GigSpacing.sm),
                    Expanded(child: Text('Notificação no app: $_previa', style: GigTypography.small)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: GigSpacing.lg),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              const SizedBox(width: GigSpacing.sm),
              GigButton(
                key: const Key('confirmar-ajuste'),
                label: _semCnpj ? 'Recusar e notificar' : 'Pedir ajuste e notificar',
                onPressed: _valido ? _confirmar : null,
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _linhaArquivo(ArquivoVerificacao a) {
    final marcado = _escolhidos.containsKey(a.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: GigSpacing.sm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CheckboxListTile(
          key: Key('recusar-${a.tipo.api}'),
          value: marcado,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: GigColors.primary,
          checkColor: GigColors.onPrimary,
          title: Text(a.tipo.rotulo, style: GigTypography.body),
          onChanged: (m) => setState(() {
            if (m ?? false) {
              _escolhidos[a.id] = null;
              _comentarios.putIfAbsent(a.id, TextEditingController.new);
            } else {
              _escolhidos.remove(a.id);
            }
          }),
        ),
        if (marcado)
          Padding(
            padding: const EdgeInsets.only(left: GigSpacing.xxxl),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: DropdownButtonFormField<MotivoRecusa>(
                  key: Key('motivo-${a.tipo.api}'),
                  value: _escolhidos[a.id],
                  hint: const Text('Motivo'),
                  dropdownColor: GigColors.surfaceHigh,
                  items: [for (final m in MotivoRecusa.values) DropdownMenuItem(value: m, child: Text(m.rotulo))],
                  onChanged: (m) => setState(() => _escolhidos[a.id] = m),
                ),
              ),
              const SizedBox(width: GigSpacing.md),
              Expanded(
                child: TextField(
                  key: Key('comentario-${a.tipo.api}'),
                  controller: _comentarios[a.id],
                  maxLength: 500,
                  decoration: const InputDecoration(hintText: 'Comentário (opcional)'),
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}
