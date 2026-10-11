import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/di.dart';
import '../../app/rotas.dart';
import '../../app/sessao_store.dart';
import '../../core/formatar.dart';
import '../../core/theme/theme.dart';
import '../../data/models/dashboard.dart';
import 'abas/atencao_aba.dart';
import 'abas/crescimento_aba.dart';
import 'abas/curtidores_aba.dart';
import 'abas/marketplace_aba.dart';
import 'abas/qualidade_aba.dart';
import 'dashboard_store.dart';
import 'widgets/blocos.dart';

export 'widgets/cartao.dart' show DashboardCartao, CorCartao;

/// Dashboard em 5 abas (E1). A aba e o período ficam na URL: `/dashboard?aba=marketplace&periodo=30`;
/// recarregar ou compartilhar o link abre no mesmo lugar. Padrão: Pontos de atenção, 30 dias.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.aba = AbaDashboard.atencao, this.periodo = PeriodoDashboard.padrao});

  final AbaDashboard aba;
  final int periodo;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  final _store = getIt<DashboardStore>();
  late final TabController _abas =
      TabController(length: AbaDashboard.values.length, vsync: this, initialIndex: widget.aba.index);

  @override
  void initState() {
    super.initState();
    _abrirDepoisDoQuadro();
  }

  /// Mexe no store só depois do quadro: initState/didUpdateWidget rodam durante o build, e o menu lateral observa
  /// o mesmo store (contador).
  void _abrirDepoisDoQuadro() {
    final aba = widget.aba;
    final periodo = widget.periodo;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _store.abrir(aba, periodo);
    });
  }

  @override
  void didUpdateWidget(covariant DashboardPage antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.aba != widget.aba || antigo.periodo != widget.periodo) {
      if (_abas.index != widget.aba.index) _abas.animateTo(widget.aba.index);
      _abrirDepoisDoQuadro();
    }
  }

  @override
  void dispose() {
    _abas.dispose();
    super.dispose();
  }

  void _ir({AbaDashboard? aba, int? periodo}) =>
      context.go(Rotas.dashboardCom(aba: (aba ?? widget.aba).url, periodo: periodo ?? widget.periodo));

  @override
  Widget build(BuildContext context) {
    final sessao = getIt<SessaoStore>();
    return ListView(
      padding: const EdgeInsets.all(GigSpacing.xxxl),
      children: [
        Observer(builder: (_) {
          final nome = sessao.membro.value?.primeiroNome ?? '';
          return Text.rich(
            TextSpan(text: 'Olá, ', children: [
              TextSpan(text: nome, style: const TextStyle(color: GigColors.primary)),
            ]),
            style: GigTypography.h1,
          );
        }),
        const SizedBox(height: GigSpacing.xs),
        Text('Os principais números do GiG, aba por aba.', style: GigTypography.paragraph),
        const SizedBox(height: GigSpacing.xl),
        Observer(builder: (_) {
          final contador = _store.contador.value;
          return TabBar(
            controller: _abas,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: GigColors.primary,
            labelColor: GigColors.primary,
            unselectedLabelColor: GigColors.textSubtle,
            labelStyle: GigTypography.buttonMedium,
            unselectedLabelStyle: GigTypography.buttonMedium,
            dividerColor: GigColors.border,
            onTap: (i) => _ir(aba: AbaDashboard.values[i]),
            tabs: [
              for (final a in AbaDashboard.values)
                Tab(
                  key: Key('aba-${a.url}'),
                  text: a == AbaDashboard.atencao && contador > 0 ? '${a.rotulo} ($contador)' : a.rotulo,
                ),
            ],
          );
        }),
        const SizedBox(height: GigSpacing.lg),
        _barraDeFerramentas(),
        const SizedBox(height: GigSpacing.xl),
        Observer(builder: (_) => _conteudo(widget.aba, _store.estado(widget.aba))),
      ],
    );
  }

  Widget _barraDeFerramentas() {
    return Observer(builder: (_) {
      final aba = widget.aba;
      final estado = _store.estado(aba);
      final geradoEm = estado.geradoEm;
      return Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: GigSpacing.lg,
        runSpacing: GigSpacing.sm,
        children: [
          SeletorDePeriodo(
            periodo: widget.periodo,
            habilitado: aba.temPeriodo,
            aoEscolher: (p) => _ir(periodo: p),
          ),
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (geradoEm != null)
              Text('Atualizado às ${Formatar.hora(geradoEm)}',
                  key: const Key('atualizado-as'), style: GigTypography.small),
            const SizedBox(width: GigSpacing.md),
            OutlinedButton.icon(
              key: const Key('dashboard-atualizar'),
              // O tema usa largura infinita (botões de formulário); aqui o botão fica do tamanho do texto.
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, GigSizes.buttonMedium)),
              onPressed: estado.carregando ? null : _store.atualizar,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Atualizar'),
            ),
          ]),
        ],
      );
    });
  }

  Widget _conteudo(AbaDashboard aba, EstadoAba estado) {
    final dado = estado.dado;
    if (dado == null) {
      if (estado.erro != null) return ErroDaAba(aoTentar: _store.tentarDeNovo);
      return const EsqueletoDaAba();
    }
    final Widget corpo = switch (dado) {
      final Atencao d => AtencaoAba(dados: d),
      final Marketplace d => MarketplaceAba(dados: d),
      final Crescimento d => CrescimentoAba(dados: d),
      final Curtidores d => CurtidoresAba(dados: d),
      final Qualidade d => QualidadeAba(dados: d),
      _ => const SizedBox.shrink(),
    };
    // Recarregando (outro período ou Atualizar): mostra os números antigos esmaecidos.
    return AnimatedOpacity(
      key: Key('conteudo-${aba.url}'),
      opacity: estado.carregando ? 0.5 : 1,
      duration: const Duration(milliseconds: 150),
      child: corpo,
    );
  }
}

/// 7 dias · 30 dias · 90 dias. Desabilitado na aba Pontos de atenção (sempre "agora").
class SeletorDePeriodo extends StatelessWidget {
  const SeletorDePeriodo({super.key, required this.periodo, required this.habilitado, required this.aoEscolher});

  final int periodo;
  final bool habilitado;
  final ValueChanged<int> aoEscolher;

  @override
  Widget build(BuildContext context) {
    final seletor = Wrap(spacing: GigSpacing.sm, children: [
      for (final p in PeriodoDashboard.opcoes)
        ChoiceChip(
          key: Key('periodo-$p'),
          label: Text('$p dias'),
          selected: habilitado && p == periodo,
          onSelected: habilitado ? (_) => aoEscolher(p) : null,
          selectedColor: GigColors.primarySoft,
          labelStyle: GigTypography.chip.copyWith(
              color: !habilitado
                  ? GigColors.textDisabled
                  : (p == periodo ? GigColors.primary : GigColors.textSubtle)),
          side: BorderSide(color: habilitado && p == periodo ? GigColors.primaryBorder : GigColors.border),
          showCheckmark: false,
        ),
    ]);
    if (habilitado) return seletor;
    return Tooltip(message: 'Esta aba mostra a situação atual', child: seletor);
  }
}
