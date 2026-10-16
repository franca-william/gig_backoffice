import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gig_backoffice/app/di.dart';
import 'package:gig_backoffice/data/mock/mock_denuncias.dart';
import 'package:gig_backoffice/data/models/denuncia.dart';
import 'package:gig_backoffice/data/models/models.dart';
import 'package:gig_backoffice/data/repositories/repositories.dart';

import 'helpers.dart';

/// E31 (E3 do backoffice) — menu Denúncias: fila por gravidade e prazo, detalhe com retrato × perfil atual e as
/// decisões (improcedente, remover, advertir, suspender 7/30, banir com confirmação dupla).

MockDenunciaRepository get _repo => getIt<DenunciaRepository>() as MockDenunciaRepository;

Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

List<String> _ordem(WidgetTester tester) {
  final linhas = find.byWidgetPredicate((w) =>
      w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('linha-denuncia-'));
  return tester.widgetList(linhas).map((w) => (w.key! as ValueKey<String>).value.substring(15)).toList();
}

void main() {
  group('fila', () {
    testWidgets('menu mostra as abertas; gravidade alta primeiro, depois o prazo', (tester) async {
      await montarApp(tester, logado: true, local: '/denuncias');

      expect(find.text('Denúncias (4)'), findsOneWidget);
      expect(_ordem(tester), ['d1', 'd4', 'd2', 'd3']);
      expect(find.byKey(const Key('denuncias-atrasadas')), findsOneWidget);
      expect(find.byKey(const Key('denuncias-altas')), findsOneWidget);
      expect(find.text('ATRASADA'), findsOneWidget);
    });

    testWidgets('chip de gravidade filtra e tocar de novo tira o filtro', (tester) async {
      await montarApp(tester, logado: true, local: '/denuncias');

      await _tocar(tester, find.byKey(const Key('chip-gravidade-ALTA')));
      expect(_ordem(tester), ['d1', 'd4']);

      await _tocar(tester, find.byKey(const Key('chip-gravidade-ALTA')));
      expect(_ordem(tester), hasLength(4));
    });

    testWidgets('chip Todas mostra as decididas no fim', (tester) async {
      await montarApp(tester, logado: true, local: '/denuncias');
      await _tocar(tester, find.byKey(const Key('chip-denuncia-TODAS')));
      expect(_ordem(tester).last, 'd5');
    });

    test('prazo da denúncia', () {
      final agora = DateTime(2026, 10, 10, 15);
      expect(prazoDaDenuncia(SituacaoDenuncia.aberta, DateTime(2026, 10, 10, 9), agora), Prazo.atrasada);
      expect(prazoDaDenuncia(SituacaoDenuncia.aberta, DateTime(2026, 10, 10, 22), agora), Prazo.venceHoje);
      expect(prazoDaDenuncia(SituacaoDenuncia.improcedente, DateTime(2026, 10, 9), agora), Prazo.noPrazo);
    });
  });

  group('detalhe', () {
    testWidgets('retrato × perfil atual, foto oculta e histórico do perfil', (tester) async {
      await montarApp(tester, logado: true, local: '/denuncias/d1');

      expect(find.byKey(const Key('retrato')), findsOneWidget);
      expect(find.byKey(const Key('perfil-atual')), findsOneWidget);
      expect(find.byKey(const Key('foto-retrato')), findsOneWidget);
      expect(_repo.fotosAbertas, contains('d1'));
      expect(find.byKey(const Key('foto-oculta')), findsOneWidget);
      expect(find.text('3 denúncias de 3 pessoas diferentes'), findsOneWidget);
      expect(find.textContaining('Rafael Lima (Curtidor)'), findsOneWidget);
    });

    testWidgets('improcedente confirma, mostra a decisão e baixa o número do menu', (tester) async {
      await montarApp(tester, logado: true, local: '/denuncias/d1');

      await _tocar(tester, find.byKey(const Key('decidir-improcedente')));
      expect(find.textContaining('A foto escondida automaticamente volta a aparecer.'), findsOneWidget);
      await tester.tap(find.text('Improcedente').last);
      await tester.pumpAndSettle();

      expect((await _repo.detalhe('d1')).situacao, SituacaoDenuncia.improcedente);
      expect(_repo.decisoes['d1']!.procedente, isFalse);
      expect(find.byKey(const Key('decisao-tomada')), findsOneWidget);
      expect(find.byKey(const Key('decidir-banir')), findsNothing);
      expect(find.text('Denúncias (3)'), findsOneWidget);
    });

    testWidgets('suspender escolhe 7 ou 30 dias e leva a mensagem para a pessoa', (tester) async {
      await montarApp(tester, logado: true, local: '/denuncias/d2');

      await tester.ensureVisible(find.byKey(const Key('mensagem-denunciado')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('mensagem-denunciado')), 'Respeite quem recusou a conversa.');
      await _tocar(tester, find.byKey(const Key('decidir-suspender')));
      await _tocar(tester, find.byKey(const Key('suspender-7')));

      final decisao = _repo.decisoes['d2']!;
      expect(decisao.acao, AcaoDenuncia.suspensao);
      expect(decisao.diasSuspensao, 7);
      expect(decisao.mensagemParaDenunciado, 'Respeite quem recusou a conversa.');
      expect((await _repo.detalhe('d2')).atual.suspensoAte, isNotNull);
    });

    testWidgets('remover pede foto ou sobre', (tester) async {
      await montarApp(tester, logado: true, local: '/denuncias/d3');

      await _tocar(tester, find.byKey(const Key('decidir-remover')));
      final confirmar = tester.widget<FilledButton>(find.byKey(const Key('confirmar-remocao')));
      expect(confirmar.onPressed, isNull);

      await _tocar(tester, find.byKey(const Key('remover-sobre')));
      await _tocar(tester, find.byKey(const Key('confirmar-remocao')));

      final decisao = _repo.decisoes['d3']!;
      expect(decisao.acao, AcaoDenuncia.conteudoRemovido);
      expect(decisao.removerSobre, isTrue);
      expect(decisao.removerFoto, isFalse);
    });

    testWidgets('banir pede confirmação dupla', (tester) async {
      await montarApp(tester, logado: true, local: '/denuncias/d4');

      await _tocar(tester, find.byKey(const Key('decidir-banir')));
      expect(find.textContaining('O banimento é definitivo'), findsOneWidget);
      await _tocar(tester, find.text('Continuar'));
      expect(find.text('Confirmar banimento'), findsOneWidget);
      await _tocar(tester, find.text('Cancelar').last);
      expect(_repo.decisoes, isEmpty);

      await _tocar(tester, find.byKey(const Key('decidir-banir')));
      await _tocar(tester, find.text('Continuar'));
      await _tocar(tester, find.text('Banir').last);

      expect(_repo.decisoes['d4']!.acao, AcaoDenuncia.banimento);
      expect((await _repo.detalhe('d4')).atual.banidoEm, isNotNull);
    });

    testWidgets('outra pessoa já decidiu: avisa e recarrega', (tester) async {
      await montarApp(tester, logado: true, local: '/denuncias/d2');
      _repo.decididasPorOutraPessoa.add('d2');

      await _tocar(tester, find.byKey(const Key('decidir-advertir')));
      await tester.tap(find.text('Advertir').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('Outra pessoa da equipe'), findsOneWidget);
    });
  });

  group('JSON da API', () {
    test('detalhe com retrato, perfil atual, histórico e decisão', () {
      final d = DenunciaDetalhe.fromJson({
        'uuid': 'x1',
        'tipo': 'ASSEDIO',
        'tipoDescricao': 'Assédio',
        'gravidade': 'MEDIA',
        'situacao': 'PROCEDENTE',
        'origem': 'CONVERSA',
        'criadaEm': '2026-10-10T12:00:00Z',
        'prazoAnalise': '2026-10-13T12:00:00Z',
        'denunciante': {'nome': 'Ana', 'perfil': 'CURTIDOR'},
        'retrato': {'nome': 'Beto', 'temFoto': true},
        'atual': {'perfil': 'MUSICO', 'nome': 'Beto Silva', 'fotoOculta': false, 'suspensoAte': '2026-10-17T12:00:00Z'},
        'totalDoPerfil': 2,
        'pessoasDistintas': 2,
        'historico': [
          {'uuid': 'x0', 'tipoDescricao': 'Golpe', 'gravidade': 'MEDIA', 'situacao': 'ABERTA', 'criadaEm': '2026-10-09T12:00:00Z'},
        ],
        'decisao': {'procedente': true, 'acao': 'SUSPENSAO', 'diasSuspensao': 7, 'analisadaEm': '2026-10-10T13:00:00Z'},
      });
      expect(d.gravidade, GravidadeDenuncia.media);
      expect(d.aberta, isFalse);
      expect(d.denunciante, 'Ana');
      expect(d.retrato.temFoto, isTrue);
      expect(d.atual.suspensoAte, isNotNull);
      expect(d.historico.single.id, 'x0');
      expect(d.decisao!.acao, AcaoDenuncia.suspensao);
      expect(d.decisao!.diasSuspensao, 7);
    });

    test('corpo da decisão', () {
      expect(const DecisaoDenuncia.improcedente().toJson(), {'procedente': false, 'removerFoto': false, 'removerSobre': false});
      expect(
        const DecisaoDenuncia(procedente: true, acao: AcaoDenuncia.suspensao, diasSuspensao: 30, mensagemParaDenunciado: ' Oi ')
            .toJson(),
        {'procedente': true, 'acao': 'SUSPENSAO', 'removerFoto': false, 'removerSobre': false, 'diasSuspensao': 30,
          'mensagemParaDenunciado': 'Oi'},
      );
    });
  });
}
