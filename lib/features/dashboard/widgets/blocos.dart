import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/theme.dart';
import 'cartao.dart';

/// Cores dos gráficos (manual da marca): âmbar na série principal, cinzas para comparar, vermelho só em alerta.
abstract final class CoresGrafico {
  static const principal = GigColors.primary;
  static const comparacao = Color(0xFFB3B3B3);
  static const comparacao2 = Color(0xFF6B6B6B);
  static const alerta = GigColors.danger;
  static const grade = GigColors.border;
}

/// Bloco de largura cheia (ou meia, dentro de [LinhaDeBlocos]) com título e conteúdo.
class Secao extends StatelessWidget {
  const Secao({super.key, required this.titulo, this.ajuda, this.acao, required this.child});

  final String titulo;
  final String? ajuda;
  final Widget? acao;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GigSpacing.xl),
      decoration: BoxDecoration(
        color: GigColors.surface,
        borderRadius: GigRadius.card,
        border: Border.all(color: GigColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Flexible(child: Text(titulo, style: GigTypography.h2)),
          if (ajuda != null) Ajuda(texto: ajuda!),
          const Spacer(),
          if (acao != null) acao!,
        ]),
        const SizedBox(height: GigSpacing.lg),
        child,
      ]),
    );
  }
}

/// Dois blocos lado a lado em telas largas; um embaixo do outro nas estreitas.
class LinhaDeBlocos extends StatelessWidget {
  const LinhaDeBlocos({super.key, required this.esquerda, required this.direita});

  final Widget esquerda;
  final Widget direita;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 900) {
        return Column(children: [esquerda, const SizedBox(height: GigSpacing.lg), direita]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: esquerda),
        const SizedBox(width: GigSpacing.lg),
        Expanded(child: direita),
      ]);
    });
  }
}

/// Coluna de uma [TabelaDashboard].
class Coluna {
  const Coluna(this.titulo, {this.flex = 2, this.numerica = false});

  final String titulo;
  final int flex;
  final bool numerica;
}

/// Tabela simples (cabeçalho + linhas). Células são textos ou widgets.
class TabelaDashboard extends StatelessWidget {
  const TabelaDashboard({super.key, required this.colunas, required this.linhas, this.chaves, this.vazio});

  final List<Coluna> colunas;
  final List<List<Object>> linhas;

  /// Chave de cada linha (testes).
  final List<String>? chaves;

  /// Texto quando não há linhas.
  final String? vazio;

  Widget _celula(Object conteudo, Coluna coluna, TextStyle estilo) {
    final filho = conteudo is Widget
        ? conteudo
        : Text('$conteudo',
            style: estilo,
            textAlign: coluna.numerica ? TextAlign.right : TextAlign.left,
            maxLines: 2,
            overflow: TextOverflow.ellipsis);
    return Expanded(
      flex: coluna.flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: GigSpacing.xs),
        child: Align(alignment: coluna.numerica ? Alignment.centerRight : Alignment.centerLeft, child: filho),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (linhas.isEmpty && vazio != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: GigSpacing.md),
        child: Text(vazio!, style: GigTypography.bodyMuted),
      );
    }
    return Column(children: [
      Padding(
        padding: const EdgeInsets.only(bottom: GigSpacing.sm),
        child: Row(children: [
          for (final c in colunas) _celula(c.titulo.toUpperCase(), c, GigTypography.fieldLabel),
        ]),
      ),
      const Divider(height: 1),
      for (var i = 0; i < linhas.length; i++)
        Container(
          key: chaves == null ? null : Key(chaves![i]),
          padding: const EdgeInsets.symmetric(vertical: GigSpacing.md),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: GigColors.border))),
          child: Row(children: [
            for (var j = 0; j < colunas.length; j++) _celula(linhas[i][j], colunas[j], GigTypography.body),
          ]),
        ),
    ]);
  }
}

/// Item de [BarrasHorizontais].
class Barra {
  const Barra(this.rotulo, this.valor, {this.texto, this.cor = CoresGrafico.principal});

  final String rotulo;
  final double valor;

  /// Texto à direita (padrão: o valor).
  final String? texto;
  final Color cor;
}

/// Barras horizontais simples (funil, preenchimento por estilo). [maximo] padrão = maior valor.
class BarrasHorizontais extends StatelessWidget {
  const BarrasHorizontais({super.key, required this.barras, this.maximo, this.larguraRotulo = 160});

  final List<Barra> barras;
  final double? maximo;
  final double larguraRotulo;

  @override
  Widget build(BuildContext context) {
    final maior = maximo ??
        barras.fold<double>(0, (m, b) => b.valor > m ? b.valor : m);
    return Column(children: [
      for (final b in barras)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: GigSpacing.xs),
          child: Row(children: [
            SizedBox(
              width: larguraRotulo,
              child: Text(b.rotulo, style: GigTypography.body, overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              child: Container(
                height: 18,
                alignment: Alignment.centerLeft,
                decoration: const BoxDecoration(color: GigColors.surfaceHigh, borderRadius: GigRadius.pillAll),
                child: FractionallySizedBox(
                  widthFactor: maior <= 0 ? 0 : (b.valor / maior).clamp(0, 1).toDouble(),
                  child: Container(decoration: BoxDecoration(color: b.cor, borderRadius: GigRadius.pillAll)),
                ),
              ),
            ),
            SizedBox(
              width: 120,
              child: Text(b.texto ?? b.valor.toStringAsFixed(0),
                  textAlign: TextAlign.right, style: GigTypography.body.copyWith(fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
    ]);
  }
}

/// Legenda de cores dos gráficos.
class Legenda extends StatelessWidget {
  const Legenda({super.key, required this.itens});

  final Map<String, Color> itens;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: GigSpacing.lg, runSpacing: GigSpacing.xs, children: [
      for (final item in itens.entries)
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: item.value, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: GigSpacing.xs),
          Text(item.key, style: GigTypography.small),
        ]),
    ]);
  }
}

// ---------------------------------------------------------------------------------------------------- estados

/// Cartões cinza pulsando enquanto a aba carrega.
class EsqueletoDaAba extends StatefulWidget {
  const EsqueletoDaAba({super.key});

  @override
  State<EsqueletoDaAba> createState() => _EsqueletoDaAbaState();
}

class _EsqueletoDaAbaState extends State<EsqueletoDaAba> with SingleTickerProviderStateMixin {
  late final AnimationController _pulso =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Carregando',
      child: FadeTransition(
        key: const Key('dashboard-carregando'),
        opacity: Tween<double>(begin: 0.4, end: 1).animate(_pulso),
        child: LayoutBuilder(builder: (context, constraints) {
          final largura = (constraints.maxWidth - GigSpacing.lg * 3) / 4;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: GigSpacing.lg, runSpacing: GigSpacing.lg, children: [
              for (var i = 0; i < 4; i++) _bloco(largura < 200 ? constraints.maxWidth : largura, 128),
            ]),
            const SizedBox(height: GigSpacing.lg),
            _bloco(constraints.maxWidth, 240),
          ]);
        }),
      ),
    );
  }

  Widget _bloco(double largura, double altura) => Container(
        width: largura,
        height: altura,
        decoration: const BoxDecoration(color: GigColors.surfaceHigh, borderRadius: GigRadius.card),
      );
}

/// "Não foi possível carregar. Tentar de novo"
class ErroDaAba extends StatelessWidget {
  const ErroDaAba({super.key, required this.aoTentar});

  final VoidCallback aoTentar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GigSpacing.huge),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(LucideIcons.alertTriangle, size: 32, color: GigColors.danger),
          const SizedBox(height: GigSpacing.md),
          Text('Não foi possível carregar.', style: GigTypography.bodyLarge),
          const SizedBox(height: GigSpacing.md),
          OutlinedButton.icon(
            key: const Key('tentar-de-novo'),
            // O tema usa largura infinita (botões de formulário); aqui o botão fica do tamanho do texto.
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, GigSizes.buttonMedium)),
            onPressed: aoTentar,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Tentar de novo'),
          ),
        ]),
      ),
    );
  }
}

/// Texto de "sem dados" de cada aba.
class VazioDaAba extends StatelessWidget {
  const VazioDaAba({super.key, required this.texto, this.icone = LucideIcons.barChart2});

  final String texto;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GigSpacing.huge),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icone, size: 32, color: GigColors.textMuted),
          const SizedBox(height: GigSpacing.md),
          Text(texto,
              textAlign: TextAlign.center, style: GigTypography.bodyLarge.copyWith(color: GigColors.textMuted)),
        ]),
      ),
    );
  }
}
