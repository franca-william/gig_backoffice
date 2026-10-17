import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gig_backoffice/app/di.dart';
import 'package:gig_backoffice/data/mock/mock_impulsos.dart';
import 'package:gig_backoffice/data/models/impulso.dart';
import 'package:gig_backoffice/data/repositories/repositories.dart';
import 'package:gig_backoffice/features/impulsos/impulsos_store.dart';

import 'helpers.dart';

/// E40 — menu Impulsos: textos de push para aprovar, casas que podem impulsionar, pacotes e parâmetros.
void main() {
  group('ImpulsosStore (mock)', () {
    test('aprovar tira o texto da fila e zera o número do menu', () async {
      final store = ImpulsosStore(MockImpulsoRepository(relogio: () => agoraFixo));
      await store.carregar();
      expect(store.textos.value, hasLength(1));
      expect(store.textosEmAnalise.value, 1);

      await store.aprovar(store.textos.value.single.campanhaId);
      expect(store.textos.value, isEmpty);
      expect(store.textosEmAnalise.value, 0);
    });

    test('recusar exige motivo', () async {
      final repo = MockImpulsoRepository(relogio: () => agoraFixo);
      final store = ImpulsosStore(repo);
      await store.carregar();
      expect(() => store.recusar('t1', ''), throwsA(isA<BackofficeException>()));
      await store.recusar('t1', 'Promete casa lotada');
      expect(store.textos.value, isEmpty);
    });

    test('flag por casa com histórico', () async {
      final repo = MockImpulsoRepository(relogio: () => agoraFixo);
      final store = ImpulsosStore(repo);
      await store.trocarAba(AbaImpulsos.casas);
      expect(store.casas.value.first.habilitada, isTrue, reason: 'as habilitadas primeiro');

      await store.definirFlag('c2', true, 'Parceira nova');
      expect(repo.habilitadas, containsAll(['c1', 'c2']));
      final historico = await store.historico('c2');
      expect(historico.single.valorNovo, isTrue);
      expect(historico.single.motivo, 'Parceira nova');
    });

    test('estorno: Google Play sim, App Store não', () async {
      final repo = MockImpulsoRepository(relogio: () => agoraFixo);
      final store = ImpulsosStore(repo);
      expect((await store.detalhe('i1')).podeEstornar, isTrue);
      await store.estornar('i1');
      expect((await store.detalhe('i1')).resumo.situacao, SituacaoImpulso.estornado);
      expect(() => store.estornar('i2'), throwsA(isA<BackofficeException>()));
    });

    test('parâmetro fora da faixa é recusado', () async {
      final store = ImpulsosStore(MockImpulsoRepository(relogio: () => agoraFixo));
      expect(() => store.definirParametro('push.prazo_aprovacao_horas', 99), throwsA(isA<BackofficeException>()));
      await store.definirParametro('push.prazo_aprovacao_horas', 8);
      expect(store.parametros.value.firstWhere((p) => p.chave == 'push.prazo_aprovacao_horas').valor, 8);
    });
  });

  group('tela', () {
    testWidgets('menu Impulsos mostra o texto para aprovar e aprova', (tester) async {
      await montarApp(tester, logado: true);
      expect(find.text('Impulsos (1)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('menu-impulsos')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('texto-t1')), findsOneWidget);
      expect(find.text('Hoje tem roda de samba!'), findsOneWidget);

      await tester.tap(find.byKey(const Key('aprovar-t1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('texto-t1')), findsNothing);
      expect(getIt<ImpulsosStore>().textosEmAnalise.value, 0);
    });

    testWidgets('aba Casas liga a flag com motivo opcional', (tester) async {
      await montarApp(tester, logado: true);
      await tester.tap(find.byKey(const Key('menu-impulsos')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('aba-impulsos-casas')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('flag-c3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('impulso-dialogo-confirmar')));
      await tester.pumpAndSettle();

      final casas = await getIt<ImpulsoRepository>().casas();
      expect(casas.itens.firstWhere((c) => c.id == 'c3').habilitada, isTrue);
    });
  });
}
