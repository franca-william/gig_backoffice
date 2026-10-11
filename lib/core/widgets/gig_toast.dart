import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/theme.dart';

enum GigToastType { info, success, error }

/// Toast flutuante no rodapé (padrão do canvas: fundo #121212, borda, ícone + texto).
///
/// Usa um ScaffoldMessenger global, então o toast sobrevive à navegação
/// (ex.: "Você saiu da conta" aparece já na tela de onboarding).
abstract final class GigToast {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void show(String message, {GigToastType type = GigToastType.info}) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    final (IconData icon, Color color) = switch (type) {
      GigToastType.info => (LucideIcons.info, GigColors.text),
      GigToastType.success => (LucideIcons.checkCircle, GigColors.primary),
      GigToastType.error => (LucideIcons.alertCircle, GigColors.text),
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(16),
          content: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: GigTypography.body.copyWith(fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      );
  }

  static void success(String message) => show(message, type: GigToastType.success);
  static void error(String message) => show(message, type: GigToastType.error);
}
