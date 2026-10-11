import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gig_backoffice/data/models/dashboard.dart';

import 'helpers.dart';

ChoiceChip _chip(WidgetTester tester, int periodo) => tester.widget<ChoiceChip>(find.byKey(Key('periodo-$periodo')));

void main() {
  testWidgets('abre na aba Pontos de atenção e carrega só ela', (tester) async {
    final app = await montarApp(tester, logado: true);

    expect(find.text('Pontos de atenção (6)'), findsOneWidget);
    expect(find.byKey(const Key('cartao-eventos-em-risco')), findsOneWidget);
    expect(app.dashboard.chamadas.map((c) => c.aba), [AbaDashboard.atencao]);
  });

  testWidgets('trocar de aba atualiza a URL e carrega a aba na primeira vez', (tester) async {
    final app = await montarApp(tester, logado: true);

    await tester.tap(find.byKey(const Key('aba-marketplace')));
    await tester.pumpAndSettle();

    expect(app.uri.path, '/dashboard');
    expect(app.uri.queryParameters, {'aba': 'marketplace', 'periodo': '30'});
    expect(find.byKey(const Key('cartao-taxa-preenchimento')), findsOneWidget);
    expect(app.dashboard.chamadas.last.toString(), 'marketplace:30');

    // voltar para Pontos de atenção não recarrega
    final antes = app.dashboard.chamadas.length;
    await tester.tap(find.byKey(const Key('aba-atencao')));
    await tester.pumpAndSettle();
    expect(app.uri.queryParameters['aba'], 'atencao');
    expect(app.dashboard.chamadas.length, antes);
    expect(find.byKey(const Key('cartao-eventos-em-risco')), findsOneWidget);
  });

  testWidgets('abrir /dashboard?aba=qualidade&periodo=90 cai na aba e no período certos', (tester) async {
    final app = await montarApp(tester, logado: true, local: '/dashboard?aba=qualidade&periodo=90');

    expect(find.byKey(const Key('cartao-nota-CASA_AVALIOU_MUSICO')), findsOneWidget);
    expect(_chip(tester, 90).selected, isTrue);
    expect(app.dashboard.chamadas.map((c) => c.toString()), contains('qualidade:90'));
  });

  testWidgets('aba ou período inválidos na URL caem no padrão', (tester) async {
    await montarApp(tester, logado: true, local: '/dashboard?aba=xyz&periodo=15');

    expect(find.byKey(const Key('cartao-eventos-em-risco')), findsOneWidget);
  });

  testWidgets('o seletor de período fica desabilitado na aba Pontos de atenção', (tester) async {
    await montarApp(tester, logado: true);

    for (final p in PeriodoDashboard.opcoes) {
      expect(_chip(tester, p).onSelected, isNull, reason: '$p dias');
    }
    expect(find.byTooltip('Esta aba mostra a situação atual'), findsOneWidget);
  });

  testWidgets('trocar o período recarrega a aba atual e vai para a URL', (tester) async {
    final app = await montarApp(tester, logado: true, local: '/dashboard?aba=crescimento');

    await tester.tap(find.byKey(const Key('periodo-7')));
    await tester.pumpAndSettle();

    expect(app.uri.queryParameters, {'aba': 'crescimento', 'periodo': '7'});
    expect(app.dashboard.chamadas.last.toString(), 'crescimento:7');
    expect(_chip(tester, 7).selected, isTrue);
  });

  testWidgets('Atualizar ignora o cache e mostra "Atualizado às"', (tester) async {
    final app = await montarApp(tester, logado: true, local: '/dashboard?aba=curtidores');
    expect(find.byKey(const Key('atualizado-as')), findsOneWidget);

    await tester.tap(find.byKey(const Key('dashboard-atualizar')));
    await tester.pumpAndSettle();

    expect(app.dashboard.chamadas.last.toString(), 'curtidores:30:atualizar');
  });

  for (final tamanho in const [Size(1400, 900), Size(800, 900)]) {
    testWidgets('todas as abas abrem sem erro de layout (${tamanho.width.toInt()} px)', (tester) async {
      final app = await montarApp(tester, logado: true, tamanho: tamanho);
      const cartaoDe = {
        AbaDashboard.atencao: 'cartao-eventos-em-risco',
        AbaDashboard.marketplace: 'cartao-taxa-preenchimento',
        AbaDashboard.crescimento: 'cartao-novos-MUSICO',
        AbaDashboard.curtidores: 'cartao-vou',
        AbaDashboard.qualidade: 'cartao-contratos-assinados',
      };
      for (final aba in AbaDashboard.values) {
        app.router.go('/dashboard?aba=${aba.url}&periodo=30');
        await tester.pumpAndSettle();
        expect(find.byKey(Key(cartaoDe[aba]!)), findsOneWidget, reason: aba.url);
        expect(tester.takeException(), isNull, reason: aba.url);
      }
    });
  }
}
