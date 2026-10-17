import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gig_backoffice/data/mock/mock_usuarios.dart';
import 'package:gig_backoffice/data/models/models.dart';
import 'package:gig_backoffice/data/models/usuario.dart';
import 'package:gig_backoffice/core/widgets/gig_logo.dart';

import 'helpers.dart';

/// E5 (backoffice) — menu Usuários (consulta somente leitura) e cabeçalho só com o símbolo da marca.

List<String> _ordem(WidgetTester tester) {
  final linhas = find.byWidgetPredicate((w) =>
      w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('linha-usuario-'));
  return tester.widgetList(linhas).map((w) => (w.key! as ValueKey<String>).value.substring(14)).toList();
}

void main() {
  group('cabeçalho do menu', () {
    testWidgets('mostra só o símbolo: sem o nome GiG e sem o texto Backoffice', (tester) async {
      await montarApp(tester, logado: true);

      expect(find.byType(GigLogo), findsNothing);
      expect(find.text('Backoffice'), findsNothing);
      expect(find.text('GiG Backoffice'), findsNothing);
      expect(find.bySemanticsLabel('GiG'), findsOneWidget);
    });
  });

  group('menu Usuários', () {
    testWidgets('item no menu abre a lista em ordem alfabética', (tester) async {
      await montarApp(tester, logado: true);

      await tester.tap(find.byKey(const Key('menu-usuarios')));
      await tester.pumpAndSettle();

      expect(_ordem(tester), ['u1', 'u2', 'u3', 'u4', 'u5', 'u6']);
    });

    testWidgets('busca por nome ou e-mail', (tester) async {
      await montarApp(tester, logado: true, local: '/usuarios');

      await tester.enterText(find.byKey(const Key('filtro-busca-usuario')), 'carlos');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(_ordem(tester), ['u3']);

      await tester.enterText(find.byKey(const Key('filtro-busca-usuario')), 'bar.do');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(_ordem(tester), ['u2']);
    });

    testWidgets('chip de perfil filtra e tocar de novo tira o filtro', (tester) async {
      await montarApp(tester, logado: true, local: '/usuarios');

      await tester.tap(find.byKey(const Key('chip-perfil-CURTIDOR')));
      await tester.pumpAndSettle();
      expect(_ordem(tester), ['u3', 'u4', 'u6']);

      await tester.tap(find.byKey(const Key('chip-perfil-CURTIDOR')));
      await tester.pumpAndSettle();
      expect(_ordem(tester), hasLength(6));
    });

    testWidgets('tocar na linha abre o detalhe e voltar retorna à lista', (tester) async {
      final app = await montarApp(tester, logado: true, local: '/usuarios');

      await tester.tap(find.byKey(const Key('linha-usuario-u5')));
      await tester.pumpAndSettle();

      expect(app.uri.path, '/usuarios/u5');
      expect(find.text('Pedro Alves'), findsWidgets);
      expect(find.text('SUSPENSO'), findsOneWidget);
      expect(find.text('Suspenso até'.toUpperCase()), findsOneWidget);

      await tester.tap(find.byKey(const Key('usuario-voltar')));
      await tester.pumpAndSettle();
      expect(app.uri.path, '/usuarios');
    });
  });

  test('o mock devolve erro para usuário inexistente', () async {
    final repo = MockUsuarioRepository(relogio: () => agoraFixo);
    expect(() => repo.detalhe('nao-existe'), throwsA(isA<Exception>()));
    final pagina = await repo.listar(const FiltroUsuarios(perfil: PerfilSugestao.estabelecimento));
    expect(pagina.itens.map((u) => u.id), ['u2']);
  });
}
