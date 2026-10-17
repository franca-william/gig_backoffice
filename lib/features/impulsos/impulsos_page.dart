import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/di.dart';
import '../../app/rotas.dart';
import '../../core/formatar.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/gig_toast.dart';
import '../../data/models/impulso.dart';
import '../sugestoes/widgets.dart';
import 'impulsos_store.dart';

/// E40 — Impulsionar evento no backoffice: textos de push para aprovar, impulsos, casas que podem impulsionar
/// (flag "passível de impulsionar") e pacotes/parâmetros.
class ImpulsosPage extends StatefulWidget {
  const ImpulsosPage({super.key});

  @override
  State<ImpulsosPage> createState() => _ImpulsosPageState();
}

class _ImpulsosPageState extends State<ImpulsosPage> {
  final _store = getIt<ImpulsosStore>();
  final _busca = TextEditingController();
  final _buscaCasas = TextEditingController();
  Timer? _espera;

  @override
  void initState() {
    super.initState();
    _busca.text = _store.busca.value;
    _buscaCasas.text = _store.buscaCasas.value;
    _store.carregar();
  }

  @override
  void dispose() {
    _espera?.cancel();
    _busca.dispose();
    _buscaCasas.dispose();
    super.dispose();
  }

  void _depois(VoidCallback acao) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 400), acao);
  }

  Future<void> _executar(Future<void> Function() acao, String sucesso) async {
    try {
      await acao();
      GigToast.success(sucesso);
    } catch (e) {
      GigToast.error('$e');
    }
  }

  Future<String?> _pedirTexto({required String titulo, required String rotulo, bool obrigatorio = true}) {
    final campo = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierColor: GigColors.scrim,
      builder: (dialogo) => AlertDialog(
        backgroundColor: GigColors.surface,
        title: Text(titulo, style: GigTypography.h2),
        content: SizedBox(
          width: 420,
          child: TextField(
            key: const Key('impulso-dialogo-texto'),
            controller: campo,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(labelText: rotulo),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogo).pop(), child: const Text('Cancelar')),
          FilledButton(
            key: const Key('impulso-dialogo-confirmar'),
            onPressed: () {
              final t = campo.text.trim();
              if (obrigatorio && t.length < 3) return;
              Navigator.of(dialogo).pop(t);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(GigSpacing.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Impulsos', style: GigTypography.h1),
          const SizedBox(height: GigSpacing.xs),
          Text(
            'Card de destaque e notificação para curtidores próximos, comprados pelas casas no app (App Store / '
            'Google Play). Só casas com a flag "passível de impulsionar" veem a opção.',
            style: GigTypography.paragraph,
          ),
          const SizedBox(height: GigSpacing.xl),
          Observer(builder: (_) {
            final atual = _store.aba.value;
            final n = _store.textosEmAnalise.value;
            return Wrap(spacing: GigSpacing.sm, children: [
              for (final a in AbaImpulsos.values)
                ChoiceChip(
                  key: Key('aba-impulsos-${a.name}'),
                  label: Text(a == AbaImpulsos.textos && n > 0 ? '${a.rotulo} ($n)' : a.rotulo),
                  selected: atual == a,
                  onSelected: (_) => _store.trocarAba(a),
                  selectedColor: GigColors.primarySoft,
                  labelStyle: GigTypography.chip.copyWith(color: atual == a ? GigColors.primary : GigColors.textSubtle),
                  side: BorderSide(color: atual == a ? GigColors.primaryBorder : GigColors.border),
                  showCheckmark: false,
                ),
            ]);
          }),
          const SizedBox(height: GigSpacing.lg),
          Expanded(
            child: Observer(builder: (_) {
              if (_store.carregando.value &&
                  _store.textos.value.isEmpty &&
                  _store.impulsos.value.itens.isEmpty &&
                  _store.casas.value.isEmpty &&
                  _store.produtos.value.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_store.erro.value != null) {
                return Center(child: Text(_store.erro.value!, style: GigTypography.body));
              }
              return switch (_store.aba.value) {
                AbaImpulsos.textos => _textos(),
                AbaImpulsos.impulsos => _impulsos(),
                AbaImpulsos.casas => _casas(),
                AbaImpulsos.configuracoes => _configuracoes(),
              };
            }),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ textos

  Widget _textos() {
    final lista = _store.textos.value;
    if (lista.isEmpty) {
      return Center(child: Text('Nenhum texto esperando a equipe. 🎉', style: GigTypography.body));
    }
    return ListView.separated(
      itemCount: lista.length,
      separatorBuilder: (_, __) => const SizedBox(height: GigSpacing.md),
      itemBuilder: (_, i) {
        final t = lista[i];
        final atrasado = !t.prazo.isAfter(DateTime.now());
        return Container(
          key: Key('texto-${t.campanhaId}'),
          padding: const EdgeInsets.all(GigSpacing.lg),
          decoration: BoxDecoration(
            color: GigColors.surface,
            borderRadius: GigRadius.card,
            border: Border.all(color: GigColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text('${t.casa} · ${t.evento} · ${Formatar.dataHora(t.dataEvento)}', style: GigTypography.h3),
              ),
              Etiqueta(
                texto: atrasado ? 'Prazo vencido' : 'Até ${Formatar.dataHora(t.prazo)}',
                cor: atrasado ? GigColors.danger : GigColors.primary,
              ),
            ]),
            const SizedBox(height: GigSpacing.md),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _blocoDeTexto('Texto da casa', t.titulo, t.texto, destaque: true)),
              const SizedBox(width: GigSpacing.lg),
              Expanded(child: _blocoDeTexto('Texto automático (vai se não aprovar a tempo)', t.tituloModelo, t.textoModelo)),
            ]),
            const SizedBox(height: GigSpacing.md),
            Text(
              'Recuse texto que prometa resultado (casa cheia, lotação), seja enganoso, ofensivo ou fale de outra '
              'coisa que não o evento.',
              style: GigTypography.small,
            ),
            const SizedBox(height: GigSpacing.md),
            Row(children: [
              FilledButton.icon(
                key: Key('aprovar-${t.campanhaId}'),
                onPressed: () => _executar(() => _store.aprovar(t.campanhaId), 'Texto aprovado. A casa foi avisada.'),
                icon: const Icon(LucideIcons.checkCircle, size: 16),
                label: const Text('Aprovar'),
              ),
              const SizedBox(width: GigSpacing.sm),
              OutlinedButton.icon(
                key: Key('recusar-${t.campanhaId}'),
                onPressed: () async {
                  final motivo = await _pedirTexto(titulo: 'Recusar texto', rotulo: 'Motivo (a casa vai ler)');
                  if (motivo != null) {
                    await _executar(() => _store.recusar(t.campanhaId, motivo), 'Texto recusado. A casa foi avisada.');
                  }
                },
                icon: const Icon(LucideIcons.x, size: 16),
                label: const Text('Recusar'),
              ),
            ]),
          ]),
        );
      },
    );
  }

  Widget _blocoDeTexto(String rotulo, String titulo, String texto, {bool destaque = false}) {
    return Container(
      padding: const EdgeInsets.all(GigSpacing.md),
      decoration: BoxDecoration(
        color: GigColors.surfaceHigh,
        borderRadius: GigRadius.card,
        border: Border.all(color: destaque ? GigColors.primaryBorder : GigColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(rotulo, style: GigTypography.fieldLabel),
        const SizedBox(height: GigSpacing.xs),
        Text(titulo, style: GigTypography.body.copyWith(fontWeight: FontWeight.w700)),
        Text(texto, style: GigTypography.body),
      ]),
    );
  }

  // ------------------------------------------------------------------ impulsos

  Widget _impulsos() {
    final pagina = _store.impulsos.value;
    final filtro = _store.situacao.value;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: GigSpacing.sm, runSpacing: GigSpacing.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
        ChoiceChip(
          label: const Text('Todos'),
          selected: filtro == null,
          onSelected: (_) => _store.filtrarImpulsos(limparSituacao: true),
          showCheckmark: false,
        ),
        for (final s in [
          SituacaoImpulso.pago,
          SituacaoImpulso.concluido,
          SituacaoImpulso.estornado,
          SituacaoImpulso.encerradoPorCancelamento,
          SituacaoImpulso.aguardandoPagamento,
        ])
          ChoiceChip(
            label: Text(s.rotulo),
            selected: filtro == s,
            onSelected: (_) => _store.filtrarImpulsos(novaSituacao: s),
            showCheckmark: false,
          ),
        SizedBox(
          width: 260,
          child: TextField(
            controller: _busca,
            onChanged: (t) => _depois(() => _store.filtrarImpulsos(novaBusca: t)),
            decoration: const InputDecoration(hintText: 'Casa ou evento', prefixIcon: Icon(LucideIcons.search, size: 16)),
          ),
        ),
      ]),
      const SizedBox(height: GigSpacing.md),
      Expanded(
        child: pagina.itens.isEmpty
            ? Center(child: Text('Nenhum impulso por aqui.', style: GigTypography.body))
            : ListView.separated(
                itemCount: pagina.itens.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final r = pagina.itens[i];
                  return ListTile(
                    key: Key('linha-impulso-${r.id}'),
                    onTap: () => context.go(Rotas.impulso(r.id)),
                    leading: Icon(r.ehCard ? LucideIcons.layoutDashboard : LucideIcons.bell, color: GigColors.primary),
                    title: Text('${r.casa} · ${r.evento}', style: GigTypography.body),
                    subtitle: Text(
                      '${r.nomeProduto}${r.dataEvento == null ? '' : ' · evento ${Formatar.data(r.dataEvento!)}'}'
                      '${r.loja == null ? '' : ' · ${r.loja == 'APP_STORE' ? 'App Store' : 'Google Play'}'}'
                      '${r.ambiente == 'SANDBOX' || r.ambiente == 'TESTE' ? ' (teste)' : ''}',
                      style: GigTypography.small,
                    ),
                    trailing: Wrap(spacing: GigSpacing.sm, children: [
                      if (r.push != null) Etiqueta(texto: r.push!.rotulo, cor: GigColors.info),
                      Etiqueta(
                        texto: r.situacao.rotulo,
                        cor: switch (r.situacao) {
                          SituacaoImpulso.pago => GigColors.primary,
                          SituacaoImpulso.estornado || SituacaoImpulso.encerradoPorCancelamento => GigColors.danger,
                          _ => GigColors.textMuted,
                        },
                      ),
                    ]),
                  );
                },
              ),
      ),
      if (pagina.total > 0)
        Padding(
          padding: const EdgeInsets.only(top: GigSpacing.sm),
          child: Text('${pagina.total} impulsos (20 mais recentes)', style: GigTypography.small, textAlign: TextAlign.right),
        ),
    ]);
  }

  // ------------------------------------------------------------------ casas

  Widget _casas() {
    final lista = _store.casas.value;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        SizedBox(
          width: 300,
          child: TextField(
            key: const Key('busca-casas-impulso'),
            controller: _buscaCasas,
            onChanged: (t) => _depois(() => _store.filtrarCasas(novaBusca: t)),
            decoration: const InputDecoration(hintText: 'Nome da casa ou cidade', prefixIcon: Icon(LucideIcons.search, size: 16)),
          ),
        ),
        const SizedBox(width: GigSpacing.lg),
        FilterChip(
          label: const Text('Só as que podem impulsionar'),
          selected: _store.soHabilitadas.value,
          onSelected: (v) => _store.filtrarCasas(habilitadas: v),
        ),
      ]),
      const SizedBox(height: GigSpacing.md),
      Expanded(
        child: lista.isEmpty
            ? Center(child: Text('Nenhuma casa encontrada.', style: GigTypography.body))
            : ListView.separated(
                itemCount: lista.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final c = lista[i];
                  return ListTile(
                    key: Key('linha-casa-${c.id}'),
                    title: Row(children: [
                      Flexible(child: Text(c.nome, style: GigTypography.body, overflow: TextOverflow.ellipsis)),
                      if (c.verificada) ...[
                        const SizedBox(width: GigSpacing.sm),
                        const Etiqueta(texto: 'Verificada', cor: GigColors.success),
                      ],
                    ]),
                    subtitle: Text(
                      '${c.local.isEmpty ? 'Sem cidade' : c.local} · ${c.impulsosPagos} impulsos pagos',
                      style: GigTypography.small,
                    ),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      TextButton(onPressed: () => _historico(c), child: const Text('Histórico')),
                      Tooltip(
                        message: 'Passível de impulsionar',
                        child: Switch(
                          key: Key('flag-${c.id}'),
                          value: c.habilitada,
                          activeColor: GigColors.primary,
                          onChanged: (v) async {
                            final motivo = await _pedirTexto(
                              titulo: v ? 'Liberar Impulsionar para ${c.nome}' : 'Tirar Impulsionar de ${c.nome}',
                              rotulo: 'Motivo (opcional, só a equipe vê)',
                              obrigatorio: false,
                            );
                            if (motivo == null) return;
                            await _executar(
                              () => _store.definirFlag(c.id, v, motivo.isEmpty ? null : motivo),
                              v ? 'Liberado. A casa recebe um aviso no app.' : 'Desligado. Impulsos pagos continuam.',
                            );
                          },
                        ),
                      ),
                    ]),
                  );
                },
              ),
      ),
    ]);
  }

  Future<void> _historico(CasaImpulso casa) async {
    final itens = await _store.historico(casa.id);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: GigColors.scrim,
      builder: (dialogo) => AlertDialog(
        backgroundColor: GigColors.surface,
        title: Text('Histórico — ${casa.nome}', style: GigTypography.h2),
        content: SizedBox(
          width: 460,
          child: itens.isEmpty
              ? Text('A flag nunca foi alterada.', style: GigTypography.body)
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  for (final h in itens)
                    ListTile(
                      dense: true,
                      title: Text('${h.valorNovo ? 'Liberado' : 'Desligado'} em ${Formatar.dataHora(h.quando)}',
                          style: GigTypography.body),
                      subtitle: Text(
                          [if (h.alteradoPor != null) 'por ${h.alteradoPor}', if (h.motivo != null) h.motivo!].join(' · '),
                          style: GigTypography.small),
                    ),
                ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(dialogo).pop(), child: const Text('Fechar'))],
      ),
    );
  }

  // ------------------------------------------------------------------ configurações

  Widget _configuracoes() {
    return ListView(children: [
      Text('Pacotes (o preço é o cadastrado nas lojas)', style: GigTypography.h3),
      const SizedBox(height: GigSpacing.sm),
      for (final p in _store.produtos.value)
        _LinhaProduto(
          key: Key('produto-${p.id}'),
          produto: p,
          aoSalvar: (alcance, ativo) => _executar(
              () => _store.ajustarProduto(p.id, alcance: alcance, ativo: ativo), 'Pacote salvo.'),
        ),
      const SizedBox(height: GigSpacing.xl),
      Text('Parâmetros', style: GigTypography.h3),
      const SizedBox(height: GigSpacing.sm),
      for (final p in _store.parametros.value)
        _LinhaParametro(
          key: Key('parametro-${p.chave}'),
          parametro: p,
          aoSalvar: (valor) => _executar(() => _store.definirParametro(p.chave, valor), 'Parâmetro salvo.'),
        ),
    ]);
  }
}

class _LinhaProduto extends StatefulWidget {
  const _LinhaProduto({super.key, required this.produto, required this.aoSalvar});

  final ProdutoImpulso produto;
  final Future<void> Function(int? alcance, bool ativo) aoSalvar;

  @override
  State<_LinhaProduto> createState() => _LinhaProdutoState();
}

class _LinhaProdutoState extends State<_LinhaProduto> {
  late final _alcance = TextEditingController(text: widget.produto.alcance?.toString() ?? '');
  late bool _ativo = widget.produto.ativo;

  @override
  void dispose() {
    _alcance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.produto;
    final ehPush = p.codigo == 'PUSH_PROXIMOS';
    return ListTile(
      title: Text(p.nome, style: GigTypography.body),
      subtitle: Text('${p.produtoLojaId} · referência R\$ ${Formatar.numero(p.precoReferenciaCentavos / 100, casas: 2)}',
          style: GigTypography.small),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (ehPush)
          SizedBox(
            width: 110,
            child: TextField(
              controller: _alcance,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Alcance'),
            ),
          ),
        const SizedBox(width: GigSpacing.sm),
        Switch(value: _ativo, activeColor: GigColors.primary, onChanged: (v) => setState(() => _ativo = v)),
        TextButton(
          onPressed: () => widget.aoSalvar(ehPush ? int.tryParse(_alcance.text) : null, _ativo),
          child: const Text('Salvar'),
        ),
      ]),
    );
  }
}

class _LinhaParametro extends StatefulWidget {
  const _LinhaParametro({super.key, required this.parametro, required this.aoSalvar});

  final ParametroImpulso parametro;
  final Future<void> Function(int valor) aoSalvar;

  @override
  State<_LinhaParametro> createState() => _LinhaParametroState();
}

class _LinhaParametroState extends State<_LinhaParametro> {
  late final _valor = TextEditingController(text: '${widget.parametro.valor}');

  @override
  void dispose() {
    _valor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.parametro;
    return ListTile(
      title: Text(p.rotulo, style: GigTypography.body),
      subtitle: Text('${p.chave} · de ${p.minimo} a ${p.maximo}', style: GigTypography.small),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 90,
          child: TextField(
            controller: _valor,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        TextButton(
          onPressed: () {
            final v = int.tryParse(_valor.text);
            if (v != null) widget.aoSalvar(v);
          },
          child: const Text('Salvar'),
        ),
      ]),
    );
  }
}
