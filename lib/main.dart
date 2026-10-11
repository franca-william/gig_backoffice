import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'app/router.dart';
import 'app/sessao_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Usa o caminho da URL (/sugestoes/123), não o "#" — o Nginx devolve o index.html nas rotas.
  usePathUrlStrategy();
  // Produção: fontes empacotadas em assets/google_fonts (a CSP não deixa baixar do Google).
  if (kReleaseMode) GoogleFonts.config.allowRuntimeFetching = false;

  configurarDependencias();
  final sessao = getIt<SessaoStore>();
  // Tela de carregamento (web/index.html) fica visível enquanto tenta renovar pelo cookie.
  await sessao.restaurar();

  runApp(BackofficeApp(router: criarRouter(sessao, localInicial: _localPedido())));
}

/// Recarregar em /sugestoes/123 volta para lá (o redirect manda para /login se não houver sessão).
String _localPedido() {
  final uri = Uri.base;
  final caminho = uri.path.isEmpty || uri.path == '/' ? '/dashboard' : uri.path;
  return uri.query.isEmpty ? caminho : '$caminho?${uri.query}';
}
