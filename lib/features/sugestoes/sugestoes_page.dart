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
import '../../data/models/models.dart';
import 'sugestoes_store.dart';
import 'widgets.dart';

/// Lista de sugestões (E28) para a equipe: filtros, tabela com prazo e paginação de 20 em 20.
class SugestoesPage extends StatefulWidget {
  const SugestoesPage({super.key});

  static const larguraMinimaTabela = 900.0;

  @override
  State<SugestoesPage> createState() => _SugestoesPageState();
}

class _SugestoesPageState extends State<SugestoesPage> {
  final _store = getIt<SugestoesStore>();
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
              Text('Sugestões', style: GigTypography.h1),
              const SizedBox(width: GigSpacing.md),
              if (c.atrasadas > 0)
                Etiqueta(
                  texto: c.atrasadas == 1 ? '1 atrasada' : '${c.atrasadas} atrasadas',
                  cor: GigColors.danger,
                ),
            ]);
          }),
          const SizedBox(height: GigSpacing.xs),
          Text('Responda em até 2 dias. A pessoa lê a resposta no app, assinada como Equipe GiG.',
              style: GigTypography.paragraph),
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
          for (final s in FiltroSituacao.values)
            ChoiceChip(
              key: Key('chip-${s.api}'),
              label: Text(s.rotulo),
              selected: f.situacao == s,
              onSelected: (_) => _store.aplicar(f.copyWith(situacao: s)),
              selectedColor: GigColors.primarySoft,
              labelStyle: GigTypography.chip.copyWith(color: f.situacao == s ? GigColors.primary : GigColors.textSubtle),
              side: BorderSide(color: f.situacao == s ? GigColors.primaryBorder : GigColors.border),
              showCheckmark: false,
            ),
          const SizedBox(width: GigSpacing.sm),
          _Selecao<PerfilSugestao>(
            key: const Key('filtro-perfil'),
            dica: 'Perfil: todos',
            valor: f.perfil,
            opcoes: PerfilSugestao.values,
            rotulo: (p) => p.rotulo,
            aoMudar: (p) => _store.aplicar(f.copyWith(perfil: p, limparPerfil: p == null)),
          ),
          _Selecao<TipoSugestao>(
            key: const Key('filtro-tipo'),
            dica: 'Tipo: todos',
            valor: f.tipo,
            opcoes: TipoSugestao.values,
            rotulo: (t) => t.rotulo,
            aoMudar: (t) => _store.aplicar(f.copyWith(tipo: t, limparTipo: t == null)),
          ),
          SizedBox(
            width: 260,
            child: TextField(
              key: const Key('filtro-busca'),
              controller: _busca,
              onChanged: _aoDigitar,
              onSubmitted: (t) {
                _espera?.cancel();
                _store.aplicar(f.copyWith(busca: t));
              },
              decoration: const InputDecoration(
                hintText: 'Buscar no texto',
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
        final semResposta = _store.filtro.value.situacao == FiltroSituacao.semResposta;
        final semOutrosFiltros =
            _store.filtro.value.perfil == null && _store.filtro.value.tipo == null && _store.filtro.value.busca.isEmpty;
        return Center(
          child: Text(
            semResposta && semOutrosFiltros ? 'Tudo respondido! 🎉' : 'Nenhuma sugestão com esses filtros.',
            style: GigTypography.h2,
          ),
        );
      }
      final agora = getIt<Relogio>()();
      return LayoutBuilder(builder: (context, constraints) {
        final largura = constraints.maxWidth < SugestoesPage.larguraMinimaTabela
            ? SugestoesPage.larguraMinimaTabela
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
                    sugestao: pagina.itens[i],
                    agora: agora,
                    aoTocar: () => context.go(Rotas.sugestao(pagina.itens[i].id)),
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
          Text('${p.total} sugestões · página ${p.pagina + 1} de ${p.totalPaginas}', style: GigTypography.small),
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

// Larguras das colunas (o texto ocupa o resto).
const _wEnvio = 100.0;
const _wPrazo = 150.0;
const _wNome = 160.0;
const _wPerfil = 90.0;
const _wTipo = 90.0;
const _wSituacao = 110.0;

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
        c('Quem enviou', _wNome),
        c('Perfil', _wPerfil),
        c('Tipo', _wTipo),
        c('Sugestão'),
        c('Situação', _wSituacao),
      ]),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.sugestao, required this.agora, required this.aoTocar});

  final SugestaoResumo sugestao;
  final DateTime agora;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final s = sugestao;
    final prazo = prazoDe(s.situacao, s.prazoResposta, agora);
    return InkWell(
      key: Key('linha-${s.id}'),
      onTap: aoTocar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: GigSpacing.md, vertical: GigSpacing.md),
        child: Row(children: [
          SizedBox(width: _wEnvio, child: Text(Formatar.data(s.enviadaEm), style: GigTypography.body)),
          SizedBox(
            width: _wPrazo,
            child: Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(Formatar.data(s.prazoResposta), style: GigTypography.small),
              EtiquetaPrazo(prazo: prazo),
            ]),
          ),
          SizedBox(
            width: _wNome,
            child: Text(
              s.nomeExibido,
              overflow: TextOverflow.ellipsis,
              style: s.nome == null ? GigTypography.bodyMuted.copyWith(fontStyle: FontStyle.italic) : GigTypography.body,
            ),
          ),
          SizedBox(width: _wPerfil, child: Text(s.perfil?.rotulo ?? '—', style: GigTypography.body)),
          SizedBox(width: _wTipo, child: Text(s.tipo?.rotulo ?? '—', style: GigTypography.body)),
          Expanded(
            child: Text(s.inicioDoTexto,
                maxLines: 2, overflow: TextOverflow.ellipsis, style: GigTypography.body.copyWith(color: GigColors.textSubtle)),
          ),
          const SizedBox(width: GigSpacing.md),
          SizedBox(width: _wSituacao - GigSpacing.md, child: Align(alignment: Alignment.centerLeft, child: EtiquetaSituacao(situacao: s.situacao))),
        ]),
      ),
    );
  }
}

/// Select com "todos" (valor nulo).
class _Selecao<T> extends StatelessWidget {
  const _Selecao({
    super.key,
    required this.dica,
    required this.valor,
    required this.opcoes,
    required this.rotulo,
    required this.aoMudar,
  });

  final String dica;
  final T? valor;
  final List<T> opcoes;
  final String Function(T) rotulo;
  final ValueChanged<T?> aoMudar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: GigSpacing.md),
      decoration: BoxDecoration(
        color: GigColors.surface,
        borderRadius: GigRadius.button,
        border: Border.all(color: GigColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          value: valor,
          hint: Text(dica, style: GigTypography.body),
          dropdownColor: GigColors.surfaceHigh,
          style: GigTypography.body,
          items: [
            DropdownMenuItem<T?>(value: null, child: Text(dica)),
            for (final o in opcoes) DropdownMenuItem<T?>(value: o, child: Text(rotulo(o))),
          ],
          onChanged: aoMudar,
        ),
      ),
    );
  }
}
