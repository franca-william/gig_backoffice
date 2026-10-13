import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobx/mobx.dart';

import '../../../app/di.dart';
import '../../../app/rotas.dart';
import '../../../core/formatar.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/gig_toast.dart';
import '../../../data/mock/mock_repositories.dart';
import '../../../data/models/dashboard.dart';
import '../../../data/models/models.dart';
import '../../sugestoes/sugestoes_store.dart';
import '../../sugestoes/widgets.dart';
import '../widgets/blocos.dart';
import '../widgets/cartao.dart';

// Regras de cor dos cartões (testadas à parte).
CorCartao corSugestoesSemResposta(int n) => n > 0 ? CorCartao.ambar : CorCartao.neutro;
CorCartao corSugestoesAtrasadas(int n) => n > 0 ? CorCartao.vermelho : CorCartao.neutro;
CorCartao corEventosEmRisco(int total, int criticos) =>
    criticos > 0 ? CorCartao.vermelho : (total > 0 ? CorCartao.ambar : CorCartao.neutro);
CorCartao corContratosSemAssinatura(int n) => n > 0 ? CorCartao.ambar : CorCartao.neutro;
CorCartao corContratosTravados(int n) => n > 0 ? CorCartao.vermelho : CorCartao.neutro;

/// Aba 1 — "O que eu preciso resolver hoje?" Sempre a situação de agora.
class AtencaoAba extends StatelessWidget {
  const AtencaoAba({super.key, required this.dados});

  final Atencao dados;

  @override
  Widget build(BuildContext context) {
    final c = dados.cartoes;
    if (dados.vazia) {
      return const VazioDaAba(texto: 'Nada pedindo atenção agora ✅', icone: LucideIcons.checkCircle);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GradeDeCartoes(cartoes: [
        DashboardCartao(
          chave: 'sugestoes-sem-resposta',
          titulo: 'Sugestões sem resposta',
          valor: Formatar.numero(c.sugestoesSemResposta),
          cor: corSugestoesSemResposta(c.sugestoesSemResposta),
          ajuda: 'Sugestões recebidas ou em análise que ainda não foram respondidas.',
        ),
        DashboardCartao(
          chave: 'sugestoes-atrasadas',
          titulo: 'Sugestões atrasadas',
          valor: Formatar.numero(c.sugestoesAtrasadas),
          cor: corSugestoesAtrasadas(c.sugestoesAtrasadas),
          ajuda: 'Sem resposta há mais de 2 dias (o prazo prometido no app).',
        ),
        DashboardCartao(
          chave: 'eventos-em-risco',
          titulo: 'Eventos em risco',
          valor: Formatar.numero(c.eventosEmRisco),
          cor: corEventosEmRisco(c.eventosEmRisco, c.eventosCriticos),
          variacao: c.eventosCriticos > 0
              ? Variacao('${c.eventosCriticos} em até 48 h', melhorou: false)
              : null,
          ajuda: 'Começam nos próximos 7 dias e ainda estão sem músico (aberto, reservado ou sem músico). '
              'Vermelho quando algum começa em até 48 h.',
        ),
        DashboardCartao(
          chave: 'contratos-sem-assinatura',
          titulo: 'Contratos sem assinatura',
          valor: Formatar.numero(c.contratosSemAssinatura),
          cor: corContratosSemAssinatura(c.contratosSemAssinatura),
          ajuda: 'Pendentes ou com uma assinatura só, de eventos que começam em até 3 dias ou com o prazo '
              'de assinatura vencido.',
        ),
        DashboardCartao(
          chave: 'contratos-travados',
          titulo: 'Contratos travados',
          valor: Formatar.numero(c.contratosTravados),
          cor: corContratosTravados(c.contratosTravados),
          ajuda: 'Alerta técnico: o contrato está gerando o PDF há mais de 10 minutos.',
        ),
      ]),
      if (c.sugestoesAtrasadas > 0) ...[
        const SizedBox(height: GigSpacing.lg),
        _SugestoesAtrasadas(quantidade: c.sugestoesAtrasadas),
      ],
      const SizedBox(height: GigSpacing.lg),
      Secao(
        titulo: 'Eventos em risco',
        ajuda: 'Mais próximo primeiro. Copie o contato da casa para ajudar a fechar o músico.',
        child: TabelaDashboard(
          vazio: 'Nenhum evento dos próximos 7 dias está sem músico.',
          chaves: [for (final e in dados.eventosEmRisco) 'evento-${e.id}'],
          colunas: const [
            Coluna('Quando', flex: 2),
            Coluna('Evento', flex: 3),
            Coluna('Casa', flex: 3),
            Coluna('Situação', flex: 2),
            Coluna('Propostas', flex: 1, numerica: true),
            Coluna('', flex: 2, numerica: true),
          ],
          linhas: [
            for (final e in dados.eventosEmRisco)
              [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.inicio == null ? '—' : Formatar.dataHora(e.inicio!), style: GigTypography.body),
                  Text(Formatar.comecaEm(e.horasParaComecar),
                      style: GigTypography.small.copyWith(color: e.critico ? GigColors.danger : null)),
                ]),
                e.titulo,
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.casa, style: GigTypography.body, overflow: TextOverflow.ellipsis),
                  if (e.cidade != null)
                    Text(e.estado == null ? e.cidade! : '${e.cidade}/${e.estado}', style: GigTypography.small),
                ]),
                Etiqueta(
                    texto: e.situacaoRotulo,
                    cor: e.situacao == 'RESERVADO' ? GigColors.info : GigColors.primary),
                '${e.propostasPendentes}',
                TextButton.icon(
                  key: Key('copiar-contato-${e.id}'),
                  onPressed: () => _copiarContato(e),
                  icon: const Icon(LucideIcons.copy, size: 14),
                  label: const Text('Copiar contato da casa'),
                ),
              ],
          ],
        ),
      ),
      const SizedBox(height: GigSpacing.lg),
      Secao(
        titulo: 'Contratos sem assinatura ou travados',
        ajuda: 'Sem CPF, CNPJ ou dados do contrato: só o que a equipe precisa para cobrar a assinatura.',
        child: TabelaDashboard(
          vazio: 'Nenhum contrato com problema.',
          chaves: [for (final k in dados.contratos) 'contrato-${k.numero}'],
          colunas: const [
            Coluna('Contrato', flex: 2),
            Coluna('Evento', flex: 3),
            Coluna('Casa', flex: 2),
            Coluna('Músico', flex: 2),
            Coluna('Situação', flex: 2),
            Coluna('Falta', flex: 2),
          ],
          linhas: [
            for (final k in dados.contratos)
              [
                k.numero,
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(k.evento, style: GigTypography.body, overflow: TextOverflow.ellipsis),
                  if (k.inicioEvento != null) Text(Formatar.dataHora(k.inicioEvento!), style: GigTypography.small),
                ]),
                k.casa,
                k.musico,
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Etiqueta(
                      texto: k.travado ? 'Travado' : (k.situacao == 'PARCIAL' ? 'Parcial' : 'Pendente'),
                      cor: k.travado ? GigColors.danger : GigColors.primary,
                      preenchida: k.travado),
                  if (k.desde != null)
                    Padding(
                      padding: const EdgeInsets.only(top: GigSpacing.xxs),
                      child: Text(Formatar.ha(k.desde!, getIt<Relogio>()()), style: GigTypography.small),
                    ),
                ]),
                k.quemFalta,
              ],
          ],
        ),
      ),
    ]);
  }

  Future<void> _copiarContato(EventoEmRisco e) async {
    await Clipboard.setData(ClipboardData(text: e.contato));
    GigToast.success('Contato copiado: ${e.contato}');
  }
}

class _SugestoesAtrasadas extends StatelessWidget {
  const _SugestoesAtrasadas({required this.quantidade});

  final int quantidade;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: GigSpacing.xl, vertical: GigSpacing.md),
      decoration: BoxDecoration(
        color: GigColors.danger.withAlpha(26),
        borderRadius: GigRadius.card,
        border: Border.all(color: GigColors.danger.withAlpha(115)),
      ),
      child: Row(children: [
        const Icon(LucideIcons.alarmClock, size: 18, color: GigColors.danger),
        const SizedBox(width: GigSpacing.md),
        Expanded(
          child: Text(
            quantidade == 1
                ? '1 sugestão passou do prazo de 2 dias sem resposta.'
                : '$quantidade sugestões passaram do prazo de 2 dias sem resposta.',
            style: GigTypography.body,
          ),
        ),
        TextButton(
          key: const Key('ver-sugestoes-atrasadas'),
          onPressed: () {
            // "Sem resposta" já ordena pelo prazo: as atrasadas aparecem primeiro.
            runInAction(() => getIt<SugestoesStore>().filtro.value = const FiltroSugestoes());
            context.go(Rotas.sugestoes);
          },
          child: const Text('Ver na lista'),
        ),
      ]),
    );
  }
}
