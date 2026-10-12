import 'dart:typed_data';

/// Fora do navegador (testes): só guarda o último pedido.
String? ultimoEnderecoAberto;

void abrirBytesEmNovaAba(Uint8List bytes, String contentType) => ultimoEnderecoAberto = 'blob:$contentType';

void abrirEnderecoEmNovaAba(String endereco) => ultimoEnderecoAberto = endereco;
