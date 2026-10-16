// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// E34 — a marca é sempre "GiG" (e "GiGs" no plural): nunca "GIG", "Gig" ou "gig" em texto que o usuário lê.
/// Este teste lê todo `.dart` de `lib/`, tira as strings literais e falha se achar a marca escrita errado.
/// Só identificadores técnicos (rota, valor de JSON, esquema `gig://`, e-mails de mock) ficam de fora, nas listas abaixo.

final _marca = RegExp(r'\b[Gg][Ii][Gg][Ss]?\b');

/// Pedaços técnicos removidos antes de conferir.
const _trechosTecnicos = ['@gig.', 'gig://'];

/// Literal inteiro permitido, por arquivo (identificadores que o usuário não lê).
const _literaisTecnicos = <String, Set<String>>{};

class _Ctx {
  _Ctx.texto(this.aspas, this.raw, this.inicio) : interpolacao = false;
  _Ctx.interpolacao()
      : interpolacao = true,
        aspas = '',
        raw = false,
        inicio = 0;

  final bool interpolacao;
  final String aspas;
  final bool raw;
  final int inicio;
  int profundidade = 1;
  final buffer = StringBuffer();
}

class _Literal {
  _Literal(this.linha, this.texto);
  final int linha;
  final String texto;
}

/// Extrai as strings literais (ignora comentários; a parte `${...}` de interpolação fica de fora).
List<_Literal> _literais(String src) {
  final saida = <_Literal>[];
  final pilha = <_Ctx>[];
  var i = 0;
  var linha = 1;
  while (i < src.length) {
    final c = src[i];
    if (c == '\n') linha++;
    final topo = pilha.isEmpty ? null : pilha.last;
    if (topo == null || topo.interpolacao) {
      if (src.startsWith('//', i)) {
        final j = src.indexOf('\n', i);
        i = j < 0 ? src.length : j;
        continue;
      }
      if (src.startsWith('/*', i)) {
        var j = src.indexOf('*/', i + 2);
        j = j < 0 ? src.length : j + 2;
        linha += '\n'.allMatches(src.substring(i, j)).length;
        i = j;
        continue;
      }
      if (topo != null) {
        if (c == '{') {
          topo.profundidade++;
        } else if (c == '}') {
          topo.profundidade--;
          if (topo.profundidade == 0) pilha.removeLast();
          i++;
          continue;
        }
      }
      if (c == "'" || c == '"') {
        final raw = i > 0 && src[i - 1] == 'r' && (i < 2 || !RegExp(r'[A-Za-z0-9_]').hasMatch(src[i - 2]));
        final aspas = src.startsWith(c * 3, i) ? c * 3 : c;
        pilha.add(_Ctx.texto(aspas, raw, linha));
        i += aspas.length;
        continue;
      }
      i++;
      continue;
    }
    if (src.startsWith(topo.aspas, i)) {
      saida.add(_Literal(topo.inicio, topo.buffer.toString()));
      pilha.removeLast();
      i += topo.aspas.length;
      continue;
    }
    if (!topo.raw && c == r'\') {
      topo.buffer.write(' ');
      i += 2;
      continue;
    }
    if (!topo.raw && src.startsWith(r'${', i)) {
      topo.buffer.write(' ');
      pilha.add(_Ctx.interpolacao());
      i += 2;
      continue;
    }
    topo.buffer.write(c);
    i++;
  }
  return saida;
}

/// Trechos de [texto] com a marca escrita errado (vazio = ok). [arquivo] só entra na lista de exceções.
List<String> _marcasErradas(String arquivo, String texto) {
  if (_literaisTecnicos[arquivo]?.contains(texto) ?? false) return const [];
  var limpo = texto;
  for (final t in _trechosTecnicos) {
    limpo = limpo.replaceAll(t, ' ');
  }
  return [
    for (final m in _marca.allMatches(limpo))
      if (m[0] != 'GiG' && m[0] != 'GiGs') m[0]!,
  ];
}

String _norm(String caminho) => caminho.replaceAll('\\', '/');

void main() {
  test('nenhuma string literal de lib/ escreve a marca errado', () {
    final erros = <String>[];
    final arquivos = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    expect(arquivos, isNotEmpty);
    for (final f in arquivos) {
      final caminho = _norm(f.path);
      for (final l in _literais(f.readAsStringSync())) {
        for (final errada in _marcasErradas(caminho, l.texto)) {
          erros.add('$caminho:${l.linha}: "$errada" em "${l.texto.trim()}" — o nome é sempre GiG (plural GiGs)');
        }
      }
    }
    expect(erros, isEmpty, reason: '\n${erros.join('\n')}');
  });

  test('o leitor ignora comentários e pega texto dentro de interpolação', () {
    const fonte = "// Gig no comentário\n"
        "final a = 'Oi \${x ? 'Gig' : \"GiG\"} fim'; /* gig */\n"
        "final b = 'GiGs abertas';\n";
    final textos = _literais(fonte).map((l) => l.texto).toList();
    expect(textos, ['Gig', 'GiG', 'Oi   fim', 'GiGs abertas']);
    expect(_marcasErradas('x.dart', 'Gig'), ['Gig']);
    expect(_marcasErradas('x.dart', 'Ver gigs'), ['gigs']);
    expect(_marcasErradas('x.dart', 'GIG'), ['GIG']);
    expect(_marcasErradas('x.dart', 'GiG e GiGs'), isEmpty);
    expect(_marcasErradas('x.dart', 'musico@gig.com e gig://app'), isEmpty);
    expect(_marcasErradas('x.dart', 'gig_app e GigButton'), isEmpty);
  });

  test('título e descrição da aba do navegador usam GiG', () {
    final html = File('web/index.html').readAsStringSync();
    expect(RegExp(r'<title>(.*?)</title>').firstMatch(html)![1], contains('GiG'));
    final textos = [
      RegExp(r'<title>(.*?)</title>').firstMatch(html)![1]!,
      RegExp(r'<meta name="description" content="([^"]*)"').firstMatch(html)![1]!,
    ];
    final manifesto = jsonDecode(File('web/manifest.json').readAsStringSync()) as Map<String, dynamic>;
    textos.addAll([for (final c in ['name', 'short_name', 'description']) manifesto[c] as String]);
    for (final t in textos) {
      expect(_marcasErradas('', t), isEmpty, reason: t);
    }
  });
}
