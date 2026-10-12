import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobx/mobx.dart';

import '../data/models/dashboard.dart';
import '../features/auth/login_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/shell/layout_backoffice.dart';
import '../features/sugestoes/sugestao_detalhe_page.dart';
import '../features/sugestoes/sugestoes_page.dart';
import 'rotas.dart';
import 'sessao_store.dart';

/// Faz o GoRouter reavaliar o redirect quando a sessão muda.
class _MobxListenable extends ChangeNotifier {
  _MobxListenable(Object? Function() track) {
    _dispose = reaction<Object?>((_) => track(), (_) => notifyListeners());
  }

  late final ReactionDisposer _dispose;

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }
}

/// `/login` público; `/dashboard`, `/sugestoes` e `/sugestoes/:id` dentro do layout com menu.
/// Sem sessão → `/login`; com sessão em `/login` → `/dashboard`.
GoRouter criarRouter(SessaoStore sessao,
    {String localInicial = Rotas.dashboard}) {
  return GoRouter(
    initialLocation: localInicial,
    refreshListenable: _MobxListenable(() => sessao.logado.value),
    redirect: (context, state) =>
        redirecionar(logado: sessao.logado.value, local: state.matchedLocation),
    errorBuilder: (context, state) => const _NaoEncontrada(),
    routes: [
      GoRoute(path: '/', redirect: (_, __) => Rotas.dashboard),
      GoRoute(
          path: Rotas.login, builder: (context, state) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) =>
            LayoutBackoffice(local: state.matchedLocation, child: child),
        routes: [
          GoRoute(
              path: Rotas.dashboard,
              pageBuilder: (c, s) => NoTransitionPage(
                    child: DashboardPage(
                      aba: AbaDashboard.deUrl(s.uri.queryParameters['aba']),
                      periodo: PeriodoDashboard.deUrl(s.uri.queryParameters['periodo']),
                    ),
                  )),
          GoRoute(
            path: Rotas.sugestoes,
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: SugestoesPage()),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (c, s) => NoTransitionPage(
                    child: SugestaoDetalhePage(id: s.pathParameters['id']!)),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

@visibleForTesting
String? redirecionar({required bool logado, required String local}) {
  final noLogin = local == Rotas.login;
  if (!logado && !noLogin) return Rotas.login;
  if (logado && noLogin) return Rotas.dashboard;
  return null;
}

class _NaoEncontrada extends StatelessWidget {
  const _NaoEncontrada();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Página não encontrada.'),
          TextButton(
              onPressed: () => context.go(Rotas.dashboard),
              child: const Text('Ir para o Dashboard')),
        ]),
      ),
    );
  }
}
