import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gig_backoffice/data/api/backoffice_api.dart';
import 'package:gig_backoffice/data/repositories/repositories.dart';

http.Response _json(int status, Object corpo) =>
    http.Response(jsonEncode(corpo), status, headers: {'content-type': 'application/json'});

void main() {
  test('login guarda o access token só em memória e manda X-GiG-Backoffice', () async {
    final pedidos = <http.Request>[];
    final api = BackofficeApi(
      base: 'http://api',
      cliente: MockClient((req) async {
        pedidos.add(req);
        if (req.url.path == '/api/backoffice/sessao') {
          return _json(200, {'accessToken': 'a1', 'usuario': {'nome': 'Ana', 'login': 'a@gig.app'}});
        }
        return _json(200, {'nome': 'Ana', 'login': 'a@gig.app'});
      }),
    );

    await api.entrar('a@gig.app', '123456');
    await api.get('/api/backoffice/me');

    expect(pedidos.first.headers['X-GiG-Backoffice'], '1');
    expect(pedidos.first.headers.containsKey('Authorization'), isFalse);
    expect(pedidos.last.headers['Authorization'], 'Bearer a1');
    expect(pedidos.last.headers['X-GiG-Backoffice'], '1');
  });

  test('senha errada → CredenciaisInvalidasException', () async {
    final api = BackofficeApi(base: 'http://api', cliente: MockClient((_) async => _json(401, {'codigo': 'credenciais-invalidas'})));

    expect(() => api.entrar('a@gig.app', 'x'), throwsA(isA<CredenciaisInvalidasException>()));
  });

  test('401 renova pelo cookie uma vez e repete a chamada (sem Bearer na renovação)', () async {
    var chamadas = 0;
    String? authNaRenovacao = 'nao-chamada';
    final api = BackofficeApi(
      base: 'http://api',
      cliente: MockClient((req) async {
        if (req.url.path.endsWith('/renovacao')) {
          authNaRenovacao = req.headers['Authorization'];
          return _json(200, {'accessToken': 'novo', 'usuario': {'nome': 'Ana'}});
        }
        chamadas++;
        return req.headers['Authorization'] == 'Bearer novo' ? _json(200, {'ok': true}) : _json(401, {});
      }),
    );

    final corpo = await api.get('/api/backoffice/sugestoes/contagem');

    expect(corpo['ok'], isTrue);
    expect(chamadas, 1); // sem token: renovou antes da primeira chamada
    expect(authNaRenovacao, isNull);
  });

  test('renovação falhou → avisa que expirou e lança SessaoExpiradaException', () async {
    var expirou = false;
    final api = BackofficeApi(base: 'http://api', cliente: MockClient((_) async => _json(401, {})))
      ..aoExpirar = () => expirou = true;

    await expectLater(api.get('/api/backoffice/me'), throwsA(isA<SessaoExpiradaException>()));
    expect(expirou, isTrue);
  });

  test('409 sugestao-ja-respondida vira SugestaoJaRespondidaException', () async {
    final api = BackofficeApi(
      base: 'http://api',
      cliente: MockClient((req) async => req.url.path.endsWith('/renovacao')
          ? _json(200, {'accessToken': 't'})
          : _json(409, {'codigo': 'sugestao-ja-respondida', 'detail': 'Esta sugestão já foi respondida.'})),
    );

    expect(() => api.post('/api/backoffice/sugestoes/x/resposta', corpo: {'texto': 'oi'}),
        throwsA(isA<SugestaoJaRespondidaException>()));
  });
}
