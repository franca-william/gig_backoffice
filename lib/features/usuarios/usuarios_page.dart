import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/di.dart';
import '../../app/rotas.dart';
import '../../core/formatar.dart';
import '../../core/theme/theme.dart';
import '../../data/models/models.dart';
import '../../data/models/usuario.dart';
import '../sugestoes/widgets.dart';
import 'usuarios_store.dart';

/// E5 (backoffice) — consulta de usuários: busca por nome ou e-mail, filtro por perfil e paginação de 20.
class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  static const larguraMinimaTabela = 900.0;

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  final _store = getIt<UsuariosStore>();
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
    _espera = Timer(const Duration(milliseconds: 400),
        () => _store.aplicar(_store.filtro.value.copyWith(busca: texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(GigSpacing.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Usuários', style: GigTypography.h1),
          const SizedBox(height: GigSpacing.xs),
          Text('Consulta de contas: busque por nome ou e-mail. Somente leitura.',
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
          SizedBox(
            width: 300,
            child: TextField(
              key: const Key('filtro-busca-usuario'),
              controller: _busca,
              onChanged: _aoDigitar,
              onSubmitted: (t) {
                _espera?.cancel();
                _store.aplicar(f.copyWith(busca: t));
              },
              decoration: const InputDecoration(
                hintText: 'Nome ou e-mail',
                prefixIcon: Icon(LucideIcons.search, size: 16),
              ),
            ),
          ),
          for (final p in PerfilSugestao.values)
            ChoiceChip(
              key: Key('chip-perfil-${p.api}'),
              label: Text(p.rotulo),
              selected: f.perfil == p,
              // Tocar de novo no chip escolhido tira o filtro.
              onSelected: (_) => _store.aplicar(f.perfil == p ? f.copyWith(limparPerfil: true) : f.copyWith(perfil: p)),
              selectedColor: GigColors.primarySoft,
              labelStyle: GigTypography.chip.copyWith(color: f.perfil == p ? GigColors.primary : GigColors.textSubtle),
              side: BorderSide(color: f.perfil == p ? GigColors.primaryBorder : GigColors.border),
              showCheckmark: false,
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
        return Center(child: Text('Nenhum usuário encontrado.', style: GigTypography.h2));
      }
      return LayoutBuilder(builder: (context, constraints) {
        final largura = constraints.maxWidth < UsuariosPage.larguraMinimaTabela
            ? UsuariosPage.larguraMinimaTabela
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
                    usuario: pagina.itens[i],
                    aoTocar: () => context.go(Rotas.usuario(pagina.itens[i].id)),
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
          Text('${p.total} usuários · página ${p.pagina + 1} de ${p.totalPaginas}', style: GigTypography.small),
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

const _wPerfis = 190.0;
const _wLocal = 170.0;
const _wSituacao = 120.0;
const _wCadastro = 110.0;

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
        c('Nome'),
        c('E-mail'),
        c('Perfis', _wPerfis),
        c('Cidade', _wLocal),
        c('Situação', _wSituacao),
        c('Cadastro', _wCadastro),
      ]),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.usuario, required this.aoTocar});

  final UsuarioResumo usuario;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final u = usuario;
    return InkWell(
      key: Key('linha-usuario-${u.id}'),
      onTap: aoTocar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: GigSpacing.md, vertical: GigSpacing.md),
        child: Row(children: [
          Expanded(child: Text(u.nome, overflow: TextOverflow.ellipsis, style: GigTypography.body)),
          Expanded(child: Text(u.login, overflow: TextOverflow.ellipsis, style: GigTypography.body)),
          SizedBox(
            width: _wPerfis,
            child: Text(u.perfis.map((p) => p.rotulo).join(', '), style: GigTypography.body),
          ),
          SizedBox(
            width: _wLocal,
            child: Text(u.local.isEmpty ? '—' : u.local, overflow: TextOverflow.ellipsis, style: GigTypography.body),
          ),
          SizedBox(
            width: _wSituacao,
            child: Align(alignment: Alignment.centerLeft, child: EtiquetaUsuario(situacao: u.situacao)),
          ),
          SizedBox(width: _wCadastro, child: Text(Formatar.data(u.criadoEm), style: GigTypography.body)),
        ]),
      ),
    );
  }
}

/// Situação da conta em pílula: ativo verde, suspenso âmbar, banido vermelho.
class EtiquetaUsuario extends StatelessWidget {
  const EtiquetaUsuario({super.key, required this.situacao});

  final SituacaoUsuario situacao;

  @override
  Widget build(BuildContext context) {
    final cor = switch (situacao) {
      SituacaoUsuario.ativo => GigColors.success,
      SituacaoUsuario.suspenso => GigColors.primary,
      SituacaoUsuario.banido => GigColors.danger,
    };
    return Etiqueta(texto: situacao.rotulo, cor: cor);
  }
}
