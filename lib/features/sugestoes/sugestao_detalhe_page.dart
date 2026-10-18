import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import 'sugestoes_store.dart';
import 'widgets.dart';

/// Detalhe de uma sugestão: texto e contexto à esquerda; linha do tempo, "Marcar em análise" e resposta à direita.
class SugestaoDetalhePage extends StatefulWidget {
  const SugestaoDetalhePage({super.key, required this.id});

  static const respostaMin = 2;
  static const respostaMax = 2000;

  final String id;

  @override
  State<SugestaoDetalhePage> createState() => _SugestaoDetalhePageState();
}

class _SugestaoDetalhePageState extends State<SugestaoDetalhePage> {
  final _repo = getIt<SugestaoRepository>();
  final _resposta = TextEditingController();
  SugestaoDetalhe? _sugestao;
  String? _erro;
  bool _marcando = false;
  bool _enviando = false;
  bool _implementando = false;

  @override
  void initState() {
    super.initState();
    _resposta.addListener(() => setState(() {}));
    _carregar();
  }

  @override
  void didUpdateWidget(covariant SugestaoDetalhePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _sugestao = null;
      _carregar();
    }
  }

  @override
  void dispose() {
    _resposta.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final s = await _repo.detalhe(widget.id);
      if (!mounted) return;
      setState(() {
        _sugestao = s;
        _erro = null;
        if (!s.respondida && _resposta.text.isEmpty) _resposta.text = s.inicioSugerido;
      });
    } on SessaoExpiradaException {
      // volta para o login
    } catch (e) {
      if (mounted) setState(() => _erro = '$e');
    }
  }

  Future<void> _marcarEmAnalise() async {
    setState(() => _marcando = true);
    try {
      await _repo.marcarEmAnalise(widget.id);
      await _carregar();
      getIt<SugestoesStore>().atualizarContagem();
    } on SugestaoJaRespondidaException catch (e) {
      GigToast.show('$e', type: GigToastType.error);
      await _carregar();
    } catch (e) {
      GigToast.show('$e', type: GigToastType.error);
    } finally {
      if (mounted) setState(() => _marcando = false);
    }
  }

  Future<void> _marcarImplementada() async {
    final confirmou = await showGigConfirmDialog(
      context,
      title: 'Marcar como implementada',
      message: 'A pessoa recebe a notificação "Sua ideia virou GiG!" e ganha a conquista. Marcar?',
      confirmLabel: 'Marcar',
    );
    if (!confirmou || !mounted) return;
    setState(() => _implementando = true);
    try {
      await _repo.marcarImplementada(widget.id);
      GigToast.show('Sugestão marcada como implementada.', type: GigToastType.success);
      await _carregar();
    } catch (e) {
      GigToast.show('$e', type: GigToastType.error);
    } finally {
      if (mounted) setState(() => _implementando = false);
    }
  }

  bool get _respostaValida {
    final n = _resposta.text.trim().length;
    return n >= SugestaoDetalhePage.respostaMin && n <= SugestaoDetalhePage.respostaMax;
  }

  Future<void> _enviar() async {
    if (_enviando || !_respostaValida) return;
    final confirmou = await showGigConfirmDialog(
      context,
      title: 'Enviar resposta',
      message: 'A resposta não pode ser editada depois. Enviar?',
      confirmLabel: 'Enviar',
    );
    if (!confirmou || !mounted) return;
    setState(() => _enviando = true);
    try {
      final s = await _repo.responder(widget.id, _resposta.text.trim());
      if (!mounted) return;
      setState(() => _sugestao = s);
      GigToast.show('Resposta enviada. A pessoa vai receber uma notificação no app.', type: GigToastType.success);
      getIt<SugestoesStore>().atualizarContagem();
    } on SugestaoJaRespondidaException catch (e) {
      GigToast.show('$e', type: GigToastType.error);
      await _carregar();
    } catch (e) {
      GigToast.show('$e', type: GigToastType.error);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _sugestao;
    return ListView(
      padding: const EdgeInsets.all(GigSpacing.xxxl),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.go(Rotas.sugestoes),
            icon: const Icon(LucideIcons.arrowLeft, size: 16),
            label: const Text('Voltar para Sugestões'),
          ),
        ),
        const SizedBox(height: GigSpacing.md),
        if (_erro != null)
          Text(_erro!, style: GigTypography.body)
        else if (s == null)
          const Center(child: Padding(padding: EdgeInsets.all(GigSpacing.huge), child: CircularProgressIndicator()))
        else
          LayoutBuilder(builder: (context, c) {
            final esquerda = _Esquerda(s: s);
            final direita = _direita(s);
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
    );
  }

  Widget _direita(SugestaoDetalhe s) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Painel(titulo: 'Linha do tempo', child: _LinhaDoTempo(s: s)),
      const SizedBox(height: GigSpacing.lg),
      if (s.situacao == SituacaoSugestao.recebida) ...[
        GigButton.outline(
          key: const Key('marcar-em-analise'),
          label: 'MARCAR EM ANÁLISE',
          icon: LucideIcons.eye,
          loading: _marcando,
          onPressed: _marcarEmAnalise,
        ),
        const SizedBox(height: GigSpacing.lg),
      ],
      if (s.respondida) _RespostaEnviada(s: s) else _blocoResposta(),
      const SizedBox(height: GigSpacing.lg),
      if (s.implementada)
        Row(key: const Key('sugestao-implementada'), children: [
          const Icon(LucideIcons.checkCircle, size: 16, color: GigColors.primary),
          const SizedBox(width: GigSpacing.sm),
          Expanded(
            child: Text('Implementada em ${Formatar.dataHora(s.implementadaEm!)}', style: GigTypography.small),
          ),
        ])
      else
        GigButton.outline(
          key: const Key('marcar-implementada'),
          label: 'MARCAR COMO IMPLEMENTADA',
          icon: LucideIcons.lightbulb,
          loading: _implementando,
          onPressed: _marcarImplementada,
        ),
    ]);
  }

  Widget _blocoResposta() {
    final n = _resposta.text.trim().length;
    return _Painel(
      titulo: 'Resposta',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Lembre: a pessoa lê isso no app, assinado como Equipe GiG. Chame pelo nome e agradeça.',
            style: GigTypography.small),
        const SizedBox(height: GigSpacing.md),
        CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter, control: true): _enviar,
            const SingleActivator(LogicalKeyboardKey.enter, meta: true): _enviar,
          },
          child: TextField(
            key: const Key('campo-resposta'),
            controller: _resposta,
            minLines: 6,
            maxLines: 14,
            maxLength: SugestaoDetalhePage.respostaMax,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                Text('$n / ${SugestaoDetalhePage.respostaMax}', style: GigTypography.small),
            decoration: const InputDecoration(hintText: 'Escreva a resposta'),
          ),
        ),
        const SizedBox(height: GigSpacing.md),
        GigButton(
          key: const Key('enviar-resposta'),
          label: 'Enviar resposta',
          loading: _enviando,
          onPressed: _respostaValida ? _enviar : null,
        ),
        const SizedBox(height: GigSpacing.xs),
        Text('Atalho: Ctrl+Enter', style: GigTypography.caption, textAlign: TextAlign.center),
      ]),
    );
  }
}

class _Esquerda extends StatelessWidget {
  const _Esquerda({required this.s});

  final SugestaoDetalhe s;

  @override
  Widget build(BuildContext context) {
    final prazo = prazoDe(s.situacao, s.prazoResposta, getIt<Relogio>()());
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: GigSpacing.sm, runSpacing: GigSpacing.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
        EtiquetaSituacao(situacao: s.situacao),
        EtiquetaPrazo(prazo: prazo),
        if (s.tipo != null) Etiqueta(texto: s.tipo!.rotulo, cor: GigColors.textSubtle),
      ]),
      const SizedBox(height: GigSpacing.md),
      Text(s.nomeExibido, style: GigTypography.h1),
      Text('${s.perfil?.rotulo ?? '—'} · enviada em ${Formatar.dataHora(s.enviadaEm)} · '
          'prazo ${Formatar.dataHora(s.prazoResposta)}', style: GigTypography.small),
      const SizedBox(height: GigSpacing.lg),
      _Painel(
        titulo: 'Sugestão',
        child: SelectableText(s.texto, style: GigTypography.bodyLarge),
      ),
      const SizedBox(height: GigSpacing.lg),
      _Painel(
        titulo: 'Aparelho',
        child: s.aparelho.vazio
            ? Text('Sem dados do aparelho.', style: GigTypography.bodyMuted)
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Dado('Versão do app',
                    [s.aparelho.versaoApp, if (s.aparelho.build != null) '(build ${s.aparelho.build})'].whereType<String>().join(' ')),
                _Dado('Sistema', [s.aparelho.sistema, s.aparelho.versaoSistema].whereType<String>().join(' ')),
                _Dado('Modelo', s.aparelho.modelo),
                _Dado('Idioma', s.aparelho.idioma),
              ]),
      ),
    ]);
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
        Expanded(child: Text(valor == null || valor!.isEmpty ? '—' : valor!, style: GigTypography.body)),
      ]),
    );
  }
}

class _LinhaDoTempo extends StatelessWidget {
  const _LinhaDoTempo({required this.s});

  final SugestaoDetalhe s;

  @override
  Widget build(BuildContext context) {
    final passos = <(String, DateTime?, bool)>[
      ('Recebida', s.enviadaEm, true),
      (s.emAnalisePor == null ? 'Em análise' : 'Em análise · ${s.emAnalisePor}', s.emAnaliseDesde, s.emAnaliseDesde != null),
      (s.respondidaPor == null ? 'Respondida' : 'Respondida · ${s.respondidaPor}', s.respondidaEm, s.respondida),
    ];
    return Column(children: [
      for (final (titulo, quando, feito) in passos)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: GigSpacing.xs),
          child: Row(children: [
            Icon(feito ? LucideIcons.checkCircle : LucideIcons.circle,
                size: 16, color: feito ? GigColors.primary : GigColors.textMuted),
            const SizedBox(width: GigSpacing.sm),
            Expanded(child: Text(titulo, style: feito ? GigTypography.body : GigTypography.bodyMuted)),
            if (quando != null) Text(Formatar.dataHora(quando), style: GigTypography.small),
          ]),
        ),
    ]);
  }
}

class _RespostaEnviada extends StatelessWidget {
  const _RespostaEnviada({required this.s});

  final SugestaoDetalhe s;

  @override
  Widget build(BuildContext context) {
    return _Painel(
      key: const Key('resposta-enviada'),
      titulo: 'Resposta enviada',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SelectableText(s.resposta ?? '', style: GigTypography.bodyLarge),
        const SizedBox(height: GigSpacing.md),
        Text(
          'Por ${s.respondidaPor ?? '—'} em ${s.respondidaEm == null ? '—' : Formatar.dataHora(s.respondidaEm!)} '
          '· no app aparece como "Equipe GiG"',
          style: GigTypography.small,
        ),
      ]),
    );
  }
}

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
