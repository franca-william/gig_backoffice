import 'package:flutter/material.dart';

import '../theme/theme.dart';

enum GigButtonVariant { primary, outline, danger, ghost }

enum GigButtonSize { large, medium, small }

/// Botão padrão do GIG.
///
/// - `primary`: âmbar, caixa alta, Roboto Slab (CTA principal, 48px).
/// - `outline`: fundo escuro com borda (ações secundárias, 40px).
/// - `danger`: vermelho (confirmar "Sair").
/// - `ghost`: só texto/ícone (ex.: link "Sair" no perfil).
class GigButton extends StatelessWidget {
  const GigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = GigButtonVariant.primary,
    this.size,
    this.icon,
    this.expanded = true,
    this.loading = false,
    this.alignStart = false,
  });

  const GigButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.size,
    this.icon,
    this.expanded = true,
    this.loading = false,
    this.alignStart = false,
  }) : variant = GigButtonVariant.outline;

  const GigButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.size,
    this.icon,
    this.expanded = true,
    this.loading = false,
    this.alignStart = false,
  }) : variant = GigButtonVariant.danger;

  const GigButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.size,
    this.icon,
    this.expanded = true,
    this.loading = false,
    this.alignStart = true,
  }) : variant = GigButtonVariant.ghost;

  final String label;
  final VoidCallback? onPressed;
  final GigButtonVariant variant;
  final GigButtonSize? size;
  final IconData? icon;
  final bool expanded;
  final bool loading;

  /// Alinha ícone + texto à esquerda (itens de menu do perfil).
  final bool alignStart;

  GigButtonSize get _size => size ?? (variant == GigButtonVariant.primary ? GigButtonSize.large : GigButtonSize.medium);

  double get _height => switch (_size) {
        GigButtonSize.large => GigSizes.buttonLarge,
        GigButtonSize.medium => GigSizes.buttonMedium,
        GigButtonSize.small => GigSizes.buttonSmall,
      };

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, BorderSide? side) = switch (variant) {
      GigButtonVariant.primary => (GigColors.primary, GigColors.onPrimary, null),
      GigButtonVariant.outline => (GigColors.background, GigColors.text, const BorderSide(color: GigColors.border)),
      GigButtonVariant.danger => (GigColors.danger, GigColors.text, null),
      GigButtonVariant.ghost => (Colors.transparent, GigColors.danger, null),
    };

    final TextStyle textStyle = switch (variant) {
      GigButtonVariant.primary =>
        _size == GigButtonSize.large ? GigTypography.buttonLarge : GigTypography.buttonMedium,
      GigButtonVariant.danger => GigTypography.buttonMedium,
      _ => GigTypography.buttonFlex,
    };

    final text = variant == GigButtonVariant.primary && _size == GigButtonSize.large ? label.toUpperCase() : label;
    final disabled = onPressed == null || loading;

    final content = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: alignStart ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: variant == GigButtonVariant.outline ? GigColors.textMuted : fg),
                const SizedBox(width: GigSpacing.md),
              ],
              // Flexible só quando há largura limitada; em Row sem limite
              // (ex.: trailing de cabeçalho) ele quebraria o layout.
              if (expanded)
                Flexible(
                  child: Text(text, style: textStyle.copyWith(color: fg), overflow: TextOverflow.ellipsis),
                )
              else
                Text(text, style: textStyle.copyWith(color: fg)),
            ],
          );

    return Opacity(
      opacity: disabled && !loading ? 0.5 : 1,
      child: SizedBox(
        height: _height,
        width: expanded ? double.infinity : null,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(borderRadius: GigRadius.button, side: side ?? BorderSide.none),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: disabled ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: GigSpacing.lg),
              child: Center(widthFactor: 1, child: content),
            ),
          ),
        ),
      ),
    );
  }
}
