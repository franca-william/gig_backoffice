import 'package:flutter/material.dart';

import '../../../core/formatar.dart';
import '../../../core/theme/theme.dart';
import '../../../data/models/dashboard.dart';
import '../widgets/blocos.dart';
import '../widgets/cartao.dart';
import '../widgets/graficos.dart';

const _corDoPerfil = {
  PerfilDashboard.musico: CoresGrafico.principal,
  PerfilDashboard.estabelecimento: CoresGrafico.comparacao,
  PerfilDashboard.curtidor: CoresGrafico.comparacao2,
};

/// Aba 3 — "A base está crescendo e está ativa?"
class CrescimentoAba extends StatelessWidget {
  const CrescimentoAba({super.key, required this.dados});

  final Crescimento dados;

  @override
  Widget build(BuildContext context) {
    if (dados.vazio && dados.semanas.every((s) => s.eventos == 0)) {
      return const VazioDaAba(texto: 'Ainda não há cadastros neste período.');
    }
    final rotulos = [for (final s in dados.semanas) Formatar.diaCurto(s.inicio)];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final perfil in PerfilDashboard.values) ...[
        Text(perfil.rotulo, style: GigTypography.sectionTitle.copyWith(color: GigColors.textSubtle)),
        const SizedBox(height: GigSpacing.sm),
        _cartoesDo(perfil, dados.perfil(perfil)),
        const SizedBox(height: GigSpacing.xl),
      ],
      LinhaDeBlocos(
        esquerda: Secao(
          titulo: 'Novos cadastros por semana',
          ajuda: 'Últimas 12 semanas (segunda a domingo, horário de Brasília).',
          child: GraficoDeLinhas(
            rotulosX: rotulos,
            series: [
              for (final p in PerfilDashboard.values)
                Serie(p.rotulo, _corDoPerfil[p]!, [for (final s in dados.semanas) s.de(p).toDouble()]),
            ],
          ),
        ),
        direita: Secao(
          titulo: 'Eventos criados por semana',
          ajuda: 'Últimas 12 semanas, pela data em que a casa criou o evento.',
          child: GraficoDeBarras(
            rotulosX: rotulos,
            series: [
              Serie('Eventos', CoresGrafico.principal, [for (final s in dados.semanas) s.eventos.toDouble()]),
            ],
          ),
        ),
      ),
      const SizedBox(height: GigSpacing.lg),
      Secao(
        titulo: 'Por cidade',
        ajuda: 'Top 10 cidades por cadastros (cidade do perfil) e os eventos futuros das casas de cada uma.',
        child: TabelaDashboard(
          vazio: 'Nenhuma cidade informada nos perfis ainda.',
          colunas: const [
            Coluna('Cidade', flex: 3),
            Coluna('Músicos', numerica: true),
            Coluna('Casas', numerica: true),
            Coluna('Curtidores', numerica: true),
            Coluna('Eventos futuros', numerica: true),
          ],
          linhas: [
            for (final c in dados.cidades)
              [
                c.nome,
                Formatar.numero(c.musicos),
                Formatar.numero(c.estabelecimentos),
                Formatar.numero(c.curtidores),
                Formatar.numero(c.eventosFuturos),
              ],
          ],
        ),
      ),
    ]);
  }

  Widget _cartoesDo(PerfilDashboard perfil, CrescimentoDoPerfil d) {
    final nome = perfil.rotulo.toLowerCase();
    return GradeDeCartoes(cartoes: [
      DashboardCartao(
        chave: 'novos-${perfil.api}',
        titulo: 'Novos no período',
        valor: valorDe(d.novos, (v) => Formatar.numero(v)),
        variacao: variacaoDe(d.novos, dados.periodo),
        ajuda: 'Cadastros de $nome feitos nos últimos ${dados.periodo} dias.',
      ),
      DashboardCartao(
        chave: 'total-${perfil.api}',
        titulo: 'Total cadastrado',
        valor: Formatar.numero(d.total),
        ajuda: 'Todos os $nome com conta hoje (sem as contas da equipe).',
      ),
      DashboardCartao(
        chave: 'ativos-${perfil.api}',
        titulo: 'Ativos (30 dias)',
        valor: Formatar.numero(d.ativos),
        ajuda: 'Entraram no app (login ou sessão renovada) nos últimos 30 dias. Contado desde a versão do '
            'dashboard: contas que não abriram o app depois disso ainda não aparecem.',
      ),
      DashboardCartao(
        chave: 'percentual-ativos-${perfil.api}',
        titulo: '% ativos',
        valor: d.percentualAtivos == null ? '—' : Formatar.percentual(d.percentualAtivos!),
        ajuda: 'Ativos nos últimos 30 dias ÷ total cadastrado.',
      ),
    ]);
  }
}
