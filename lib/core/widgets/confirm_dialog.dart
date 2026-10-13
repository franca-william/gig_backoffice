import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'gig_button.dart';

/// Diálogo de confirmação centralizado (ex.: "Sair da conta").
/// Retorna `true` se o usuário confirmou.
Future<bool> showGigConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: GigColors.scrim,
    builder: (context) => Dialog(
      backgroundColor: GigColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 25),
      shape: const RoundedRectangleBorder(
        borderRadius: GigRadius.card,
        side: BorderSide(color: GigColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.all(GigSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: GigTypography.h2.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: GigSpacing.sm),
              Text(message, textAlign: TextAlign.center, style: GigTypography.bodyMuted),
              const SizedBox(height: GigSpacing.lg),
              destructive
                  ? GigButton.danger(label: confirmLabel, onPressed: () => Navigator.of(context).pop(true))
                  : GigButton(
                      label: confirmLabel,
                      size: GigButtonSize.medium,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
              const SizedBox(height: GigSpacing.sm),
              GigButton.outline(label: cancelLabel, onPressed: () => Navigator.of(context).pop(false)),
            ],
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}
