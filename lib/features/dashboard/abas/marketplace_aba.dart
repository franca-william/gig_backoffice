import 'package:flutter/material.dart';

import '../../../core/formatar.dart';
import '../../../core/theme/theme.dart';
import '../../../data/models/dashboard.dart';
import '../widgets/blocos.dart';
import '../widgets/cartao.dart';
import '../widgets/graficos.dart';

/// Aba 2 — "Casas e músicos estão se encontrando?"
class MarketplaceAba extends StatelessWidget {
  const MarketplaceAba({super.key, required this.dados});

  final Marketplace dados;

  @override
  Widget build(BuildContext context) {
    if (dados.vazio) return const VazioDaAba(texto: 'Ainda não há eventos neste período.');
    final p = dados.periodo;
    final f = dados.funil;
    final estilosComCache = dados.porEstilo
        .where((e) => e.cacheMinimoMediana != null || e.cacheMaximoMediana != null || e.cachePagoMediana != null)
        .toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GradeDeCartoes(cartoes: [
        DashboardCartao(
          chave: 'taxa-preenchimento',
          titulo: 'Taxa de preenchimento',
          destaque: true,
          valor: valorDe(dados.taxaPreenchimento, Formatar.percentual),
          variacao: variacaoDe(dados.taxaPreenchimento, p),
          ajuda: 'Dos eventos que aconteceram no período, quantos tinham músico confirmado. Não conta eventos '
              'com músico da casa ou artista de fora, nem os cancelados antes de começar.',
        ),
        DashboardCartao(
          chave: 'tempo-ate-fechar',
          titulo: 'Tempo até fechar',
          valor: valorDe(dados.tempoAteFecharHoras, Formatar.duracaoEmHoras),
          variacao: variacaoDe(dados.tempoAteFecharHoras, p, maiorEhMelhor: false),
          ajuda: 'Mediana do tempo entre criar o evento e o aceite (proposta ou convite) que confirmou o músico.',
        ),
        DashboardCartao(
          chave: 'propostas-por-evento',
          titulo: 'Propostas por evento',
          valor: valorDe(dados.propostasPorEvento, (v) => Formatar.numero(v, casas: 1)),
          variacao: variacaoDe(dados.propostasPorEvento, p),
          ajuda: 'Média de propostas recebidas pelos eventos criados no período.',
        ),
        DashboardCartao(
          chave: 'eventos-sem-proposta',
          titulo: 'Eventos sem proposta',
          valor: valorDe(dados.eventosSemProposta, Formatar.percentual),
          variacao: variacaoDe(dados.eventosSemProposta, p, maiorEhMelhor: false),
          ajuda: 'Eventos do período que não receberam nenhuma proposta e ficaram sem músico. Sinal de falta '
              'de músicos ou cachê baixo.',
        ),
        DashboardCartao(
          chave: 'aceite-propostas',
          titulo: 'Aceite de propostas',
          valor: valorDe(dados.aceitePropostas, Formatar.percentual),
          variacao: variacaoDe(dados.aceitePropostas, p),
          ajuda: 'Das propostas respondidas no período, quantas a casa aceitou.',
        ),
        DashboardCartao(
          chave: 'aceite-convites',
          titulo: 'Aceite de convites',
          valor: valorDe(dados.aceiteConvites, Formatar.percentual),
          variacao: variacaoDe(dados.aceiteConvites, p),
          ajuda: 'Dos convites respondidos no período (diretos e da vaga), quantos o músico aceitou.',
        ),
        DashboardCartao(
          chave: 'cancelados-antes',
          titulo: 'Cancelados antes do músico',
          valor: valorDe(dados.canceladosAntesDoMusico, Formatar.percentual),
          variacao: variacaoDe(dados.canceladosAntesDoMusico, p, maiorEhMelhor: false),
          ajuda: 'Dos eventos marcados para o período ou cancelados nele, quantos a casa cancelou antes de ter '
              'músico.',
        ),
        DashboardCartao(
          chave: 'cancelados-depois',
          titulo: 'Cancelados depois de confirmado',
          valor: valorDe(dados.canceladosDepoisDeConfirmado, Formatar.percentual),
          cor: (dados.canceladosDepoisDeConfirmado.valor ?? 0) > 0 ? CorCartao.vermelho : CorCartao.neutro,
          variacao: variacaoDe(dados.canceladosDepoisDeConfirmado, p, maiorEhMelhor: false),
          ajuda: 'Os mais graves: a casa cancelou com o músico já confirmado.',
        ),
        DashboardCartao(
          chave: 'musico-proprio',
          titulo: 'Eventos com músico próprio',
          valor: valorDe(dados.eventosComMusicoProprio, (v) => Formatar.numero(v)),
          variacao: variacaoDe(dados.eventosComMusicoProprio, p),
          ajuda: 'Eventos do período com músico da casa ou artista de fora do GiG. Ficam fora das taxas acima '
              'porque não passaram pelo marketplace.',
        ),
      ]),
      const SizedBox(height: GigSpacing.lg),
      LinhaDeBlocos(
        esquerda: Secao(
          titulo: 'Funil do período',
          ajuda: 'Eventos criados no período (sem os de músico próprio) e até onde chegaram.',
          child: BarrasHorizontais(barras: [
            Barra('Criados', f.criados.toDouble(), texto: Formatar.numero(f.criados)),
            Barra('Com proposta', f.comProposta.toDouble(),
                texto: _comPercentual(f.comProposta, f.criados), cor: CoresGrafico.comparacao),
            Barra('Confirmados', f.confirmados.toDouble(),
                texto: _comPercentual(f.confirmados, f.criados), cor: CoresGrafico.comparacao),
            Barra('Realizados', f.realizados.toDouble(),
                texto: _comPercentual(f.realizados, f.criados), cor: CoresGrafico.comparacao2),
          ]),
        ),
        direita: Secao(
          titulo: 'Preenchimento por estilo',
          ajuda: 'Taxa de preenchimento dos eventos do período, por estilo do evento. Mostra onde faltam músicos.',
          child: dados.porEstilo.isEmpty
              ? Text('Sem eventos no período.', style: GigTypography.bodyMuted)
              : BarrasHorizontais(maximo: 100, barras: [
                  for (final e in dados.porEstilo)
                    Barra(
                      e.estilo,
                      e.taxaPreenchimento ?? 0,
                      texto: e.taxaPreenchimento == null
                          ? '—'
                          : '${Formatar.percentual(e.taxaPreenchimento!)} (${e.preenchidos}/${e.eventos})',
                    ),
                ]),
        ),
      ),
      const SizedBox(height: GigSpacing.lg),
      Secao(
        titulo: 'Cachê por estilo',
        ajuda: 'Mediana do cachê mínimo e máximo pedidos pelas casas x mediana do cachê aceito (proposta ou '
            'convite), nos eventos do período.',
        child: estilosComCache.isEmpty
            ? Text('Sem cachês no período.', style: GigTypography.bodyMuted)
            : GraficoDeBarras(
                rotulosX: [for (final e in estilosComCache) e.estilo],
                series: [
                  Serie('Pedido (mínimo)', CoresGrafico.comparacao2,
                      [for (final e in estilosComCache) e.cacheMinimoMediana ?? 0]),
                  Serie('Pedido (máximo)', CoresGrafico.comparacao,
                      [for (final e in estilosComCache) e.cacheMaximoMediana ?? 0]),
                  Serie('Pago', CoresGrafico.principal, [for (final e in estilosComCache) e.cachePagoMediana ?? 0]),
                ],
              ),
      ),
    ]);
  }

  static String _comPercentual(int parte, int total) =>
      total == 0 ? Formatar.numero(parte) : '${Formatar.numero(parte)} · ${Formatar.percentual(parte * 100 / total)}';
}
