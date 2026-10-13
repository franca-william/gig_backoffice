import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/di.dart';
import '../../app/rotas.dart';
import '../../core/formatar.dart';
import '../../core/theme/theme.dart';
import '../../data/mock/mock_repositories.dart';
import '../../data/models/verificacao.dart';
import '../sugestoes/widgets.dart';
import 'verificacoes_store.dart';

/// E30 — fila de verificações dos estabelecimentos: filtros, tabela com prazo de 3 dias úteis e paginação de 20.
class VerificacoesPage extends StatefulWidget {
  const VerificacoesPage({super.key});

  static const larguraMinimaTabela = 900.0;

  @override
  State<VerificacoesPage> createState() => _VerificacoesPageState();
}

class _VerificacoesPageState extends State<VerificacoesPage> {
  final _store = getIt<VerificacoesStore>();
  final _busca = TextEditingController();
  Timer? _espera;

  @override
  void initState() {
    super.initState();
    _busca.text = _store.filtro.value.busca;
    _store.carregar();
  }

  @override
  void dispose() {
    _espera?.cancel();
    _busca.dispose();
    super.dispose();
  }

  void _aoDigitar(String texto) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 400), () => _store.aplicar(_store.filtro.value.copyWith(busca: texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(GigSpacing.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Observer(builder: (_) {
            final c = _store.contagem.value;
            return Row(children: [
              Text('Verificações', style: GigTypography.h1),
              const SizedBox(width: GigSpacing.md),
              if (c.atrasadas > 0)
                Etiqueta(
                  key: const Key('verificacoes-atrasadas'),
                  texto: c.atrasadas == 1 ? '1 atrasada' : '${c.atrasadas} atrasadas',
                  cor: GigColors.danger,
                ),
            ]);
          }),
          const SizedBox(height: GigSpacing.xs),
          Text(
            'Analise em até 3 dias úteis. A casa recebe uma notificação no app a cada devolutiva (aprovar ou pedir '
            'ajuste).',
            style: GigTypography.paragraph,
          ),
          const SizedBox(height: GigSpacing.xl),
          _filtros(),
          const SizedBox(height: GigSpacing.lg),
          Expanded(child: _tabela()),
          _paginacao(),
        ],
      ),
    );
  }

  Widget _filtros() {
    return Observer(builder: (_) {
      final f = _store.filtro.value;
      return Wrap(
        spacing: GigSpacing.sm,
        runSpacing: GigSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final s in FiltroVerificacao.values)
            ChoiceChip(
              key: Key('chip-verificacao-${s.api}'),
              label: Text(s.rotulo),
              selected: f.situacao == s,
              onSelected: (_) => _store.aplicar(f.copyWith(situacao: s)),
              selectedColor: GigColors.primarySoft,
              labelStyle: GigTypography.chip.copyWith(color: f.situacao == s ? GigColors.primary : GigColors.textSubtle),
              side: BorderSide(color: f.situacao == s ? GigColors.primaryBorder : GigColors.border),
              showCheckmark: false,
            ),
          const SizedBox(width: GigSpacing.sm),
          Container(
            key: const Key('filtro-tipo-verificacao'),
            padding: const EdgeInsets.symmetric(horizontal: GigSpacing.md),
            decoration: BoxDecoration(
              color: GigColors.surface,
              borderRadius: GigRadius.button,
              border: Border.all(color: GigColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TipoVerificacao?>(
                value: f.tipo,
                hint: Text('Tipo: todos', style: GigTypography.body),
                dropdownColor: GigColors.surfaceHigh,
                style: GigTypography.body,
                items: [
                  const DropdownMenuItem<TipoVerificacao?>(value: null, child: Text('Tipo: todos')),
                  for (final t in TipoVerificacao.values) DropdownMenuItem<TipoVerificacao?>(value: t, child: Text(t.rotulo)),
                ],
                onChanged: (t) => _store.aplicar(f.copyWith(tipo: t, limparTipo: t == null)),
              ),
            ),
          ),
          SizedBox(
            width: 260,
            child: TextField(
              key: const Key('filtro-busca-verificacao'),
              controller: _busca,
              onChanged: _aoDigitar,
              onSubmitted: (t) {
                _espera?.cancel();
                _store.aplicar(f.copyWith(busca: t));
              },
              decoration: const InputDecoration(
                hintText: 'Nome da casa ou CNPJ',
                prefixIcon: Icon(LucideIcons.search, size: 16),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _tabela() {
    return Observer(builder: (_) {
      final pagina = _store.pagina.value;
      final carregando = _store.carregando.value;
      final erro = _store.erro.value;
      if (erro != null) {
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(erro, style: GigTypography.body),
            TextButton(onPressed: _store.carregar, child: const Text('Tentar de novo')),
          ]),
        );
      }
      if (pagina.itens.isEmpty) {
        if (carregando) return const Center(child: CircularProgressIndicator());
        final f = _store.filtro.value;
        final fila = f.situacao == FiltroVerificacao.emAnalise && f.tipo == null && f.busca.isEmpty;
        return Center(
          child: Text(fila ? 'Nenhuma verificação esperando.' : 'Nenhuma verificação com esses filtros.',
              style: GigTypography.h2),
        );
      }
      final agora = getIt<Relogio>()();
      return LayoutBuilder(builder: (context, constraints) {
        final largura = constraints.maxWidth < VerificacoesPage.larguraMinimaTabela
            ? VerificacoesPage.larguraMinimaTabela
            : constraints.maxWidth;
        final tabela = SizedBox(
          width: largura,
          child: Column(children: [
            const _Cabecalho(),
            Expanded(
              child: Stack(children: [
                ListView.separated(
                  itemCount: pagina.itens.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) => _Linha(
                    verificacao: pagina.itens[i],
                    agora: agora,
                    aoTocar: () => context.go(Rotas.verificacao(pagina.itens[i].id)),
                  ),
                ),
                if (carregando) const LinearProgressIndicator(minHeight: 2),
              ]),
            ),
          ]),
        );
        return largura > constraints.maxWidth
            ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: tabela)
            : tabela;
      });
    });
  }

  Widget _paginacao() {
    return Observer(builder: (_) {
      final p = _store.pagina.value;
      if (p.totalPaginas <= 1) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: GigSpacing.md),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text('${p.total} verificações · página ${p.pagina + 1} de ${p.totalPaginas}', style: GigTypography.small),
          IconButton(
            tooltip: 'Página anterior',
            onPressed: p.pagina > 0 ? () => _store.carregar(numeroPagina: p.pagina - 1) : null,
            icon: const Icon(LucideIcons.chevronLeft),
          ),
          IconButton(
            tooltip: 'Próxima página',
            onPressed: p.pagina + 1 < p.totalPaginas ? () => _store.carregar(numeroPagina: p.pagina + 1) : null,
            icon: const Icon(LucideIcons.chevronRight),
          ),
        ]),
      );
    });
  }
}

const _wEnvio = 100.0;
const _wPrazo = 150.0;
const _wCidade = 130.0;
const _wCnpj = 170.0;
const _wTipo = 150.0;
const _wSituacao = 130.0;

class _Cabecalho extends StatelessWidget {
  const _Cabecalho();

  @override
  Widget build(BuildContext context) {
    Widget c(String t, [double? w]) {
      final texto = Text(t.toUpperCase(), style: GigTypography.fieldLabel);
      return w == null ? Expanded(child: texto) : SizedBox(width: w, child: texto);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: GigSpacing.md, vertical: GigSpacing.md),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: GigColors.border))),
      child: Row(children: [
        c('Envio', _wEnvio),
        c('Prazo', _wPrazo),
        c('Casa'),
        c('Cidade', _wCidade),
        c('CNPJ', _wCnpj),
        c('Tipo', _wTipo),
        c('Situação', _wSituacao),
      ]),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.verificacao, required this.agora, required this.aoTocar});

  final VerificacaoResumo verificacao;
  final DateTime agora;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final v = verificacao;
    final prazo = prazoDaVerificacao(v.situacao, v.prazoAnalise, agora);
    return InkWell(
      key: Key('linha-verificacao-${v.id}'),
      onTap: aoTocar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: GigSpacing.md, vertical: GigSpacing.md),
        child: Row(children: [
          SizedBox(
            width: _wEnvio,
            child: Text(v.enviadaEm == null ? '—' : Formatar.data(v.enviadaEm!), style: GigTypography.body),
          ),
          SizedBox(
            width: _wPrazo,
            child: Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              if (v.prazoAnalise != null) Text(Formatar.data(v.prazoAnalise!), style: GigTypography.small),
              EtiquetaPrazo(prazo: prazo),
            ]),
          ),
          Expanded(child: Text(v.casa, overflow: TextOverflow.ellipsis, style: GigTypography.body)),
          SizedBox(width: _wCidade, child: Text(v.cidadeUf.isEmpty ? '—' : v.cidadeUf, style: GigTypography.body)),
          SizedBox(width: _wCnpj, child: Text(formatarCnpj(v.cnpj), style: GigTypography.body)),
          SizedBox(
            width: _wTipo,
            child: Align(
              alignment: Alignment.centerLeft,
              child: v.tipo == TipoVerificacao.semCnpj
                  ? const Etiqueta(texto: 'Sem CNPJ — contato', cor: GigColors.info)
                  : Text('Documentos', style: GigTypography.body),
            ),
          ),
          SizedBox(
            width: _wSituacao,
            child: Align(alignment: Alignment.centerLeft, child: EtiquetaVerificacao(situacao: v.situacao)),
          ),
        ]),
      ),
    );
  }
}

/// Situação da verificação em pílula colorida.
class EtiquetaVerificacao extends StatelessWidget {
  const EtiquetaVerificacao({super.key, required this.situacao});

  final SituacaoVerificacao situacao;

  @override
  Widget build(BuildContext context) {
    final cor = switch (situacao) {
      SituacaoVerificacao.emAnalise => GigColors.primary,
      SituacaoVerificacao.aprovada => GigColors.success,
      SituacaoVerificacao.reprovada => GigColors.danger,
      SituacaoVerificacao.substituida || SituacaoVerificacao.rascunho => GigColors.textSubtle,
    };
    return Etiqueta(texto: situacao.rotulo, cor: cor);
  }
}
