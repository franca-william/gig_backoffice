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
import '../../data/models/denuncia.dart';
import '../sugestoes/widgets.dart';
import 'denuncias_store.dart';

/// E31 (E3 do backoffice) — fila de denúncias: gravidade alta primeiro, depois o prazo (24 h alta / 3 dias úteis
/// demais), com etiquetas Atrasada / Vence hoje e paginação de 20.
class DenunciasPage extends StatefulWidget {
  const DenunciasPage({super.key});

  static const larguraMinimaTabela = 900.0;

  @override
  State<DenunciasPage> createState() => _DenunciasPageState();
}

class _DenunciasPageState extends State<DenunciasPage> {
  final _store = getIt<DenunciasStore>();
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
            return Wrap(spacing: GigSpacing.md, runSpacing: GigSpacing.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text('Denúncias', style: GigTypography.h1),
              if (c.altas > 0)
                Etiqueta(
                  key: const Key('denuncias-altas'),
                  texto: c.altas == 1 ? '1 grave' : '${c.altas} graves',
                  cor: GigColors.danger,
                ),
              if (c.atrasadas > 0)
                Etiqueta(
                  key: const Key('denuncias-atrasadas'),
                  texto: c.atrasadas == 1 ? '1 atrasada' : '${c.atrasadas} atrasadas',
                  cor: GigColors.danger,
                  preenchida: true,
                ),
            ]);
          }),
          const SizedBox(height: GigSpacing.xs),
          Text(
            'Gravidade alta (explícito, ódio, menor de idade) em até 24 h; as demais em até 3 dias úteis. Quem '
            'denunciou nunca aparece para quem foi denunciado.',
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

  Widget _chip({required Key key, required String rotulo, required bool selecionado, required VoidCallback aoTocar}) {
    return ChoiceChip(
      key: key,
      label: Text(rotulo),
      selected: selecionado,
      onSelected: (_) => aoTocar(),
      selectedColor: GigColors.primarySoft,
      labelStyle: GigTypography.chip.copyWith(color: selecionado ? GigColors.primary : GigColors.textSubtle),
      side: BorderSide(color: selecionado ? GigColors.primaryBorder : GigColors.border),
      showCheckmark: false,
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
          for (final s in FiltroDenuncia.values)
            _chip(
              key: Key('chip-denuncia-${s.api}'),
              rotulo: s.rotulo,
              selecionado: f.situacao == s,
              aoTocar: () => _store.aplicar(f.copyWith(situacao: s)),
            ),
          const SizedBox(width: GigSpacing.md),
          for (final g in GravidadeDenuncia.values)
            _chip(
              key: Key('chip-gravidade-${g.api}'),
              rotulo: 'Gravidade ${g.rotulo.toLowerCase()}',
              selecionado: f.gravidade == g,
              // Tocar de novo no chip escolhido tira o filtro.
              aoTocar: () => _store.aplicar(f.gravidade == g
                  ? f.copyWith(limparGravidade: true)
                  : f.copyWith(gravidade: g)),
            ),
          SizedBox(
            width: 260,
            child: TextField(
              key: const Key('filtro-busca-denuncia'),
              controller: _busca,
              onChanged: _aoDigitar,
              onSubmitted: (t) {
                _espera?.cancel();
                _store.aplicar(f.copyWith(busca: t));
              },
              decoration: const InputDecoration(
                hintText: 'Nome de quem foi denunciado',
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
        final fila = f.situacao == FiltroDenuncia.abertas && f.gravidade == null && f.busca.isEmpty;
        return Center(
          child: Text(fila ? 'Nenhuma denúncia esperando.' : 'Nenhuma denúncia com esses filtros.',
              style: GigTypography.h2),
        );
      }
      final agora = getIt<Relogio>()();
      return LayoutBuilder(builder: (context, constraints) {
        final largura =
            constraints.maxWidth < DenunciasPage.larguraMinimaTabela ? DenunciasPage.larguraMinimaTabela : constraints.maxWidth;
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
                    denuncia: pagina.itens[i],
                    agora: agora,
                    aoTocar: () => context.go(Rotas.denuncia(pagina.itens[i].id)),
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
          Text('${p.total} denúncias · página ${p.pagina + 1} de ${p.totalPaginas}', style: GigTypography.small),
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

const _wRecebida = 100.0;
const _wPrazo = 160.0;
const _wGravidade = 100.0;
const _wPerfil = 100.0;
const _wDenunciado = 190.0;
const _wSituacao = 140.0;

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
        c('Recebida', _wRecebida),
        c('Prazo', _wPrazo),
        c('Gravidade', _wGravidade),
        c('Tipo'),
        c('Denunciado', _wDenunciado),
        c('Perfil', _wPerfil),
        c('Situação', _wSituacao),
      ]),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.denuncia, required this.agora, required this.aoTocar});

  final DenunciaResumo denuncia;
  final DateTime agora;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final d = denuncia;
    final prazo = prazoDaDenuncia(d.situacao, d.prazoAnalise, agora);
    return InkWell(
      key: Key('linha-denuncia-${d.id}'),
      onTap: aoTocar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: GigSpacing.md, vertical: GigSpacing.md),
        child: Row(children: [
          SizedBox(width: _wRecebida, child: Text(Formatar.data(d.criadaEm), style: GigTypography.body)),
          SizedBox(
            width: _wPrazo,
            child: Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              if (d.situacao.estaAberta) Text(Formatar.dataHora(d.prazoAnalise), style: GigTypography.small),
              EtiquetaPrazo(prazo: prazo),
            ]),
          ),
          SizedBox(
            width: _wGravidade,
            child: Align(alignment: Alignment.centerLeft, child: EtiquetaGravidade(gravidade: d.gravidade)),
          ),
          Expanded(
            child: Text(d.tipoDescricao, maxLines: 2, overflow: TextOverflow.ellipsis, style: GigTypography.body),
          ),
          SizedBox(
            width: _wDenunciado,
            child: Text(d.denunciado, overflow: TextOverflow.ellipsis, style: GigTypography.body),
          ),
          SizedBox(width: _wPerfil, child: Text(rotuloDoPerfil(d.perfil), style: GigTypography.body)),
          SizedBox(
            width: _wSituacao,
            child: Align(alignment: Alignment.centerLeft, child: EtiquetaDenuncia(situacao: d.situacao, acao: d.acao)),
          ),
        ]),
      ),
    );
  }
}

/// Gravidade em pílula: alta vermelha, média âmbar, baixa cinza.
class EtiquetaGravidade extends StatelessWidget {
  const EtiquetaGravidade({super.key, required this.gravidade});

  final GravidadeDenuncia gravidade;

  @override
  Widget build(BuildContext context) {
    final cor = switch (gravidade) {
      GravidadeDenuncia.alta => GigColors.danger,
      GravidadeDenuncia.media => GigColors.primary,
      GravidadeDenuncia.baixa => GigColors.textSubtle,
    };
    return Etiqueta(texto: gravidade.rotulo, cor: cor, preenchida: gravidade == GravidadeDenuncia.alta);
  }
}

/// Situação (e a ação, quando procedente) em pílula.
class EtiquetaDenuncia extends StatelessWidget {
  const EtiquetaDenuncia({super.key, required this.situacao, this.acao});

  final SituacaoDenuncia situacao;
  final AcaoDenuncia? acao;

  @override
  Widget build(BuildContext context) {
    if (situacao == SituacaoDenuncia.procedente && acao != null && acao != AcaoDenuncia.nenhuma) {
      return Etiqueta(texto: acao!.rotulo, cor: GigColors.danger);
    }
    final cor = switch (situacao) {
      SituacaoDenuncia.aberta || SituacaoDenuncia.emAnalise => GigColors.primary,
      SituacaoDenuncia.procedente => GigColors.danger,
      SituacaoDenuncia.improcedente => GigColors.textSubtle,
    };
    return Etiqueta(texto: situacao.rotulo, cor: cor);
  }
}
