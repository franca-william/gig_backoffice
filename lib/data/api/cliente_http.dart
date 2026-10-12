// No navegador o cliente precisa de `withCredentials` para o cookie da sessão atravessar a porta no dev
// (localhost:5173 → localhost:8080). Fora do navegador (testes) usa o cliente padrão.
export 'cliente_http_padrao.dart' if (dart.library.js_interop) 'cliente_http_web.dart';
