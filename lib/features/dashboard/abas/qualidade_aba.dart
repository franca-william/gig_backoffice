import 'package:flutter/material.dart';

import '../../../core/formatar.dart';
import '../../../core/theme/theme.dart';
import '../../../data/models/dashboard.dart';
import '../widgets/blocos.dart';
import '../widgets/cartao.dart';
import '../widgets/graficos.dart';

const _corDoTipo = {
  TipoAvaliacaoDashboard.casaAvaliouMusico: CoresGrafico.principal,
  TipoAvaliacaoDashboard.musicoAvaliouCasa: CoresGrafico.comparacao,
  TipoAvaliacaoDashboard.curtidorAvaliouCasa: CoresGrafico.comparacao2,
};

/// Aba 5 — "As pessoas estão tendo boas experiências?"
class QualidadeAba extends StatelessWidget {
  const QualidadeAba({super.key, required this.dados});

  final Qualidade dados;

  @override
  Widget build(BuildContext context) {
    if (dados.vazio) return const VazioDaAba(texto: 'Ainda não há avaliações neste período.');
    final p = dados.periodo;
    final conversas = dados.conversas;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GradeDeCartoes(cartoes: [
        for (final n in dados.notas)
          DashboardCartao(
            chave: 'nota-${n.tipo.api}',
            titulo: 'Nota média · ${n.tipo.rotulo}',
            valor: valorDe(n.media, (v) => Formatar.numero(v, casas: 1)),
            variacao: variacaoDe(n.media, p),
            ajuda: 'Média das avaliações (${n.tipo.rotulo.toLowerCase()}) feitas no período: '
                '${Formatar.numero(n.quantidade.valor ?? 0)} avaliações.',
          ),
        DashboardCartao(
          chave: 'avaliados-pela-casa',
          titulo: 'Eventos avaliados pela casa',
          valor: valorDe(dados.eventosAvaliados.pelaCasa, Formatar.percentual),
          variacao: variacaoDe(dados.eventosAvaliados.pelaCasa, p),
          ajuda: 'Dos ${dados.eventosAvaliados.eventos} eventos do período com músico do GiG, em quantos a casa '
              'avaliou o músico (a avaliação é uma por par casa x músico).',
        ),
        DashboardCartao(
          chave: 'avaliados-pelo-musico',
          titulo: 'Eventos avaliados pelo músico',
          valor: valorDe(dados.eventosAvaliados.peloMusico, Formatar.percentual),
          variacao: variacaoDe(dados.eventosAvaliados.peloMusico, p),
          ajuda: 'Dos ${dados.eventosAvaliados.eventos} eventos do período com músico do GiG, em quantos o músico '
              'avaliou a casa.',
        ),
        DashboardCartao(
          chave: 'contratos-assinados',
          titulo: 'Contratos assinados',
          valor: valorDe(dados.contratos.percentualAssinados, Formatar.percentual),
          variacao: variacaoDe(dados.contratos.percentualAssinados, p),
          ajuda: 'Dos ${dados.contratos.gerados} contratos gerados no período, quantos foram assinados pelos dois '
              '(${dados.contratos.assinados}). Não conta os cancelados antes de assinar.',
        ),
        DashboardCartao(
          chave: 'conversas',
          titulo: 'Conversas entre curtidores',
          valor: valorDe(conversas.solicitacoes, (v) => Formatar.numero(v)),
          variacao: Variacao(
            [
              if (conversas.percentualAceitas != null) '${Formatar.percentual(conversas.percentualAceitas!)} aceitas',
              if (conversas.percentualRecusadas != null)
                '${Formatar.percentual(conversas.percentualRecusadas!)} recusadas',
              if (conversas.percentualSemResposta != null)
                '${Formatar.percentual(conversas.percentualSemResposta!)} sem resposta',
            ].join(' · '),
          ),
          ajuda: 'Solicitações de conversa enviadas no período. "Sem resposta" = pendentes há mais de 7 dias.',
        ),
      ]),
      const SizedBox(height: GigSpacing.lg),
      Secao(
        titulo: 'Notas baixas',
        ajuda: 'Músicos e casas com média abaixo de 3,0 e pelo menos 3 avaliações nos últimos 90 dias (o mínimo '
            'evita marcar alguém por uma nota só).',
        child: TabelaDashboard(
          vazio: 'Ninguém com nota baixa nos últimos 90 dias.',
          chaves: [for (var i = 0; i < dados.alertas.length; i++) 'alerta-$i'],
          colunas: const [
            Coluna('Nome', flex: 3),
            Coluna('Perfil', flex: 1),
            Coluna('Cidade', flex: 2),
            Coluna('Média', flex: 1, numerica: true),
            Coluna('Avaliações', flex: 1, numerica: true),
            Coluna('Último comentário', flex: 4),
          ],
          linhas: [
            for (final a in dados.alertas)
              [
                a.nome,
                a.perfilRotulo,
                a.cidade == null ? '—' : (a.estado == null ? a.cidade! : '${a.cidade}/${a.estado}'),
                Text(Formatar.numero(a.media, casas: 1),
                    style: GigTypography.body.copyWith(color: GigColors.danger, fontWeight: FontWeight.w600)),
                Formatar.numero(a.quantidade),
                a.ultimoComentario == null ? '—' : '“${a.ultimoComentario}”',
              ],
          ],
        ),
      ),
      const SizedBox(height: GigSpacing.lg),
      Secao(
        titulo: 'Distribuição das notas',
        ajuda: 'Quantidade de avaliações de 1 a 5 estrelas no período, por tipo.',
        child: GraficoDeBarras(
          rotulosX: const ['Nota 1', 'Nota 2', 'Nota 3', 'Nota 4', 'Nota 5'],
          series: [
            for (final tipo in TipoAvaliacaoDashboard.values)
              Serie(tipo.rotulo, _corDoTipo[tipo]!, [
                for (var nota = 0; nota < 5; nota++)
                  ((dados.distribuicao[tipo] ?? const <int>[]).length > nota ? dados.distribuicao[tipo]![nota] : 0)
                      .toDouble(),
              ]),
          ],
        ),
      ),
    ]);
  }
}
