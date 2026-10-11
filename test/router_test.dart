import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gig_backoffice/app/router.dart';

import 'helpers.dart';

void main() {
  test('sem sessão, rotas protegidas vão para o login', () {
    for (final local in ['/dashboard', '/sugestoes', '/sugestoes/s1']) {
      expect(redirecionar(logado: false, local: local), '/login', reason: local);
    }
    expect(redirecionar(logado: false, local: '/login'), isNull);
  });

  test('com sessão, o login vai para o dashboard', () {
    expect(redirecionar(logado: true, local: '/login'), '/dashboard');
    expect(redirecionar(logado: true, local: '/sugestoes'), isNull);
  });

  testWidgets('abrir /sugestoes/s1 sem sessão mostra o login', (tester) async {
    final app = await montarApp(tester, local: '/sugestoes/s1');

    expect(app.router.routeInformationProvider.value.uri.path, '/login');
    expect(find.text('ENTRAR'), findsOneWidget);
  });

  testWidgets('tela estreita: o menu vira gaveta', (tester) async {
    await montarApp(tester, logado: true, tamanho: const Size(800, 900));

    expect(find.text('Sugestões (6)'), findsNothing);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('Sugestões (6)'), findsOneWidget);
  });
}
