import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gig_backoffice/app/app.dart';
import 'package:gig_backoffice/app/di.dart';
import 'package:gig_backoffice/app/router.dart';
import 'package:gig_backoffice/app/sessao_store.dart';
import 'package:gig_backoffice/data/mock/mock_dashboard.dart';
import 'package:gig_backoffice/data/mock/mock_repositories.dart';

/// "Agora" fixo dos testes: sábado, 10/10/2026 15:00 (hora local).
final agoraFixo = DateTime(2026, 10, 10, 15);

class AppDeTeste {
  AppDeTeste(this.router, this.sessao, this.sugestoes, this.sessaoRepo, this.dashboard);

  final GoRouter router;
  final SessaoStore sessao;
  final MockSugestaoRepository sugestoes;
  final MockSessaoRepository sessaoRepo;
  final MockDashboardRepository dashboard;

  /// Caminho + query atuais (ex.: `/dashboard?aba=marketplace&periodo=30`).
  Uri get uri => router.routeInformationProvider.value.uri;
}

/// Monta o backoffice com mocks numa janela de desktop (1400 × 900).
Future<AppDeTeste> montarApp(
  WidgetTester tester, {
  bool logado = false,
  bool cookieValido = false,
  String local = '/dashboard',
  Size tamanho = const Size(1400, 900),
  MockDashboardRepository? dashboard,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final sessaoRepo = MockSessaoRepository(cookieValido: cookieValido || logado);
  final sugestoes = MockSugestaoRepository(relogio: () => agoraFixo);
  final dashboardRepo = dashboard ?? MockDashboardRepository(relogio: () => agoraFixo);
  configurarDependencias(
      sessao: sessaoRepo, sugestoes: sugestoes, dashboard: dashboardRepo, relogio: () => agoraFixo);
  final sessao = getIt<SessaoStore>();
  await sessao.restaurar();
  final router = criarRouter(sessao, localInicial: local);
  await tester.pumpWidget(BackofficeApp(router: router));
  await tester.pumpAndSettle();
  return AppDeTeste(router, sessao, sugestoes, sessaoRepo, dashboardRepo);
}

Future<void> entrarComo(WidgetTester tester, String email, String senha) async {
  await tester.enterText(find.descendant(of: find.byKey(const Key('login-email')), matching: find.byType(EditableText)), email);
  await tester.enterText(find.descendant(of: find.byKey(const Key('login-senha')), matching: find.byType(EditableText)), senha);
  await tester.tap(find.text('ENTRAR'));
  await tester.pumpAndSettle();
}
