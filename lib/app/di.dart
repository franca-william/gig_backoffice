import 'package:get_it/get_it.dart';

import '../data/api/api_denuncia_repository.dart';
import '../data/api/api_repositories.dart';
import '../data/api/api_verificacao_repository.dart';
import '../data/api/backoffice_api.dart';
import '../data/mock/mock_dashboard.dart';
import '../data/mock/mock_denuncias.dart';
import '../data/mock/mock_repositories.dart';
import '../data/mock/mock_verificacoes.dart';
import '../data/repositories/repositories.dart';
import '../features/dashboard/dashboard_store.dart';
import '../features/denuncias/denuncias_store.dart';
import '../features/sugestoes/sugestoes_store.dart';
import '../features/verificacoes/verificacoes_store.dart';
import 'sessao_store.dart';

final getIt = GetIt.instance;

/// Com `--dart-define=GIG_API=...` (dev) ou no build de produção (`--dart-define=GIG_MODO=api`) usa a API;
/// sem nenhum dos dois, os mocks (login `equipe@gig.app` / `123456`).
const bool usarApi =
    gigApiBase != '' || String.fromEnvironment('GIG_MODO') == 'api';

void configurarDependencias(
    {SessaoRepository? sessao,
    SugestaoRepository? sugestoes,
    DashboardRepository? dashboard,
    VerificacaoRepository? verificacoes,
    DenunciaRepository? denuncias,
    Relogio? relogio}) {
  getIt.allowReassignment = true;
  final agora = relogio ?? DateTime.now;
  getIt.registerSingleton<Relogio>(agora);

  if (sessao != null ||
      sugestoes != null ||
      dashboard != null ||
      verificacoes != null ||
      denuncias != null ||
      !usarApi) {
    getIt
      ..registerSingleton<SessaoRepository>(sessao ?? MockSessaoRepository())
      ..registerSingleton<SugestaoRepository>(
          sugestoes ?? MockSugestaoRepository(relogio: agora))
      ..registerSingleton<DashboardRepository>(
          dashboard ?? MockDashboardRepository(relogio: agora))
      ..registerSingleton<VerificacaoRepository>(
          verificacoes ?? MockVerificacaoRepository(relogio: agora))
      ..registerSingleton<DenunciaRepository>(
          denuncias ?? MockDenunciaRepository(relogio: agora));
  } else {
    final api = BackofficeApi();
    getIt
      ..registerSingleton<BackofficeApi>(api)
      ..registerSingleton<SessaoRepository>(ApiSessaoRepository(api))
      ..registerSingleton<SugestaoRepository>(ApiSugestaoRepository(api))
      ..registerSingleton<DashboardRepository>(ApiDashboardRepository(api))
      ..registerSingleton<VerificacaoRepository>(ApiVerificacaoRepository(api))
      ..registerSingleton<DenunciaRepository>(ApiDenunciaRepository(api));
  }

  final sessaoStore = SessaoStore(getIt());
  getIt
    ..registerSingleton<SessaoStore>(sessaoStore)
    ..registerSingleton<SugestoesStore>(SugestoesStore(getIt()))
    ..registerSingleton<DashboardStore>(DashboardStore(getIt()))
    ..registerSingleton<VerificacoesStore>(VerificacoesStore(getIt()))
    ..registerSingleton<DenunciasStore>(DenunciasStore(getIt()));

  if (getIt.isRegistered<BackofficeApi>()) {
    getIt<BackofficeApi>().aoExpirar = sessaoStore.expirou;
  }
}
