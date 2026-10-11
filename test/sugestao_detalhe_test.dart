import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gig_backoffice/app/di.dart';
import 'package:gig_backoffice/data/models/models.dart';
import 'package:gig_backoffice/features/sugestoes/sugestoes_store.dart';

import 'helpers.dart';

String _textoDoCampo(WidgetTester tester) =>
    tester.widget<TextField>(find.byKey(const Key('campo-resposta'))).controller!.text;

void main() {
  testWidgets('marcar em análise (recebida)', (tester) async {
    final app = await montarApp(tester, logado: true, local: '/sugestoes/s1');

    await tester.tap(find.byKey(const Key('marcar-em-analise')));
    await tester.pumpAndSettle();

    expect((await app.sugestoes.detalhe('s1')).situacao, SituacaoSugestao.emAnalise);
    expect(find.byKey(const Key('marcar-em-analise')), findsNothing);
    expect(find.textContaining('Em análise · Ana Equipe'), findsOneWidget);
  });

  testWidgets('resposta já vem com o início sugerido, pede confirmação e depois mostra a resposta', (tester) async {
    final app = await montarApp(tester, logado: true, local: '/sugestoes/s1');

    expect(_textoDoCampo(tester), 'Oi, Carlos! Obrigado pela sugestão. ');
    await tester.enterText(find.byKey(const Key('campo-resposta')), 'Oi, Carlos! Obrigado pela sugestão. Já está na fila.');
    await tester.pump();
    await tester.tap(find.byKey(const Key('enviar-resposta')));
    await tester.pumpAndSettle();

    expect(find.text('A resposta não pode ser editada depois. Enviar?'), findsOneWidget);
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('campo-resposta')), findsNothing);
    expect(find.byKey(const Key('resposta-enviada')), findsOneWidget);
    expect(find.text('Oi, Carlos! Obrigado pela sugestão. Já está na fila.'), findsOneWidget);
    expect((await app.sugestoes.detalhe('s1')).respondida, isTrue);
    expect(getIt<SugestoesStore>().contagem.value.semResposta, 5);
  });

  testWidgets('cancelar a confirmação não envia', (tester) async {
    final app = await montarApp(tester, logado: true, local: '/sugestoes/s1');

    await tester.tap(find.byKey(const Key('enviar-resposta')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect((await app.sugestoes.detalhe('s1')).respondida, isFalse);
    expect(find.byKey(const Key('campo-resposta')), findsOneWidget);
  });

  testWidgets('Ctrl+Enter envia (com a mesma confirmação)', (tester) async {
    await montarApp(tester, logado: true, local: '/sugestoes/s1');

    await tester.tap(find.byKey(const Key('campo-resposta')));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.text('A resposta não pode ser editada depois. Enviar?'), findsOneWidget);
  });

  testWidgets('409: outra pessoa respondeu antes — a tela recarrega com a resposta dela', (tester) async {
    final app = await montarApp(tester, logado: true, local: '/sugestoes/s3');
    app.sugestoes.respondidasPorOutraPessoa.add('s3');

    await tester.tap(find.byKey(const Key('enviar-resposta')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.text('Outra pessoa da equipe acabou de responder esta sugestão.'), findsOneWidget);
    expect(find.text('Resposta enviada por outra pessoa da equipe.'), findsOneWidget);
    expect(find.byKey(const Key('campo-resposta')), findsNothing);
  });

  testWidgets('sugestão respondida mostra a resposta e quem respondeu, sem campo', (tester) async {
    await montarApp(tester, logado: true, local: '/sugestoes/s6');

    expect(find.byKey(const Key('resposta-enviada')), findsOneWidget);
    expect(find.byKey(const Key('campo-resposta')), findsNothing);
    expect(find.byKey(const Key('marcar-em-analise')), findsNothing);
    expect(find.textContaining('Por Ana Equipe'), findsOneWidget);
  });

  testWidgets('conta excluída aparece como "Usuário excluído" e o início sugerido não tem nome', (tester) async {
    await montarApp(tester, logado: true, local: '/sugestoes/s4');

    expect(find.text('Usuário excluído'), findsOneWidget);
    expect(_textoDoCampo(tester), 'Oi! Obrigado pela sugestão. ');
  });
}
