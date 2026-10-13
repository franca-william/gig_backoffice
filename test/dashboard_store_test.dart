import 'package:flutter_test/flutter_test.dart';

import 'package:gig_backoffice/data/mock/mock_dashboard.dart';
import 'package:gig_backoffice/data/models/dashboard.dart';
import 'package:gig_backoffice/features/dashboard/dashboard_store.dart';

import 'helpers.dart';

void main() {
  late MockDashboardRepository repo;
  late DashboardStore store;

  setUp(() {
    repo = MockDashboardRepository(relogio: () => agoraFixo);
    store = DashboardStore(repo);
  });

  List<String> chamadas() => repo.chamadas.map((c) => c.toString()).toList();

  test('carrega só a aba aberta, e voltar para ela não recarrega', () async {
    await store.abrir(AbaDashboard.atencao, 30);
    expect(chamadas(), ['atencao:-']);

    await store.abrir(AbaDashboard.marketplace, 30);
    await store.abrir(AbaDashboard.atencao, 30);
    await store.abrir(AbaDashboard.marketplace, 30);

    expect(chamadas(), ['atencao:-', 'marketplace:30']);
    expect(store.estado(AbaDashboard.crescimento).carregada, isFalse);
    expect(store.estado(AbaDashboard.marketplace).dado, isA<Marketplace>());
  });

  test('trocar o período recarrega a aba atual; as outras recarregam quando forem abertas', () async {
    await store.abrir(AbaDashboard.crescimento, 30);
    await store.abrir(AbaDashboard.marketplace, 30);
    await store.abrir(AbaDashboard.marketplace, 7);
    expect(chamadas().last, 'marketplace:7');
    expect(store.estado(AbaDashboard.marketplace).periodo, 7);

    await store.abrir(AbaDashboard.crescimento, 7);
    expect(chamadas().last, 'crescimento:7');
  });

  test('a aba Pontos de atenção não depende do período', () async {
    await store.abrir(AbaDashboard.atencao, 30);
    await store.abrir(AbaDashboard.atencao, 90);
    expect(chamadas(), ['atencao:-']);
  });

  test('Atualizar ignora o cache (atualizar=true)', () async {
    await store.abrir(AbaDashboard.qualidade, 90);
    await store.atualizar();
    expect(chamadas(), ['qualidade:90', 'qualidade:90:atualizar']);
  });

  test('erro e tentar de novo', () async {
    repo.falhar.add(AbaDashboard.curtidores);
    await store.abrir(AbaDashboard.curtidores, 30);
    expect(store.atual.erro, isNotNull);
    expect(store.atual.carregada, isFalse);

    repo.falhar.clear();
    await store.tentarDeNovo();
    expect(store.atual.erro, isNull);
    expect(store.atual.dado, isA<Curtidores>());
  });

  test('o contador é o total da aba Pontos de atenção', () async {
    expect(store.contador.value, 0);
    await store.atualizarContador();
    expect(store.contador.value, 6);
  });

  test('carregando mantém os números antigos até chegar o período novo', () async {
    await store.abrir(AbaDashboard.marketplace, 30);
    final pedido = store.abrir(AbaDashboard.marketplace, 90);
    expect(store.atual.carregando, isTrue);
    expect(store.atual.dado, isA<Marketplace>());
    await pedido;
    expect(store.atual.carregando, isFalse);
    expect((store.atual.dado! as Marketplace).periodo, 90);
  });

  test('sair limpa tudo', () async {
    await store.abrir(AbaDashboard.marketplace, 7);
    store.limpar();
    expect(store.aba.value, AbaDashboard.atencao);
    expect(store.periodo.value, 30);
    expect(store.estado(AbaDashboard.marketplace).carregada, isFalse);
  });
}
