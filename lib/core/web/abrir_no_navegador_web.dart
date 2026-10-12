import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

String? ultimoEnderecoAberto;

/// Abre o arquivo (ex.: PDF do documento) numa aba nova, a partir dos bytes já baixados com o token: o arquivo nunca
/// tem URL no servidor. O endereço `blob:` some quando a aba do backoffice fecha.
void abrirBytesEmNovaAba(Uint8List bytes, String contentType) {
  final blob = web.Blob(<JSAny>[bytes.toJS].toJS, web.BlobPropertyBag(type: contentType));
  final endereco = web.URL.createObjectURL(blob);
  ultimoEnderecoAberto = endereco;
  web.window.open(endereco, '_blank');
}

/// Endereço externo (ex.: consulta pública do CNPJ na Receita), sem passar a origem para o outro site.
void abrirEnderecoEmNovaAba(String endereco) {
  ultimoEnderecoAberto = endereco;
  web.window.open(endereco, '_blank', 'noopener,noreferrer');
}
