import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gig_backoffice/data/mock/mock_repositories.dart';

import 'helpers.dart';

void main() {
  testWidgets('senha errada mostra a mensagem genérica e continua no login', (tester) async {
    final app = await montarApp(tester);

    await entrarComo(tester, MockSessaoRepository.loginEquipe, 'errada');

    expect(find.text('E-mail ou senha inválidos.'), findsOneWidget);
    expect(app.router.routeInformationProvider.value.uri.path, '/login');
  });

  testWidgets('conta sem acesso vê a mesma mensagem da senha errada', (tester) async {
    await montarApp(tester);

    await entrarComo(tester, 'musico@gig.app', MockSessaoRepository.senhaEquipe);

    expect(find.text('E-mail ou senha inválidos.'), findsOneWidget);
  });

  testWidgets('login certo vai para o dashboard com o primeiro nome', (tester) async {
    final app = await montarApp(tester);

    await entrarComo(tester, MockSessaoRepository.loginEquipe, MockSessaoRepository.senhaEquipe);

    expect(app.router.routeInformationProvider.value.uri.path, '/dashboard');
    expect(find.textContaining('Ana'), findsWidgets);
    expect(find.byKey(const Key('aba-atencao')), findsOneWidget);
  });

  testWidgets('recarregar com o cookie válido entra direto (renovação)', (tester) async {
    final app = await montarApp(tester, cookieValido: true, local: '/sugestoes');

    expect(app.sessao.logado.value, isTrue);
    expect(app.router.routeInformationProvider.value.uri.path, '/sugestoes');
  });

  testWidgets('sessão expirada no meio do uso volta ao login com aviso', (tester) async {
    final app = await montarApp(tester, logado: true);

    app.sessao.expirou();
    await tester.pumpAndSettle();

    expect(app.router.routeInformationProvider.value.uri.path, '/login');
    expect(find.text('Sua sessão expirou. Entre de novo.'), findsOneWidget);
  });

  testWidgets('sair apaga a sessão (cookie) e volta ao login', (tester) async {
    final app = await montarApp(tester, logado: true);

    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(app.router.routeInformationProvider.value.uri.path, '/login');
    expect(app.sessaoRepo.cookieValido, isFalse);
  });

  test('nada de sessão em localStorage/sessionStorage no código', () {
    final arquivos = Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    for (final arquivo in arquivos) {
      final codigo = arquivo.readAsStringSync();
      expect(codigo.contains('localStorage') || codigo.contains('sessionStorage') || codigo.contains('shared_preferences'),
          isFalse,
          reason: arquivo.path);
    }
  });
}
