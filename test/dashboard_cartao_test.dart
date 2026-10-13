import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gig_backoffice/core/formatar.dart';
import 'package:gig_backoffice/core/theme/theme.dart';
import 'package:gig_backoffice/data/models/dashboard.dart';
import 'package:gig_backoffice/features/dashboard/widgets/cartao.dart';

Future<void> _montar(WidgetTester tester, DashboardCartao cartao) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await tester.pumpWidget(MaterialApp(
    theme: GigTheme.dark,
    home: Scaffold(body: SizedBox(width: 300, child: CartaoIndicador(cartao: cartao))),
  ));
}

Color? _corDoTexto(WidgetTester tester, String texto) => tester.widget<Text>(find.text(texto)).style?.color;

void main() {
  group('variação', () {
    test('positiva em % (contagens e medianas)', () {
      final v = variacaoDe(const Indicador(valor: 18, anterior: 16, variacaoPercentual: 12.5), 30)!;
      expect(v.texto, '+12,5% vs. 30 dias anteriores');
      expect(v.melhorou, isTrue);
    });

    test('negativa em pontos percentuais; subir é ruim quando maiorEhMelhor = false', () {
      final v = variacaoDe(const Indicador(valor: 25, anterior: 33.3, variacaoPontos: -8.3), 7, maiorEhMelhor: false)!;
      expect(v.texto, '-8,3 p.p. vs. 7 dias anteriores');
      expect(v.melhorou, isTrue);

      final pior = variacaoDe(const Indicador(valor: 72, anterior: 120, variacaoPercentual: -40), 90)!;
      expect(pior.texto, '-40% vs. 90 dias anteriores');
      expect(pior.melhorou, isFalse);
    });

    test('base zero vira "novo"; sem comparação não mostra nada', () {
      expect(variacaoDe(const Indicador(valor: 1, anterior: 0, novo: true), 30)!.texto, 'novo');
      expect(variacaoDe(const Indicador(valor: 50), 30), isNull);
      expect(variacaoDe(const Indicador(valor: 50, anterior: 50, variacaoPontos: 0), 30)!.melhorou, isNull);
    });
  });

  testWidgets('cartão com variação positiva (verde), negativa (vermelha) e "novo"', (tester) async {
    await _montar(
        tester,
        const DashboardCartao(
            titulo: 'Novos', valor: '18', variacao: Variacao('+12,5% vs. 30 dias anteriores', melhorou: true)));
    expect(find.text('NOVOS'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(_corDoTexto(tester, '+12,5% vs. 30 dias anteriores'), GigColors.success);

    await _montar(
        tester,
        const DashboardCartao(
            titulo: 'Tempo', valor: '3 dias', variacao: Variacao('+40% vs. 30 dias anteriores', melhorou: false)));
    expect(_corDoTexto(tester, '+40% vs. 30 dias anteriores'), GigColors.danger);

    await _montar(tester, const DashboardCartao(titulo: 'Novos', valor: '1', variacao: Variacao('novo')));
    expect(_corDoTexto(tester, 'novo'), GigColors.textMuted);
  });

  testWidgets('ⓘ mostra a regra do número', (tester) async {
    await _montar(tester, const DashboardCartao(titulo: 'Taxa', valor: '50%', ajuda: 'A regra.', chave: 'taxa'));

    await tester.tap(find.byKey(const Key('ajuda-taxa')));
    await tester.pumpAndSettle();
    expect(find.text('A regra.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  group('formatação pt-BR', () {
    test('números, percentuais, moeda e duração', () {
      expect(Formatar.numero(1234567), '1.234.567');
      expect(Formatar.numero(1234.5, casas: 1), '1.234,5');
      expect(Formatar.numero(-8.3, casas: 1), '-8,3');
      expect(Formatar.percentual(50), '50%');
      expect(Formatar.percentual(33.3), '33,3%');
      expect(Formatar.moeda(1050), r'R$ 1.050');
      expect(Formatar.duracaoEmHoras(36), '36 h');
      expect(Formatar.duracaoEmHoras(72), '3 dias');
      expect(Formatar.duracaoEmHoras(84), '3,5 dias');
      expect(Formatar.comecaEm(30), 'começa em 30 h');
      expect(Formatar.comecaEm(120), 'começa em 5 dias');
    });
  });

  test('Indicador.fromJson: campos nulos não vêm no JSON', () {
    final i = Indicador.fromJson({'valor': 75.0, 'novo': true});
    expect(i.valor, 75.0);
    expect(i.anterior, isNull);
    expect(i.variacaoPercentual, isNull);
    expect(i.novo, isTrue);
    expect(Indicador.fromJson(null).valor, isNull);
  });
}
