import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF4CAF82);
  static const Color primaryDark = Color(0xFF2E7D5A);
  static const Color primaryLight = Color(0xFFE8F5EE);

  static const Color background = Color(0xFFF6F7F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F2F5);

  static const Color textPrimary = Color(0xFF1A1D23);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFADB5BD);

  static const Color success = Color(0xFF4CAF82);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF42A5F5);

  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  static const Color checkedOverlay = Color(0x1A4CAF82);

  static Color backgroundColor(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color surfaceColor(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color surfaceVariantColor(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;

  static Color textPrimaryColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color textSecondaryColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  static Color textHintColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.72);

  static Color borderColor(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant;

  static Color dividerColor(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.45);

  static Color checkedOverlayColor(BuildContext context) =>
      primary.withValues(
        alpha: Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.10,
      );

  static Color primarySoftColor(BuildContext context) => primary.withValues(
    alpha: Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.12,
  );

  static List<BoxShadow> cardShadow(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return const [];
    }

    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }
}
