import '../models/dashboard.dart';
import '../repositories/repositories.dart';
import 'mock_repositories.dart';

/// Uma chamada feita ao repositório (os testes conferem o que foi carregado).
class ChamadaDashboard {
  const ChamadaDashboard(this.aba, this.periodo, this.atualizar);

  final AbaDashboard aba;
  final int? periodo;
  final bool atualizar;

  @override
  String toString() => '${aba.url}:${periodo ?? '-'}${atualizar ? ':atualizar' : ''}';
}

/// Números de exemplo em todas as abas (inclusive pontos de atenção vermelhos), para rodar sem backend.
/// Passa pelos mesmos `fromJson` da API.
class MockDashboardRepository implements DashboardRepository {
  MockDashboardRepository({Relogio? relogio, this.semPendencias = false}) : _agora = relogio ?? DateTime.now;

  final Relogio _agora;

  /// Aba Pontos de atenção sem nada pendente.
  bool semPendencias;

  /// Abas que respondem com erro (simula a API fora do ar).
  final Set<AbaDashboard> falhar = {};

  final List<ChamadaDashboard> chamadas = [];

  Future<Map<String, dynamic>> _responder(AbaDashboard aba, int? periodo, bool atualizar,
      Map<String, dynamic> Function() corpo) async {
    chamadas.add(ChamadaDashboard(aba, periodo, atualizar));
    await Future<void>.delayed(Duration.zero);
    if (falhar.contains(aba)) throw const BackofficeException('Não foi possível carregar.');
    return corpo();
  }

  String _iso(DateTime d) => d.toIso8601String();

  Map<String, dynamic> _ind(num? valor, num? anterior, {bool taxa = false}) {
    final v = valor?.toDouble();
    final a = anterior?.toDouble();
    double r(double x) => (x * 10).roundToDouble() / 10;
    return {
      if (v != null) 'valor': r(v),
      if (a != null) 'anterior': r(a),
      if (!taxa && v != null && a != null && a != 0) 'variacaoPercentual': r((v - a) * 100 / a),
      if (taxa && v != null && a != null) 'variacaoPontos': r(v - a),
      'novo': v != null && v != 0 && (a == null || (!taxa && a == 0)),
    };
  }

  @override
  Future<Atencao> atencao() async {
    final agora = _agora();
    final json = await _responder(AbaDashboard.atencao, null, false, () {
      if (semPendencias) {
        return {
          'geradoEm': _iso(agora.toUtc()),
          'total': 0,
          'cartoes': <String, dynamic>{},
          'eventosEmRisco': <Object>[],
          'contratos': <Object>[],
        };
      }
      Map<String, dynamic> evento(String id, String titulo, int horas, String casa, String situacao, int propostas) {
        final inicio = agora.add(Duration(hours: horas));
        return {
          'uuid': id,
          'titulo': titulo,
          'inicio': _iso(DateTime(inicio.year, inicio.month, inicio.day, inicio.hour)),
          'casa': casa,
          'cidade': 'Fortaleza',
          'estado': 'CE',
          'contato': '${casa.toLowerCase().replaceAll(' ', '.')}@exemplo.com',
          'situacao': situacao,
          'propostasPendentes': propostas,
          'horasParaComecar': horas,
          'critico': horas <= 48,
        };
      }

      return {
        'geradoEm': _iso(agora.toUtc()),
        'total': 6,
        'cartoes': {
          'sugestoesSemResposta': 2,
          'sugestoesAtrasadas': 1,
          'eventosEmRisco': 3,
          'eventosCriticos': 1,
          'contratosSemAssinatura': 0,
          'contratosTravados': 1,
        },
        'eventosEmRisco': [
          evento('e1', 'Sexta do Samba', 30, 'Bar do Zé', 'ABERTO', 2),
          evento('e2', 'Rock na Laje', 76, 'Pub Rock', 'SEM_MUSICO', 0),
          evento('e3', 'Jazz ao Pôr do Sol', 140, 'Casa Azul', 'RESERVADO', 0),
        ],
        'contratos': [
          {
            'numero': 'GIG-2026-000042',
            'tipo': 'TRAVADO',
            'situacao': 'GERANDO',
            'evento': 'Noite do Forró',
            'inicioEvento': _iso(agora.add(const Duration(days: 9))),
            'casa': 'Casa Azul',
            'musico': 'Trio Pé de Serra',
            'desde': _iso(agora.subtract(const Duration(minutes: 25)).toUtc()),
            'faltaAssinar': <String>[],
          },
        ],
      };
    });
    return Atencao.fromJson(json);
  }

  @override
  Future<Marketplace> marketplace(int periodo, {bool atualizar = false}) async {
    final f = periodo / 30;
    final json = await _responder(AbaDashboard.marketplace, periodo, atualizar, () => {
          'geradoEm': _iso(_agora().toUtc()),
          'periodo': periodo,
          'cartoes': {
            'taxaPreenchimento': _ind(72.5, 64.0, taxa: true),
            'tempoAteFecharHoras': _ind(36, 52),
            'propostasPorEvento': _ind(3.4, 2.9),
            'eventosSemProposta': _ind(12.5, 18.0, taxa: true),
            'aceitePropostas': _ind(41.2, 38.0, taxa: true),
            'aceiteConvites': _ind(68.0, null, taxa: true),
            'canceladosAntesDoMusico': _ind(6.0, 4.5, taxa: true),
            'canceladosDepoisDeConfirmado': _ind(2.0, 0.0, taxa: true),
            'eventosComMusicoProprio': _ind((9 * f).round(), (7 * f).round()),
          },
          'funil': {
            'criados': (48 * f).round(),
            'comProposta': (42 * f).round(),
            'confirmados': (35 * f).round(),
            'realizados': (29 * f).round(),
          },
          'porEstilo': [
            {'estilo': 'Samba', 'eventos': 14, 'preenchidos': 12, 'taxaPreenchimento': 85.7,
              'cacheMinimoMediana': 800.0, 'cacheMaximoMediana': 1200.0, 'cachePagoMediana': 1000.0},
            {'estilo': 'Rock', 'eventos': 10, 'preenchidos': 7, 'taxaPreenchimento': 70.0,
              'cacheMinimoMediana': 600.0, 'cacheMaximoMediana': 900.0, 'cachePagoMediana': 750.0},
            {'estilo': 'Pagode', 'eventos': 8, 'preenchidos': 4, 'taxaPreenchimento': 50.0,
              'cacheMinimoMediana': 700.0, 'cacheMaximoMediana': 1000.0, 'cachePagoMediana': 950.0},
            {'estilo': 'Jazz', 'eventos': 6, 'preenchidos': 3, 'taxaPreenchimento': 50.0,
              'cacheMinimoMediana': 900.0, 'cacheMaximoMediana': 1500.0},
          ],
        });
    return Marketplace.fromJson(json);
  }

  @override
  Future<Crescimento> crescimento(int periodo, {bool atualizar = false}) async {
    final agora = _agora();
    final segunda = DateTime(agora.year, agora.month, agora.day).subtract(Duration(days: agora.weekday - 1));
    final json = await _responder(AbaDashboard.crescimento, periodo, atualizar, () => {
          'geradoEm': _iso(agora.toUtc()),
          'periodo': periodo,
          'porPerfil': {
            'MUSICO': {'novos': _ind(18, 12), 'total': 240, 'ativos': 96, 'percentualAtivos': 40.0},
            'ESTABELECIMENTO': {'novos': _ind(5, 6), 'total': 61, 'ativos': 38, 'percentualAtivos': 62.3},
            'CURTIDOR': {'novos': _ind(132, 0), 'total': 1850, 'ativos': 610, 'percentualAtivos': 33.0},
          },
          'semanas': [
            for (var i = 11; i >= 0; i--)
              {
                'inicio': _iso(segunda.subtract(Duration(days: 7 * i))).substring(0, 10),
                'musicos': 2 + (11 - i) % 4,
                'estabelecimentos': (11 - i) % 3,
                'curtidores': 10 + (11 - i) * 3,
                'eventos': 6 + (11 - i) % 5,
              },
          ],
          'cidades': [
            {'cidade': 'Fortaleza', 'estado': 'CE', 'musicos': 150, 'estabelecimentos': 40, 'curtidores': 1200,
              'eventosFuturos': 22},
            {'cidade': 'Recife', 'estado': 'PE', 'musicos': 50, 'estabelecimentos': 12, 'curtidores': 400,
              'eventosFuturos': 6},
            {'cidade': 'Natal', 'estado': 'RN', 'musicos': 40, 'estabelecimentos': 9, 'curtidores': 250,
              'eventosFuturos': 0},
          ],
        });
    return Crescimento.fromJson(json);
  }

  @override
  Future<Curtidores> curtidores(int periodo, {bool atualizar = false}) async {
    final agora = _agora();
    final json = await _responder(AbaDashboard.curtidores, periodo, atualizar, () => {
          'geradoEm': _iso(agora.toUtc()),
          'periodo': periodo,
          'cartoes': {
            'vou': _ind(820, 640),
            'fui': _ind(410, 350),
            'conversaoVouFui': _ind(50.0, 54.7, taxa: true),
            'eventosComPublico': _ind(78.0, 70.0, taxa: true),
            'curtidoresAtivos': 610,
            'curtidoresTotal': 1850,
            'percentualAtivos': 33.0,
          },
          'estilos': [
            {'estilo': 'Pagode', 'curtidores': 340, 'eventosFuturos': 2, 'destaque': true},
            {'estilo': 'Samba', 'curtidores': 300, 'eventosFuturos': 14, 'destaque': true},
            {'estilo': 'Rock', 'curtidores': 120, 'eventosFuturos': 10, 'destaque': false},
            {'estilo': 'Jazz', 'curtidores': 60, 'eventosFuturos': 6, 'destaque': false},
          ],
          'topCasas': [
            {'casa': 'Bar do Zé', 'cidade': 'Fortaleza', 'estado': 'CE', 'eventos': 6, 'publico': 210},
            {'casa': 'Pub Rock', 'cidade': 'Fortaleza', 'estado': 'CE', 'eventos': 4, 'publico': 150},
          ],
          'topEventos': [
            {'uuid': 'f1', 'titulo': 'Sexta do Samba', 'inicio': _iso(agora.add(const Duration(days: 2))),
              'casa': 'Bar do Zé', 'cidade': 'Fortaleza', 'estado': 'CE', 'vou': 85},
            {'uuid': 'f2', 'titulo': 'Rock na Laje', 'inicio': _iso(agora.add(const Duration(days: 5))),
              'casa': 'Pub Rock', 'cidade': 'Fortaleza', 'estado': 'CE', 'vou': 40},
          ],
        });
    return Curtidores.fromJson(json);
  }

  @override
  Future<Qualidade> qualidade(int periodo, {bool atualizar = false}) async {
    final json = await _responder(AbaDashboard.qualidade, periodo, atualizar, () => {
          'geradoEm': _iso(_agora().toUtc()),
          'periodo': periodo,
          'notas': [
            {'tipo': 'CASA_AVALIOU_MUSICO', 'media': _ind(4.5, 4.4), 'quantidade': _ind(40, 32)},
            {'tipo': 'MUSICO_AVALIOU_CASA', 'media': _ind(4.1, 4.3), 'quantidade': _ind(35, 30)},
            {'tipo': 'CURTIDOR_AVALIOU_CASA', 'media': _ind(4.6, null), 'quantidade': _ind(120, 0)},
          ],
          'eventosAvaliados': {
            'eventos': 29,
            'pelaCasa': _ind(72.4, 65.0, taxa: true),
            'peloMusico': _ind(58.6, 60.0, taxa: true),
          },
          'contratos': {'gerados': 35, 'assinados': 31, 'percentualAssinados': _ind(88.6, 90.0, taxa: true)},
          'conversas': {
            'solicitacoes': _ind(210, 180),
            'percentualAceitas': 61.0,
            'percentualRecusadas': 14.3,
            'percentualSemResposta': 9.5,
          },
          'distribuicao': [
            {'tipo': 'CASA_AVALIOU_MUSICO', 'notas': [1, 1, 3, 10, 25]},
            {'tipo': 'MUSICO_AVALIOU_CASA', 'notas': [2, 2, 4, 12, 15]},
            {'tipo': 'CURTIDOR_AVALIOU_CASA', 'notas': [3, 2, 5, 30, 80]},
          ],
          'alertas': [
            {'nome': 'Casa do Samba', 'perfil': 'ESTABELECIMENTO', 'cidade': 'Recife', 'estado': 'PE', 'media': 2.3,
              'quantidade': 4, 'ultimoComentario': 'Pagamento atrasou de novo.'},
            {'nome': 'Duda Voz', 'perfil': 'MUSICO', 'cidade': 'Natal', 'estado': 'RN', 'media': 2.7,
              'quantidade': 3, 'ultimoComentario': 'Chegou 1 hora atrasado.'},
          ],
        });
    return Qualidade.fromJson(json);
  }
}
