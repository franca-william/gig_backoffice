import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Rótulo de status em caixa alta (ex.: ABERTO em azul, CONFIRMADO em âmbar).
class StatusTag extends StatelessWidget {
  const StatusTag({super.key, required this.label, this.color = GigColors.info});

  const StatusTag.aberto({super.key})
      : label = 'Aberto',
        color = GigColors.info;

  const StatusTag.confirmado({super.key})
      : label = 'Confirmado',
        color = GigColors.primary;

  const StatusTag.encerrado({super.key})
      : label = 'Encerrado',
        color = GigColors.textMuted;

  const StatusTag.cancelado({super.key})
      : label = 'Cancelado',
        color = GigColors.danger;

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(), style: GigTypography.tag.copyWith(color: color));
  }
}

/// Selo âmbar preenchido usado sobre imagens (tema da festa).
class ThemeBadge extends StatelessWidget {
  const ThemeBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const BoxDecoration(color: GigColors.primary, borderRadius: GigRadius.pillAll),
      child: Text(
        label.toUpperCase(),
        style: GigTypography.tag.copyWith(color: GigColors.onPrimary, fontWeight: FontWeight.w700, letterSpacing: 0.8),
      ),
    );
  }
}
