import 'package:flutter/material.dart';

import '../../../core/formatar.dart';
import '../../../core/theme/theme.dart';
import '../../../data/models/dashboard.dart';
import '../../sugestoes/widgets.dart';
import '../widgets/blocos.dart';
import '../widgets/cartao.dart';
import '../widgets/graficos.dart';

/// Aba 4 — "O app está levando público às casas?"
class CurtidoresAba extends StatelessWidget {
  const CurtidoresAba({super.key, required this.dados});

  final Curtidores dados;

  String _local(String? cidade, String? estado) =>
      cidade == null ? '—' : (estado == null ? cidade : '$cidade/$estado');

  @override
  Widget build(BuildContext context) {
    if (dados.vazio) return const VazioDaAba(texto: 'Ainda não há presenças neste período.');
    final p = dados.periodo;
    final destaques = dados.estilos.where((e) => e.destaque).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GradeDeCartoes(cartoes: [
        DashboardCartao(
          chave: 'vou',
          titulo: '"Vou" no período',
          valor: valorDe(dados.vou, (v) => Formatar.numero(v)),
          variacao: variacaoDe(dados.vou, p),
          ajuda: 'Marcações de "Vou" em eventos que começaram no período.',
        ),
        DashboardCartao(
          chave: 'fui',
          titulo: '"Fui" no período',
          valor: valorDe(dados.fui, (v) => Formatar.numero(v)),
          variacao: variacaoDe(dados.fui, p),
          ajuda: 'Confirmações de "Fui" nos eventos que aconteceram no período.',
        ),
        DashboardCartao(
          chave: 'conversao',
          titulo: 'Conversão Vou → Fui',
          valor: valorDe(dados.conversaoVouFui, Formatar.percentual),
          variacao: variacaoDe(dados.conversaoVouFui, p),
          ajuda: 'De quem marcou "Vou" em eventos que já aconteceram, quantos confirmaram "Fui".',
        ),
        DashboardCartao(
          chave: 'eventos-com-publico',
          titulo: 'Eventos com público',
          valor: valorDe(dados.eventosComPublico, Formatar.percentual),
          variacao: variacaoDe(dados.eventosComPublico, p),
          ajuda: 'Dos eventos que aconteceram no período, quantos tiveram pelo menos um "Vou". Argumento de '
              'venda para as casas.',
        ),
        DashboardCartao(
          chave: 'curtidores-ativos',
          titulo: 'Curtidores ativos',
          valor: Formatar.numero(dados.curtidoresAtivos),
          variacao: dados.percentualAtivos == null
              ? null
              : Variacao('${Formatar.percentual(dados.percentualAtivos!)} de '
                  '${Formatar.numero(dados.curtidoresTotal)} cadastrados'),
          ajuda: 'Entraram no app nos últimos 30 dias.',
        ),
      ]),
      const SizedBox(height: GigSpacing.lg),
      Secao(
        titulo: 'Procura x oferta por estilo',
        ajuda: 'Curtidores que seguem o estilo x eventos com o estilo nos próximos 30 dias. Destaque quando há '
            'muita procura e pouca oferta (20 ou mais curtidores por evento).',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (destaques.isNotEmpty) ...[
            for (final e in destaques)
              Padding(
                padding: const EdgeInsets.only(bottom: GigSpacing.sm),
                child: Row(children: [
                  const Etiqueta(texto: 'Oportunidade', cor: GigColors.primary),
                  const SizedBox(width: GigSpacing.sm),
                  Flexible(
                    child: Text(
                      '${e.estilo}: ${Formatar.numero(e.curtidores)} curtidores, '
                      '${e.eventosFuturos == 1 ? '1 evento' : '${e.eventosFuturos} eventos'} nos próximos 30 dias',
                      key: Key('destaque-${e.estilo}'),
                      style: GigTypography.body,
                    ),
                  ),
                ]),
              ),
            const SizedBox(height: GigSpacing.sm),
          ],
          if (dados.estilos.isEmpty)
            Text('Nenhum curtidor seguindo estilos ainda.', style: GigTypography.bodyMuted)
          else
            GraficoDeBarras(
              rotulosX: [for (final e in dados.estilos) e.estilo],
              series: [
                Serie('Curtidores', CoresGrafico.principal,
                    [for (final e in dados.estilos) e.curtidores.toDouble()]),
                Serie('Eventos (30 dias)', CoresGrafico.comparacao,
                    [for (final e in dados.estilos) e.eventosFuturos.toDouble()]),
              ],
            ),
        ]),
      ),
      const SizedBox(height: GigSpacing.lg),
      LinhaDeBlocos(
        esquerda: Secao(
          titulo: 'Top 10 casas por público',
          ajuda: 'Soma de "Vou" nos eventos de cada casa que aconteceram no período.',
          child: TabelaDashboard(
            vazio: 'Nenhuma casa com público no período.',
            colunas: const [
              Coluna('Casa', flex: 3),
              Coluna('Cidade', flex: 2),
              Coluna('Eventos', flex: 1, numerica: true),
              Coluna('Público', flex: 1, numerica: true),
            ],
            linhas: [
              for (final c in dados.topCasas)
                [c.casa, _local(c.cidade, c.estado), Formatar.numero(c.eventos), Formatar.numero(c.publico)],
            ],
          ),
        ),
        direita: Secao(
          titulo: 'Top 10 eventos futuros',
          ajuda: 'Eventos que ainda vão acontecer, pelo número de "Vou".',
          child: TabelaDashboard(
            vazio: 'Nenhum evento futuro com "Vou" ainda.',
            colunas: const [
              Coluna('Evento', flex: 3),
              Coluna('Quando', flex: 2),
              Coluna('Casa', flex: 2),
              Coluna('Vou', flex: 1, numerica: true),
            ],
            linhas: [
              for (final e in dados.topEventos)
                [
                  e.titulo,
                  e.inicio == null ? '—' : Formatar.dataHora(e.inicio!),
                  e.casa,
                  Formatar.numero(e.vou),
                ],
            ],
          ),
        ),
      ),
    ]);
  }
}
