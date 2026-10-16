import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/di.dart';
import '../../app/rotas.dart';
import '../../core/formatar.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/gig_button.dart';
import '../../core/widgets/gig_toast.dart';
import '../../data/mock/mock_repositories.dart';
import '../../data/models/denuncia.dart';
import '../../data/repositories/repositories.dart';
import '../sugestoes/widgets.dart';
import 'denuncias_page.dart';
import 'denuncias_store.dart';

/// E31 (E3 do backoffice) — detalhe de uma denúncia: retrato (o que foi denunciado) × perfil atual lado a lado; à
/// direita a denúncia, o histórico do perfil e a decisão (Improcedente, Remover foto/bio, Advertir, Suspender 7/30
/// dias, Banir). Cada ação confirma antes, dizendo o que a pessoa vai receber; banir pede confirmação dupla.
class DenunciaDetalhePage extends StatefulWidget {
  const DenunciaDetalhePage({super.key, required this.id});

  final String id;

  @override
  State<DenunciaDetalhePage> createState() => _DenunciaDetalhePageState();
}

class _DenunciaDetalhePageState extends State<DenunciaDetalhePage> {
  final _repo = getIt<DenunciaRepository>();
  final _observacao = TextEditingController();
  final _mensagem = TextEditingController();
  DenunciaDetalhe? _d;
  String? _erro;
  bool _decidindo = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void didUpdateWidget(covariant DenunciaDetalhePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _d = null;
      _carregar();
    }
  }

  @override
  void dispose() {
    _observacao.dispose();
    _mensagem.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final d = await _repo.detalhe(widget.id);
      if (!mounted) return;
      setState(() {
        _d = d;
        _erro = null;
      });
    } on SessaoExpiradaException {
      // volta para o login
    } catch (e) {
      if (mounted) setState(() => _erro = '$e');
    }
  }

  Future<void> _enviar(DecisaoDenuncia decisao, String sucesso) async {
    setState(() => _decidindo = true);
    try {
      final d = await _repo.decidir(widget.id, decisao);
      if (!mounted) return;
      setState(() => _d = d);
      GigToast.show(sucesso, type: GigToastType.success);
      getIt<DenunciasStore>().atualizarContagem();
    } on DenunciaJaAnalisadaException catch (e) {
      GigToast.show('$e', type: GigToastType.error);
      await _carregar();
    } catch (e) {
      GigToast.show('$e', type: GigToastType.error);
    } finally {
      if (mounted) setState(() => _decidindo = false);
    }
  }

  String get _obs => _observacao.text;
  String get _msg => _mensagem.text;

  Future<void> _improcedente(DenunciaDetalhe d) async {
    final ok = await showGigConfirmDialog(
      context,
      title: 'Marcar como improcedente',
      message: 'Nenhuma ação no perfil de ${d.atual.nome}. Quem denunciou recebe "Analisamos sua denúncia".'
          '${d.atual.fotoOculta ? ' A foto escondida automaticamente volta a aparecer.' : ''}'
          '${d.totalDoPerfil > 1 ? ' Vale para as ${d.totalDoPerfil} denúncias abertas sobre este perfil.' : ''}',
      confirmLabel: 'Improcedente',
    );
    if (!ok || !mounted) return;
    await _enviar(DecisaoDenuncia.improcedente(observacaoInterna: _obs), 'Denúncia marcada como improcedente.');
  }

  Future<void> _remover(DenunciaDetalhe d) async {
    final escolha = await showDialog<({bool foto, bool sobre})>(
      context: context,
      barrierColor: GigColors.scrim,
      builder: (_) => _DialogoRemover(nome: d.atual.nome),
    );
    if (escolha == null || !mounted) return;
    await _enviar(
      DecisaoDenuncia(
        procedente: true,
        acao: AcaoDenuncia.conteudoRemovido,
        removerFoto: escolha.foto,
        removerSobre: escolha.sobre,
        observacaoInterna: _obs,
        mensagemParaDenunciado: _msg,
      ),
      'Conteúdo removido. A pessoa foi avisada no app.',
    );
  }

  Future<void> _advertir(DenunciaDetalhe d) async {
    final ok = await showGigConfirmDialog(
      context,
      title: 'Advertir ${d.atual.nome}',
      message: 'A pessoa recebe o aviso "Advertência da equipe GiG"${_msg.trim().isEmpty ? '' : ' com a sua mensagem'}. '
          'O perfil continua no ar.',
      confirmLabel: 'Advertir',
    );
    if (!ok || !mounted) return;
    await _enviar(
      DecisaoDenuncia(
        procedente: true,
        acao: AcaoDenuncia.advertencia,
        observacaoInterna: _obs,
        mensagemParaDenunciado: _msg,
      ),
      'Advertência enviada. A pessoa foi avisada no app.',
    );
  }

  Future<void> _suspender(DenunciaDetalhe d) async {
    final dias = await showDialog<int>(
      context: context,
      barrierColor: GigColors.scrim,
      builder: (_) => _DialogoSuspender(nome: d.atual.nome, agora: getIt<Relogio>()()),
    );
    if (dias == null || !mounted) return;
    await _enviar(
      DecisaoDenuncia(
        procedente: true,
        acao: AcaoDenuncia.suspensao,
        diasSuspensao: dias,
        observacaoInterna: _obs,
        mensagemParaDenunciado: _msg,
      ),
      'Conta suspensa por $dias dias. A pessoa foi avisada no app.',
    );
  }

  Future<void> _banir(DenunciaDetalhe d) async {
    final primeira = await showGigConfirmDialog(
      context,
      title: 'Banir ${d.atual.nome}?',
      message: 'O banimento é definitivo: a conta não entra mais no app, some de todas as listas e as sessões são '
          'encerradas. A pessoa não recebe aviso no app.',
      confirmLabel: 'Continuar',
      destructive: true,
    );
    if (!primeira || !mounted) return;
    final segunda = await showGigConfirmDialog(
      context,
      title: 'Confirmar banimento',
      message: 'Tem certeza? Não dá para desfazer pelo backoffice.',
      confirmLabel: 'Banir',
      destructive: true,
    );
    if (!segunda || !mounted) return;
    await _enviar(
      DecisaoDenuncia(procedente: true, acao: AcaoDenuncia.banimento, observacaoInterna: _obs),
      'Conta banida.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return ListView(
      padding: const EdgeInsets.all(GigSpacing.xxxl),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.go(Rotas.denuncias),
            icon: const Icon(LucideIcons.arrowLeft, size: 16),
            label: const Text('Voltar para Denúncias'),
          ),
        ),
        const SizedBox(height: GigSpacing.md),
        if (_erro != null)
          Text(_erro!, style: GigTypography.body)
        else if (d == null)
          const Center(child: Padding(padding: EdgeInsets.all(GigSpacing.huge), child: CircularProgressIndicator()))
        else ...[
          _cabecalho(d),
          const SizedBox(height: GigSpacing.xl),
          LayoutBuilder(builder: (context, c) {
            final esquerda = _Comparacao(d: d, repo: _repo);
            final direita = _direita(d);
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

  Widget _cabecalho(DenunciaDetalhe d) {
    final prazo = prazoDaDenuncia(d.situacao, d.prazoAnalise, getIt<Relogio>()());
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: GigSpacing.sm, runSpacing: GigSpacing.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
        EtiquetaGravidade(gravidade: d.gravidade),
        EtiquetaDenuncia(situacao: d.situacao, acao: d.decisao?.acao),
        EtiquetaPrazo(prazo: prazo),
        if (d.atual.banidoEm != null) const Etiqueta(texto: 'Conta banida', cor: GigColors.danger, preenchida: true),
        if (d.atual.suspensoAte != null && d.atual.suspensoAte!.isAfter(getIt<Relogio>()()))
          Etiqueta(texto: 'Suspensa até ${Formatar.data(d.atual.suspensoAte!)}', cor: GigColors.danger),
      ]),
      const SizedBox(height: GigSpacing.md),
      Text(d.tipoDescricao, style: GigTypography.h1),
      Text(
        [
          '${rotuloDoPerfil(d.atual.perfil)}: ${d.atual.nome}',
          'recebida em ${Formatar.dataHora(d.criadaEm)}',
          if (d.aberta) 'prazo ${Formatar.dataHora(d.prazoAnalise)}',
        ].join(' · '),
        style: GigTypography.small,
      ),
    ]);
  }

  Widget _direita(DenunciaDetalhe d) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Painel(
        titulo: 'Denúncia',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Dado('Tipo', d.tipoDescricao),
          _Dado('Origem', rotuloDaOrigem(d.origem)),
          _Dado('Quem denunciou', d.denunciante == null
              ? 'Conta excluída'
              : '${d.denunciante} (${rotuloDoPerfil(d.perfilDenunciante)}) — só a equipe vê'),
          const SizedBox(height: GigSpacing.sm),
          Text('COMENTÁRIO', style: GigTypography.fieldLabel),
          const SizedBox(height: GigSpacing.xs),
          SelectableText(d.comentario ?? 'Sem comentário.', style: GigTypography.body),
        ]),
      ),
      const SizedBox(height: GigSpacing.lg),
      _Painel(
        key: const Key('historico-perfil'),
        titulo: 'Histórico do perfil',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
            '${d.totalDoPerfil} ${d.totalDoPerfil == 1 ? 'denúncia' : 'denúncias'} de ${d.pessoasDistintas} '
            '${d.pessoasDistintas == 1 ? 'pessoa' : 'pessoas diferentes'}',
            style: GigTypography.body,
          ),
          for (final h in d.historico) ...[
            const SizedBox(height: GigSpacing.sm),
            Row(children: [
              EtiquetaGravidade(gravidade: h.gravidade),
              const SizedBox(width: GigSpacing.sm),
              Expanded(child: Text(h.tipoDescricao, overflow: TextOverflow.ellipsis, style: GigTypography.small)),
              const SizedBox(width: GigSpacing.sm),
              Text(Formatar.data(h.criadaEm), style: GigTypography.small),
              const SizedBox(width: GigSpacing.sm),
              EtiquetaDenuncia(situacao: h.situacao, acao: h.acao),
            ]),
          ],
        ]),
      ),
      const SizedBox(height: GigSpacing.lg),
      if (d.aberta) _decisao(d) else _DecisaoTomada(d: d),
    ]);
  }

  Widget _decisao(DenunciaDetalhe d) {
    return _Painel(
      titulo: 'Decisão',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (d.totalDoPerfil > 1) ...[
          Text('A decisão vale para todas as denúncias abertas sobre este perfil.', style: GigTypography.small),
          const SizedBox(height: GigSpacing.sm),
        ],
        TextField(
          key: const Key('mensagem-denunciado'),
          controller: _mensagem,
          minLines: 2,
          maxLines: 6,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Mensagem para a pessoa (opcional)',
            helperText: 'Aparece no aviso (conteúdo removido, advertência e suspensão). Nunca diga quem denunciou.',
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: GigSpacing.sm),
        TextField(
          key: const Key('observacao-interna-denuncia'),
          controller: _observacao,
          minLines: 2,
          maxLines: 6,
          maxLength: 2000,
          decoration: const InputDecoration(labelText: 'Observação interna (só a equipe vê)'),
        ),
        const SizedBox(height: GigSpacing.md),
        GigButton.outline(
          key: const Key('decidir-improcedente'),
          label: 'Improcedente',
          icon: LucideIcons.x,
          onPressed: _decidindo ? null : () => _improcedente(d),
        ),
        const SizedBox(height: GigSpacing.sm),
        GigButton.outline(
          key: const Key('decidir-remover'),
          label: 'Remover foto/bio',
          icon: LucideIcons.imageOff,
          onPressed: _decidindo ? null : () => _remover(d),
        ),
        const SizedBox(height: GigSpacing.sm),
        GigButton.outline(
          key: const Key('decidir-advertir'),
          label: 'Advertir',
          icon: LucideIcons.alertTriangle,
          onPressed: _decidindo ? null : () => _advertir(d),
        ),
        const SizedBox(height: GigSpacing.sm),
        GigButton.outline(
          key: const Key('decidir-suspender'),
          label: 'Suspender (7/30 dias)',
          icon: LucideIcons.clock,
          onPressed: _decidindo ? null : () => _suspender(d),
        ),
        const SizedBox(height: GigSpacing.sm),
        GigButton.danger(
          key: const Key('decidir-banir'),
          label: 'Banir',
          icon: LucideIcons.ban,
          loading: _decidindo,
          onPressed: _decidindo ? null : () => _banir(d),
        ),
        const SizedBox(height: GigSpacing.xs),
        Text('Quem denunciou recebe "Analisamos sua denúncia", sem saber a ação.',
            style: GigTypography.caption, textAlign: TextAlign.center),
      ]),
    );
  }
}

// ---------------------------------------------------------------- retrato × atual

class _Comparacao extends StatelessWidget {
  const _Comparacao({required this.d, required this.repo});

  final DenunciaDetalhe d;
  final DenunciaRepository repo;

  @override
  Widget build(BuildContext context) {
    final r = d.retrato;
    final a = d.atual;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: _Painel(
          key: const Key('retrato'),
          titulo: 'Na hora da denúncia',
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            r.temFoto ? _FotoDoRetrato(id: d.id, repo: repo) : const _SemFoto(),
            const SizedBox(height: GigSpacing.md),
            Text(r.nome, style: GigTypography.h3),
            Text([r.cidade, r.estado].whereType<String>().where((t) => t.isNotEmpty).join('/'),
                style: GigTypography.small),
            const SizedBox(height: GigSpacing.sm),
            SelectableText(r.sobre ?? 'Sem "sobre".', style: GigTypography.body),
          ]),
        ),
      ),
      const SizedBox(width: GigSpacing.lg),
      Expanded(
        child: _Painel(
          key: const Key('perfil-atual'),
          titulo: 'Perfil agora',
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (a.fotoUrl != null)
              ClipRRect(
                borderRadius: GigRadius.button,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(a.fotoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _SemFoto()),
                ),
              )
            else
              const _SemFoto(),
            if (a.fotoOculta) ...[
              const SizedBox(height: GigSpacing.sm),
              const Etiqueta(
                key: Key('foto-oculta'),
                texto: 'Foto escondida automaticamente',
                cor: GigColors.primary,
              ),
            ],
            const SizedBox(height: GigSpacing.md),
            Text(a.nome, style: GigTypography.h3),
            Text('${rotuloDoPerfil(a.perfil)} · ${[a.cidade, a.estado].whereType<String>().where((t) => t.isNotEmpty).join('/')}',
                style: GigTypography.small),
            const SizedBox(height: GigSpacing.sm),
            SelectableText(a.sobre ?? 'Sem "sobre".', style: GigTypography.body),
          ]),
        ),
      ),
    ]);
  }
}

class _FotoDoRetrato extends StatefulWidget {
  const _FotoDoRetrato({required this.id, required this.repo});

  final String id;
  final DenunciaRepository repo;

  @override
  State<_FotoDoRetrato> createState() => _FotoDoRetratoState();
}

class _FotoDoRetratoState extends State<_FotoDoRetrato> {
  late final Future<({Uint8List bytes, String contentType})> _foto = widget.repo.foto(widget.id);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({Uint8List bytes, String contentType})>(
      future: _foto,
      builder: (context, s) {
        if (s.hasError) return Text('Não foi possível abrir a foto.', style: GigTypography.small);
        final dados = s.data;
        if (dados == null) {
          return const AspectRatio(aspectRatio: 1, child: Center(child: CircularProgressIndicator()));
        }
        return ClipRRect(
          borderRadius: GigRadius.button,
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.memory(dados.bytes, key: const Key('foto-retrato'), fit: BoxFit.cover, gaplessPlayback: true),
          ),
        );
      },
    );
  }
}

class _SemFoto extends StatelessWidget {
  const _SemFoto();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: GigColors.surfaceHigh,
          borderRadius: GigRadius.button,
          border: Border.all(color: GigColors.border),
        ),
        child: const Center(child: Icon(LucideIcons.user, color: GigColors.textMuted, size: 40)),
      ),
    );
  }
}

class _DecisaoTomada extends StatelessWidget {
  const _DecisaoTomada({required this.d});

  final DenunciaDetalhe d;

  @override
  Widget build(BuildContext context) {
    final x = d.decisao;
    return _Painel(
      key: const Key('decisao-tomada'),
      titulo: 'Decisão',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        EtiquetaDenuncia(situacao: d.situacao, acao: x?.acao),
        const SizedBox(height: GigSpacing.sm),
        if (x != null) ...[
          Text('Por ${x.analisadaPor ?? '—'} em ${Formatar.dataHora(x.analisadaEm)}', style: GigTypography.small),
          if (x.diasSuspensao != null) Text('Suspensão de ${x.diasSuspensao} dias', style: GigTypography.body),
          if (x.fotoRemovida || x.sobreRemovido)
            Text('Removido: ${[if (x.fotoRemovida) 'foto', if (x.sobreRemovido) 'sobre'].join(' e ')}',
                style: GigTypography.body),
          if (x.mensagemParaDenunciado != null) ...[
            const SizedBox(height: GigSpacing.md),
            Text('MENSAGEM PARA A PESSOA', style: GigTypography.fieldLabel),
            const SizedBox(height: GigSpacing.xs),
            SelectableText(x.mensagemParaDenunciado!, style: GigTypography.body),
          ],
          if (x.observacaoInterna != null) ...[
            const SizedBox(height: GigSpacing.md),
            Text('OBSERVAÇÃO INTERNA', style: GigTypography.fieldLabel),
            const SizedBox(height: GigSpacing.xs),
            SelectableText(x.observacaoInterna!, style: GigTypography.body),
          ],
        ],
      ]),
    );
  }
}

// ---------------------------------------------------------------- diálogos

class _DialogoRemover extends StatefulWidget {
  const _DialogoRemover({required this.nome});

  final String nome;

  @override
  State<_DialogoRemover> createState() => _DialogoRemoverState();
}

class _DialogoRemoverState extends State<_DialogoRemover> {
  bool _foto = false;
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: GigColors.surface,
      title: Text('Remover do perfil de ${widget.nome}', style: GigTypography.h2),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        CheckboxListTile(
          key: const Key('remover-foto'),
          value: _foto,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: GigColors.primary,
          checkColor: GigColors.onPrimary,
          title: Text('Foto', style: GigTypography.body),
          onChanged: (v) => setState(() => _foto = v ?? false),
        ),
        CheckboxListTile(
          key: const Key('remover-sobre'),
          value: _sobre,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: GigColors.primary,
          checkColor: GigColors.onPrimary,
          title: Text('Texto do "Sobre"', style: GigTypography.body),
          onChanged: (v) => setState(() => _sobre = v ?? false),
        ),
        const SizedBox(height: GigSpacing.sm),
        Text('A pessoa recebe o aviso "Removemos um conteúdo do seu perfil".', style: GigTypography.small),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('confirmar-remocao'),
          onPressed: _foto || _sobre ? () => Navigator.of(context).pop((foto: _foto, sobre: _sobre)) : null,
          child: const Text('Remover'),
        ),
      ],
    );
  }
}

class _DialogoSuspender extends StatelessWidget {
  const _DialogoSuspender({required this.nome, required this.agora});

  final String nome;
  final DateTime agora;

  @override
  Widget build(BuildContext context) {
    Widget opcao(int dias) => ListTile(
          key: Key('suspender-$dias'),
          leading: const Icon(LucideIcons.clock, color: GigColors.textMuted),
          title: Text('$dias dias', style: GigTypography.body),
          subtitle: Text('Até ${Formatar.data(agora.add(Duration(days: dias)))}', style: GigTypography.small),
          onTap: () => Navigator.of(context).pop(dias),
        );
    return AlertDialog(
      backgroundColor: GigColors.surface,
      title: Text('Suspender $nome', style: GigTypography.h2),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'A conta não entra no app até a data, some das listas (Quem vai, candidatos, buscas) e as sessões são '
          'encerradas. A pessoa recebe o aviso com a data.',
          style: GigTypography.small,
        ),
        const SizedBox(height: GigSpacing.sm),
        opcao(7),
        opcao(30),
      ]),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar'))],
    );
  }
}

// ---------------------------------------------------------------- blocos

class _Painel extends StatelessWidget {
  const _Painel({super.key, required this.titulo, required this.child});

  final String titulo;
  final Widget child;

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
        Text(titulo.toUpperCase(), style: GigTypography.fieldLabel),
        const SizedBox(height: GigSpacing.md),
        child,
      ]),
    );
  }
}

class _Dado extends StatelessWidget {
  const _Dado(this.rotulo, this.valor);

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GigSpacing.xxs),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 120, child: Text(rotulo, style: GigTypography.small)),
        Expanded(child: SelectableText(valor, style: GigTypography.body)),
      ]),
    );
  }
}
