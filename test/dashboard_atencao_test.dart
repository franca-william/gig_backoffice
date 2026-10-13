import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gig_backoffice/core/theme/theme.dart';
import 'package:gig_backoffice/data/mock/mock_dashboard.dart';
import 'package:gig_backoffice/features/dashboard/abas/atencao_aba.dart';
import 'package:gig_backoffice/features/dashboard/widgets/cartao.dart';

import 'helpers.dart';

Color _borda(WidgetTester tester, String chave) {
  final caixa = tester.widget<Container>(find.byKey(Key('cartao-$chave'))).decoration! as BoxDecoration;
  return (caixa.border! as Border).top.color;
}

void main() {
  group('cores dos cartões', () {
    test('sugestões: âmbar sem resposta, vermelho atrasadas', () {
      expect(corSugestoesSemResposta(0), CorCartao.neutro);
      expect(corSugestoesSemResposta(2), CorCartao.ambar);
      expect(corSugestoesAtrasadas(0), CorCartao.neutro);
      expect(corSugestoesAtrasadas(1), CorCartao.vermelho);
    });

    test('eventos em risco: vermelho se algum começa em até 48 h, âmbar no resto', () {
      expect(corEventosEmRisco(0, 0), CorCartao.neutro);
      expect(corEventosEmRisco(3, 0), CorCartao.ambar);
      expect(corEventosEmRisco(3, 1), CorCartao.vermelho);
    });

    test('contratos: âmbar sem assinatura, vermelho travado', () {
      expect(corContratosSemAssinatura(1), CorCartao.ambar);
      expect(corContratosTravados(1), CorCartao.vermelho);
      expect(corContratosTravados(0), CorCartao.neutro);
    });
  });

  testWidgets('o contador soma os itens e aparece na aba e no menu', (tester) async {
    await montarApp(tester, logado: true);

    // 2 sugestões sem resposta + 3 eventos em risco + 1 contrato travado
    expect(find.text('Pontos de atenção (6)'), findsOneWidget);
    expect(find.text('Dashboard (6)'), findsOneWidget);
  });

  testWidgets('cartões com as cores das regras', (tester) async {
    await montarApp(tester, logado: true);

    expect(_borda(tester, 'sugestoes-sem-resposta'), GigColors.primary);
    expect(_borda(tester, 'sugestoes-atrasadas'), GigColors.danger);
    expect(_borda(tester, 'eventos-em-risco'), GigColors.danger);
    expect(_borda(tester, 'contratos-sem-assinatura'), GigColors.border);
    expect(_borda(tester, 'contratos-travados'), GigColors.danger);
  });

  testWidgets('listas: eventos em risco e contratos com problema', (tester) async {
    await montarApp(tester, logado: true);

    expect(find.byKey(const Key('evento-e1')), findsOneWidget);
    expect(find.byKey(const Key('evento-e3')), findsOneWidget);
    expect(find.text('começa em 30 h'), findsOneWidget);
    expect(find.text('Falha ao gerar o PDF'), findsOneWidget);
    expect(find.text('Ver na lista'), findsOneWidget);
  });

  testWidgets('sem nada pendente: "Nada pedindo atenção agora" e menu sem número', (tester) async {
    await montarApp(tester, logado: true, dashboard: MockDashboardRepository(relogio: () => agoraFixo, semPendencias: true));

    expect(find.text('Nada pedindo atenção agora'), findsOneWidget);
    expect(find.text('Pontos de atenção'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('"Copiar contato da casa" copia o e-mail da casa', (tester) async {
    String? copiado;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (chamada) async {
      if (chamada.method == 'Clipboard.setData') {
        copiado = (chamada.arguments as Map<Object?, Object?>)['text'] as String?;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await montarApp(tester, logado: true);

    final botao = find.byKey(const Key('copiar-contato-e1'));
    await tester.ensureVisible(botao);
    await tester.tap(botao);
    await tester.pump();

    expect(copiado, 'bar.do.zé@exemplo.com');
    expect(find.text('Contato copiado: bar.do.zé@exemplo.com'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });

  testWidgets('"Ver na lista" abre as sugestões sem resposta', (tester) async {
    final app = await montarApp(tester, logado: true);

    final botao = find.byKey(const Key('ver-sugestoes-atrasadas'));
    await tester.ensureVisible(botao);
    await tester.tap(botao);
    await tester.pumpAndSettle();

    expect(app.uri.path, '/sugestoes');
    expect(find.text('Sugestões (6)'), findsOneWidget);
  });
}
