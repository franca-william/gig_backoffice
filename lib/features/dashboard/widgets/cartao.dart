import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/formatar.dart';
import '../../../core/theme/theme.dart';
import '../../../data/models/dashboard.dart';

/// Cor do cartão: neutro, âmbar (pede atenção) ou vermelho (alerta).
enum CorCartao { neutro, ambar, vermelho }

extension on CorCartao {
  Color get borda => switch (this) {
        CorCartao.neutro => GigColors.border,
        CorCartao.ambar => GigColors.primary,
        CorCartao.vermelho => GigColors.danger,
      };
}

/// Variação já formatada para o cartão ("+12% vs. 30 dias anteriores", "novo").
class Variacao {
  const Variacao(this.texto, {this.melhorou});

  final String texto;

  /// true = melhorou (verde), false = piorou (vermelho), null = neutro.
  final bool? melhorou;
}

/// Formata a variação do [indicador] contra o período anterior. [maiorEhMelhor] = false para números em que
/// subir é ruim (cancelamentos, tempo até fechar, eventos sem proposta).
Variacao? variacaoDe(Indicador indicador, int periodo, {bool maiorEhMelhor = true}) {
  if (indicador.novo) return const Variacao('novo');
  final double v;
  final String unidade;
  if (indicador.variacaoPercentual != null) {
    v = indicador.variacaoPercentual!;
    unidade = '%';
  } else if (indicador.variacaoPontos != null) {
    v = indicador.variacaoPontos!;
    unidade = ' p.p.';
  } else {
    return null;
  }
  final sinal = v > 0 ? '+' : (v < 0 ? '-' : '');
  final texto = '$sinal${Formatar.compacto(v.abs())}$unidade vs. $periodo dias anteriores';
  return Variacao(texto, melhorou: v == 0 ? null : (v > 0) == maiorEhMelhor);
}

/// Cartão de indicador (nasceu vazio na E29; no E1 ganha [cor], [variacao] e a regra em [ajuda]).
class DashboardCartao {
  const DashboardCartao({
    required this.titulo,
    required this.valor,
    this.variacao,
    this.cor = CorCartao.neutro,
    this.ajuda,
    this.chave,
    this.destaque = false,
  });

  final String titulo;

  /// Já formatado ("72,5%", "36 h"). "—" quando não há dados.
  final String valor;
  final Variacao? variacao;
  final CorCartao cor;

  /// A regra do número em uma frase (ícone ⓘ).
  final String? ajuda;

  /// Sufixo das chaves de teste (`cartao-<chave>`).
  final String? chave;

  /// Cartão principal da aba (ocupa duas colunas).
  final bool destaque;
}

class CartaoIndicador extends StatelessWidget {
  const CartaoIndicador({super.key, required this.cartao});

  final DashboardCartao cartao;

  @override
  Widget build(BuildContext context) {
    final variacao = cartao.variacao;
    final corVariacao = switch (variacao?.melhorou) {
      true => GigColors.success,
      false => GigColors.danger,
      null => GigColors.textMuted,
    };
    return Container(
      key: cartao.chave == null ? null : Key('cartao-${cartao.chave}'),
      constraints: const BoxConstraints(minHeight: 128),
      padding: const EdgeInsets.all(GigSpacing.xl),
      decoration: BoxDecoration(
        color: GigColors.surface,
        borderRadius: GigRadius.card,
        border: Border.all(color: cartao.cor.borda, width: cartao.cor == CorCartao.neutro ? 1 : 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Expanded(
              child: Text(cartao.titulo.toUpperCase(),
                  style: GigTypography.fieldLabel, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            if (cartao.ajuda != null) Ajuda(texto: cartao.ajuda!, chave: cartao.chave),
          ]),
          const SizedBox(height: GigSpacing.md),
          Text(
            cartao.valor,
            style: GigTypography.display.copyWith(
                color: cartao.cor == CorCartao.vermelho ? GigColors.danger : GigColors.text,
                fontSize: cartao.destaque ? 40 : null),
          ),
          if (variacao != null) ...[
            const SizedBox(height: GigSpacing.xs),
            Text(variacao.texto, style: GigTypography.small.copyWith(color: corVariacao)),
          ],
        ],
      ),
    );
  }
}

/// Ícone ⓘ com a regra do número.
class Ajuda extends StatelessWidget {
  const Ajuda({super.key, required this.texto, this.chave});

  final String texto;
  final String? chave;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      key: chave == null ? null : Key('ajuda-$chave'),
      message: texto,
      triggerMode: TooltipTriggerMode.tap,
      preferBelow: true,
      child: Semantics(
        label: 'O que é este número',
        child: const Padding(
          padding: EdgeInsets.only(left: GigSpacing.xs),
          child: Icon(LucideIcons.info, size: 16, color: GigColors.textMuted),
        ),
      ),
    );
  }
}

/// Grade de cartões: 4 por linha a partir de ~1000 px de largura, 2 em telas médias e 1 nas estreitas.
/// O cartão [DashboardCartao.destaque] ocupa duas colunas.
class GradeDeCartoes extends StatelessWidget {
  const GradeDeCartoes({super.key, required this.cartoes});

  final List<DashboardCartao> cartoes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const espaco = GigSpacing.lg;
      final largura = constraints.maxWidth;
      final colunas = largura >= 960 ? 4 : (largura >= 560 ? 2 : 1);
      final coluna = (largura - espaco * (colunas - 1)) / colunas;
      return Wrap(
        spacing: espaco,
        runSpacing: espaco,
        children: [
          for (final c in cartoes)
            SizedBox(
              width: c.destaque && colunas > 1 ? coluna * 2 + espaco : coluna,
              child: CartaoIndicador(cartao: c),
            ),
        ],
      );
    });
  }
}

/// Formata o valor de um indicador; "—" sem dados.
String valorDe(Indicador i, String Function(double) formatar) => i.valor == null ? '—' : formatar(i.valor!);
