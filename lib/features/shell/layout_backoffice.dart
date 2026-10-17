import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/di.dart';
import '../../app/rotas.dart';
import '../../app/sessao_store.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/gig_logo.dart';
import '../dashboard/dashboard_store.dart';
import '../denuncias/denuncias_store.dart';
import '../sugestoes/sugestoes_store.dart';
import '../impulsos/impulsos_store.dart';
import '../usuarios/usuarios_store.dart';
import '../verificacoes/verificacoes_store.dart';

/// Menu lateral fixo (240 px) a partir de 1024 px de largura; abaixo disso vira gaveta.
/// Conteúdo com largura máxima de 1200 px.
class LayoutBackoffice extends StatefulWidget {
  const LayoutBackoffice({super.key, required this.local, required this.child});

  static const larguraMenu = 240.0;
  static const larguraMinimaMenuFixo = 1024.0;
  static const larguraMaximaConteudo = 1200.0;

  final String local;
  final Widget child;

  @override
  State<LayoutBackoffice> createState() => _LayoutBackofficeState();
}

class _LayoutBackofficeState extends State<LayoutBackoffice> {
  @override
  void initState() {
    super.initState();
    getIt<SugestoesStore>().atualizarContagem();
    getIt<VerificacoesStore>().atualizarContagem();
    getIt<DenunciasStore>().atualizarContagem();
    getIt<ImpulsosStore>().atualizarContagem();
    // Depois do quadro: o store é observado pelo menu e pelo dashboard que estão sendo montados agora.
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => getIt<DashboardStore>().atualizarContador());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final fixo =
          constraints.maxWidth >= LayoutBackoffice.larguraMinimaMenuFixo;
      final conteudo = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              maxWidth: LayoutBackoffice.larguraMaximaConteudo),
          child: widget.child,
        ),
      );
      if (fixo) {
        return Scaffold(
          body: Row(children: [
            SizedBox(
                width: LayoutBackoffice.larguraMenu,
                child: MenuLateral(local: widget.local)),
            const VerticalDivider(width: 1),
            Expanded(child: conteudo),
          ]),
        );
      }
      return Scaffold(
        appBar: AppBar(
          backgroundColor: GigColors.surface,
          title: const Align(
              alignment: Alignment.centerLeft,
              child: GigPinSymbol(largura: 28)),
        ),
        drawer: Drawer(
          width: LayoutBackoffice.larguraMenu,
          backgroundColor: GigColors.surface,
          child: MenuLateral(
              local: widget.local,
              aoNavegar: () => Navigator.of(context).maybePop()),
        ),
        body: conteudo,
      );
    });
  }
}

class MenuLateral extends StatelessWidget {
  const MenuLateral({super.key, required this.local, this.aoNavegar});

  final String local;
  final VoidCallback? aoNavegar;

  @override
  Widget build(BuildContext context) {
    final sessao = getIt<SessaoStore>();
    final sugestoes = getIt<SugestoesStore>();
    final dashboard = getIt<DashboardStore>();
    final verificacoes = getIt<VerificacoesStore>();
    final denuncias = getIt<DenunciasStore>();
    void ir(String rota) {
      aoNavegar?.call();
      context.go(rota);
    }

    return ColoredBox(
      color: GigColors.surface,
      child: SafeArea(
        // Rolável: em janela baixa (ex.: DevTools aberto) os últimos itens não podem ficar cortados.
        child: LayoutBuilder(
          builder: (context, restricoes) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: restricoes.maxHeight),
              child: IntrinsicHeight(
                child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  GigSpacing.xl, GigSpacing.xxl, GigSpacing.xl, GigSpacing.xxl),
              // Só o símbolo da marca: sem o nome "GiG" e sem o texto "Backoffice".
              child: const Align(
                  alignment: Alignment.centerLeft,
                  child: GigPinSymbol(largura: 40)),
            ),
            Observer(builder: (_) {
              final n = dashboard.contador.value;
              return _ItemMenu(
                key: const Key('menu-dashboard'),
                icone: LucideIcons.layoutDashboard,
                rotulo: n > 0 ? 'Dashboard ($n)' : 'Dashboard',
                ativo: local.startsWith(Rotas.dashboard),
                aoTocar: () => ir(Rotas.dashboard),
              );
            }),
            Observer(builder: (_) {
              final n = sugestoes.contagem.value.semResposta;
              return _ItemMenu(
                key: const Key('menu-sugestoes'),
                icone: LucideIcons.messageSquare,
                rotulo: n > 0 ? 'Sugestões ($n)' : 'Sugestões',
                ativo: local.startsWith(Rotas.sugestoes),
                aoTocar: () => ir(Rotas.sugestoes),
              );
            }),
            Observer(builder: (_) {
              final n = verificacoes.contagem.value.emAnalise;
              return _ItemMenu(
                key: const Key('menu-verificacoes'),
                icone: LucideIcons.shieldCheck,
                rotulo: n > 0 ? 'Verificações ($n)' : 'Verificações',
                ativo: local.startsWith(Rotas.verificacoes),
                aoTocar: () => ir(Rotas.verificacoes),
              );
            }),
            // E31 (E3 do backoffice) — denúncias abertas.
            Observer(builder: (_) {
              final n = denuncias.contagem.value.abertas;
              return _ItemMenu(
                key: const Key('menu-denuncias'),
                icone: LucideIcons.flag,
                rotulo: n > 0 ? 'Denúncias ($n)' : 'Denúncias',
                ativo: local.startsWith(Rotas.denuncias),
                aoTocar: () => ir(Rotas.denuncias),
              );
            }),
            // E40 — impulsos (número = textos de push esperando a equipe).
            Observer(builder: (_) {
              final n = getIt<ImpulsosStore>().textosEmAnalise.value;
              return _ItemMenu(
                key: const Key('menu-impulsos'),
                icone: LucideIcons.barChart2,
                rotulo: n > 0 ? 'Impulsos ($n)' : 'Impulsos',
                ativo: local.startsWith(Rotas.impulsos),
                aoTocar: () => ir(Rotas.impulsos),
              );
            }),
            // E5 (backoffice) — consulta de usuários.
            _ItemMenu(
              key: const Key('menu-usuarios'),
              icone: LucideIcons.users,
              rotulo: 'Usuários',
              ativo: local.startsWith(Rotas.usuarios),
              aoTocar: () => ir(Rotas.usuarios),
            ),
            const Spacer(),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(GigSpacing.lg),
              child: Observer(builder: (_) {
                final membro = sessao.membro.value;
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(membro?.nome ?? '',
                          style: GigTypography.h3,
                          overflow: TextOverflow.ellipsis),
                      Text(membro?.login ?? '',
                          style: GigTypography.small,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: GigSpacing.md),
                      OutlinedButton.icon(
                        key: const Key('menu-sair'),
                        onPressed: () async {
                          aoNavegar?.call();
                          await sessao.sair();
                          sugestoes.limpar();
                          verificacoes.limpar();
                          denuncias.limpar();
                          getIt<UsuariosStore>().limpar();
                          getIt<ImpulsosStore>().limpar();
                          dashboard.limpar();
                        },
                        icon: const Icon(LucideIcons.logOut, size: 16),
                        label: const Text('Sair'),
                      ),
                    ]);
              }),
            ),
          ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  const _ItemMenu(
      {super.key,
      required this.icone,
      required this.rotulo,
      required this.ativo,
      required this.aoTocar});

  final IconData icone;
  final String rotulo;
  final bool ativo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cor = ativo ? GigColors.primary : GigColors.textSubtle;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: GigSpacing.md, vertical: GigSpacing.xxs),
      child: Material(
        color: ativo ? GigColors.primarySoft : Colors.transparent,
        borderRadius: GigRadius.button,
        child: InkWell(
          borderRadius: GigRadius.button,
          onTap: aoTocar,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: GigSpacing.md, vertical: GigSpacing.md),
            child: Row(children: [
              Icon(icone, size: 18, color: cor),
              const SizedBox(width: GigSpacing.md),
              Expanded(
                  child: Text(rotulo,
                      style: GigTypography.buttonMedium.copyWith(color: cor))),
            ]),
          ),
        ),
      ),
    );
  }
}
