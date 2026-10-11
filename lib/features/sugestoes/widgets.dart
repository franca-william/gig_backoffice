import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../data/models/models.dart';

/// Pílula colorida (situação e prazo).
class Etiqueta extends StatelessWidget {
  const Etiqueta({super.key, required this.texto, required this.cor, this.preenchida = false});

  final String texto;
  final Color cor;
  final bool preenchida;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: preenchida ? cor : cor.withAlpha(26),
        borderRadius: GigRadius.pillAll,
        border: Border.all(color: cor.withAlpha(preenchida ? 255 : 115)),
      ),
      child: Text(
        texto.toUpperCase(),
        style: GigTypography.tag.copyWith(color: preenchida ? GigColors.text : cor),
      ),
    );
  }
}

class EtiquetaSituacao extends StatelessWidget {
  const EtiquetaSituacao({super.key, required this.situacao});

  final SituacaoSugestao situacao;

  @override
  Widget build(BuildContext context) {
    final cor = switch (situacao) {
      SituacaoSugestao.recebida => GigColors.info,
      SituacaoSugestao.emAnalise => GigColors.primary,
      SituacaoSugestao.respondida => GigColors.success,
    };
    return Etiqueta(texto: situacao.rotulo, cor: cor);
  }
}

/// "Atrasada" (vermelha) quando passou de 2 dias sem resposta; "Vence hoje" (âmbar) no último dia.
class EtiquetaPrazo extends StatelessWidget {
  const EtiquetaPrazo({super.key, required this.prazo});

  final Prazo prazo;

  @override
  Widget build(BuildContext context) {
    return switch (prazo) {
      Prazo.atrasada => const Etiqueta(texto: 'Atrasada', cor: GigColors.danger, preenchida: true),
      Prazo.venceHoje => const Etiqueta(texto: 'Vence hoje', cor: GigColors.primary),
      Prazo.noPrazo => const SizedBox.shrink(),
    };
  }
}
