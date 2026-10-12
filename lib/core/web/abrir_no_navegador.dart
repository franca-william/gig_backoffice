// Abre um PDF (bytes) ou um endereço externo numa aba nova. No navegador usa `package:web`; fora dele (testes) não
// faz nada.
export 'abrir_no_navegador_padrao.dart' if (dart.library.js_interop) 'abrir_no_navegador_web.dart';
