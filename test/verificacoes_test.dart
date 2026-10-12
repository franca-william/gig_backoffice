import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gig_backoffice/app/di.dart';
import 'package:gig_backoffice/core/web/abrir_no_navegador.dart';
import 'package:gig_backoffice/core/widgets/gig_button.dart';
import 'package:gig_backoffice/data/mock/mock_verificacoes.dart';
import 'package:gig_backoffice/data/models/models.dart';
import 'package:gig_backoffice/data/models/verificacao.dart';
import 'package:gig_backoffice/data/repositories/repositories.dart';

import 'helpers.dart';

/// E30 — menu Verificações: fila, detalhe com os arquivos, aprovar, pedir ajuste e pedido sem CNPJ.

MockVerificacaoRepository get _repo => getIt<VerificacaoRepository>() as MockVerificacaoRepository;

Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

void main() {
  group('fila', () {
    testWidgets('menu mostra quantas estão em análise e a fila vem pelo prazo', (tester) async {
      await montarApp(tester, logado: true, local: '/verificacoes');

      expect(find.text('Verificações (3)'), findsOneWidget);
      expect(find.byKey(const Key('verificacoes-atrasadas')), findsOneWidget);
      expect(find.text('Atrasada'.toUpperCase()), findsOneWidget);
      expect(find.text('Sem CNPJ — contato'.toUpperCase()), findsOneWidget);

      final linhas = find.byWidgetPredicate((w) => w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('linha-verificacao-'));
      final ordem = tester.widgetList(linhas).map((w) => (w.key! as ValueKey<String>).value).toList();
      expect(ordem, ['linha-verificacao-v1', 'linha-verificacao-v3', 'linha-verificacao-v2']);
    });

    testWidgets('chip Todas mostra as analisadas também', (tester) async {
      await montarApp(tester, logado: true, local: '/verificacoes');

      await _tocar(tester, find.byKey(const Key('chip-verificacao-TODAS')));

      expect(find.byKey(const Key('linha-verificacao-v4')), findsOneWidget);
      expect(find.byKey(const Key('linha-verificacao-v5')), findsOneWidget);
    });

    test('prazo da verificação', () {
      final agora = DateTime(2026, 10, 10, 15);
      expect(prazoDaVerificacao(SituacaoVerificacao.emAnalise, DateTime(2026, 10, 9), agora), Prazo.atrasada);
      expect(prazoDaVerificacao(SituacaoVerificacao.emAnalise, DateTime(2026, 10, 10, 20), agora), Prazo.venceHoje);
      expect(prazoDaVerificacao(SituacaoVerificacao.aprovada, DateTime(2026, 10, 9), agora), Prazo.noPrazo);
      expect(formatarCnpj('11222333000181'), '11.222.333/0001-81');
    });
  });

  group('detalhe com documentos', () {
    testWidgets('mostra documento e selfie lado a lado com marca d\'água; PDF só baixa quando pede', (tester) async {
      await montarApp(tester, logado: true, local: '/verificacoes/v1');

      expect(find.byKey(const Key('arquivo-DOCUMENTO_FRENTE')), findsOneWidget);
      expect(find.byKey(const Key('arquivo-SELFIE_DOCUMENTO')), findsOneWidget);
      expect(find.byKey(const Key('marca-dagua')), findsWidgets);
      expect(_repo.arquivosAbertos, containsAll(['v1-frente', 'v1-verso', 'v1-selfie']));
      expect(_repo.arquivosAbertos, isNot(contains('v1-comprovante')));

      await _tocar(tester, find.byKey(const Key('abrir-pdf-COMPROVANTE')));

      expect(_repo.arquivosAbertos, contains('v1-comprovante'));
      expect(ultimoEnderecoAberto, 'blob:application/pdf');
    });

    testWidgets('aprovar pede confirmação, mostra a devolutiva e baixa o número do menu', (tester) async {
      await montarApp(tester, logado: true, local: '/verificacoes/v1');

      await _tocar(tester, find.byKey(const Key('aprovar-verificacao')));
      expect(find.textContaining('A casa vai receber uma notificação no app.'), findsOneWidget);
      await tester.tap(find.text('Aprovar').last);
      await tester.pumpAndSettle();

      expect((await _repo.detalhe('v1')).situacao, SituacaoVerificacao.aprovada);
      expect(find.byKey(const Key('devolutiva')), findsOneWidget);
      expect(find.byKey(const Key('aprovar-verificacao')), findsNothing);
      expect(find.text('Verificações (2)'), findsOneWidget);
    });

    testWidgets('pedir ajuste exige motivo em cada documento e mostra a prévia da notificação', (tester) async {
      await montarApp(tester, logado: true, local: '/verificacoes/v1');

      await _tocar(tester, find.byKey(const Key('pedir-ajuste')));
      GigButtonFinder.semAcao(tester, const Key('confirmar-ajuste'));

      await _tocar(tester, find.byKey(const Key('recusar-SELFIE_DOCUMENTO')));
      GigButtonFinder.semAcao(tester, const Key('confirmar-ajuste'));

      await _tocar(tester, find.byKey(const Key('motivo-SELFIE_DOCUMENTO')));
      await tester.tap(find.text('Rosto não confere').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('comentario-SELFIE_DOCUMENTO')), 'Tire sem óculos escuros');
      await tester.pump();

      expect(find.textContaining('1 documento precisa ser reenviado'), findsOneWidget);
      await _tocar(tester, find.byKey(const Key('confirmar-ajuste')));

      final v = await _repo.detalhe('v1');
      expect(v.situacao, SituacaoVerificacao.reprovada);
      final selfie = v.arquivo(TipoArquivoVerificacao.selfie)!;
      expect(selfie.situacao, SituacaoArquivo.recusado);
      expect(selfie.motivo, MotivoRecusa.rostoNaoConfere);
      expect(selfie.comentario, 'Tire sem óculos escuros');
      expect(v.arquivo(TipoArquivoVerificacao.frente)!.situacao, SituacaoArquivo.aceito);
      expect(find.byKey(const Key('devolutiva')), findsOneWidget);
    });

    testWidgets('outra pessoa já decidiu: avisa e recarrega', (tester) async {
      await montarApp(tester, logado: true, local: '/verificacoes/v2');
      _repo.analisadasPorOutraPessoa.add('v2');

      await _tocar(tester, find.byKey(const Key('aprovar-verificacao')));
      await tester.tap(find.text('Aprovar').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('Outra pessoa da equipe'), findsOneWidget);
    });

    testWidgets('CNH digital em PDF: sem verso', (tester) async {
      await montarApp(tester, logado: true, local: '/verificacoes/v2');
      expect(find.text('CNH digital em PDF: sem verso.'), findsOneWidget);
      expect(find.byKey(const Key('abrir-pdf-DOCUMENTO_FRENTE')), findsOneWidget);
    });
  });

  group('casa sem CNPJ', () {
    testWidgets('mostra o contato; aprovar exige a observação interna', (tester) async {
      await montarApp(tester, logado: true, local: '/verificacoes/v3');

      expect(find.byKey(const Key('contato-sem-cnpj')), findsOneWidget);
      expect(find.text('(85) 99999-1234'), findsOneWidget);
      expect(find.text('Recusar'), findsOneWidget);

      await _tocar(tester, find.byKey(const Key('aprovar-verificacao')));
      expect(find.textContaining('Registre na observação interna'), findsOneWidget);
      expect((await _repo.detalhe('v3')).situacao, SituacaoVerificacao.emAnalise);

      await tester.enterText(find.byKey(const Key('observacao-interna')), 'Liguei no telefone do Google Maps.');
      await _tocar(tester, find.byKey(const Key('aprovar-verificacao')));
      await tester.tap(find.text('Aprovar').last);
      await tester.pumpAndSettle();

      final v = await _repo.detalhe('v3');
      expect(v.situacao, SituacaoVerificacao.aprovada);
      expect(v.observacaoInterna, 'Liguei no telefone do Google Maps.');
    });

    testWidgets('recusar exige a mensagem para a casa', (tester) async {
      await montarApp(tester, logado: true, local: '/verificacoes/v3');

      await _tocar(tester, find.byKey(const Key('pedir-ajuste')));
      GigButtonFinder.semAcao(tester, const Key('confirmar-ajuste'));
      await tester.enterText(find.byKey(const Key('mensagem-para-casa')), 'Não encontramos a casa no endereço.');
      await tester.pump();
      await _tocar(tester, find.byKey(const Key('confirmar-ajuste')));

      final v = await _repo.detalhe('v3');
      expect(v.situacao, SituacaoVerificacao.reprovada);
      expect(v.mensagemParaCasa, 'Não encontramos a casa no endereço.');
    });
  });
}

/// Confere que o botão (GigButton com a chave) está desabilitado.
abstract final class GigButtonFinder {
  static void semAcao(WidgetTester tester, Key chave) {
    expect(tester.widget<GigButton>(find.byKey(chave)).onPressed, isNull, reason: '$chave deveria estar desabilitado');
  }
}
