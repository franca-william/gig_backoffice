import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'gig_button.dart';

/// Estado vazio (ex.: "Nenhum evento encontrado.").
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData? icon;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GigSpacing.huge, horizontal: GigSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 32, color: GigColors.textMuted),
            const SizedBox(height: GigSpacing.md),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: GigTypography.bodyLarge.copyWith(color: GigColors.textMuted),
          ),
          if (description != null) ...[
            const SizedBox(height: GigSpacing.xs),
            Text(description!, textAlign: TextAlign.center, style: GigTypography.small),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: GigSpacing.lg),
            GigButton.outline(label: actionLabel!, onPressed: onAction, expanded: false),
          ],
        ],
      ),
    );
  }
}
