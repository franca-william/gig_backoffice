import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gig_backoffice/data/models/models.dart';

import 'helpers.dart';

double _y(WidgetTester tester, String id) => tester.getTopLeft(find.byKey(Key('linha-$id'))).dy;

void main() {
  group('prazoDe', () {
    final agora = DateTime(2026, 10, 10, 15);

    test('Atrasada quando passou do prazo sem resposta', () {
      expect(prazoDe(SituacaoSugestao.recebida, DateTime(2026, 10, 10, 14), agora), Prazo.atrasada);
      expect(prazoDe(SituacaoSugestao.emAnalise, DateTime(2026, 10, 9, 8), agora), Prazo.atrasada);
    });

    test('Vence hoje no último dia', () {
      expect(prazoDe(SituacaoSugestao.recebida, DateTime(2026, 10, 10, 23, 59), agora), Prazo.venceHoje);
    });

    test('no prazo antes do último dia, e respondida nunca atrasa', () {
      expect(prazoDe(SituacaoSugestao.recebida, DateTime(2026, 10, 11, 1), agora), Prazo.noPrazo);
      expect(prazoDe(SituacaoSugestao.respondida, DateTime(2026, 10, 1), agora), Prazo.noPrazo);
    });
  });

  testWidgets('padrão "Sem resposta": mais antigas primeiro, etiquetas de atraso e contador no menu', (tester) async {
    await montarApp(tester, logado: true, local: '/sugestoes');

    expect(find.text('Sugestões (6)'), findsOneWidget);
    expect(find.text('2 ATRASADAS'), findsOneWidget); // Etiqueta mostra em maiúsculas
    expect(find.text('ATRASADA'), findsNWidgets(2));
    // respondidas não aparecem no padrão
    expect(find.byKey(const Key('linha-s6')), findsNothing);
    // ordem pelo prazo: s1, s2, s3, s4, s5, s8
    expect(_y(tester, 's1'), lessThan(_y(tester, 's2')));
    expect(_y(tester, 's2'), lessThan(_y(tester, 's3')));
    expect(_y(tester, 's5'), lessThan(_y(tester, 's8')));
    // conta excluída
    expect(find.text('Usuário excluído'), findsOneWidget);
  });

  testWidgets('chip "Respondidas" mostra só as respondidas', (tester) async {
    await montarApp(tester, logado: true, local: '/sugestoes');

    await tester.tap(find.byKey(const Key('chip-RESPONDIDA')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('linha-s6')), findsOneWidget);
    expect(find.byKey(const Key('linha-s7')), findsOneWidget);
    expect(find.byKey(const Key('linha-s1')), findsNothing);
  });

  testWidgets('filtro de perfil e busca no texto', (tester) async {
    await montarApp(tester, logado: true, local: '/sugestoes');

    await tester.tap(find.byKey(const Key('filtro-perfil')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Músico').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('linha-s1')), findsOneWidget);
    expect(find.byKey(const Key('linha-s5')), findsOneWidget);
    expect(find.byKey(const Key('linha-s2')), findsNothing);

    await tester.enterText(find.byKey(const Key('filtro-busca')), 'pagamento');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('linha-s5')), findsOneWidget);
    expect(find.byKey(const Key('linha-s1')), findsNothing);
  });

  testWidgets('sem nada pendente: "Tudo respondido!"', (tester) async {
    final app = await montarApp(tester, logado: true, local: '/dashboard');
    for (final id in ['s1', 's2', 's3', 's4', 's5', 's8']) {
      await app.sugestoes.responder(id, 'Obrigado!');
    }

    await tester.tap(find.byKey(const Key('menu-sugestoes')));
    await tester.pumpAndSettle();

    expect(find.text('Tudo respondido! 🎉'), findsOneWidget);
    expect(find.text('Sugestões'), findsWidgets);
  });

  testWidgets('clicar na linha abre o detalhe', (tester) async {
    final app = await montarApp(tester, logado: true, local: '/sugestoes');

    await tester.tap(find.byKey(const Key('linha-s3')));
    await tester.pumpAndSettle();

    expect(app.router.routeInformationProvider.value.uri.path, '/sugestoes/s3');
    expect(find.text('Júlia Rocha'), findsOneWidget);
  });
}
