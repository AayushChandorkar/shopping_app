import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../settings/presentation/provider/settings_provider.dart';
import '../provider/shopping_list_provider.dart';

class SummaryBar extends ConsumerWidget {
  const SummaryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shoppingListProvider);
    final settings = ref.watch(settingsProvider);
    final currencySymbol = settings.currencySymbol;
    final currencyIcon = settings.currencyIcon;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatChip(
            label: 'Total',
            value: '${state.totalItems}',
            icon: Icons.shopping_cart_rounded,
          ),
          _Divider(),
          _StatChip(
            label: 'Pending',
            value: '${state.pendingItems}',
            icon: Icons.radio_button_unchecked_rounded,
          ),
          _Divider(),
          _StatChip(
            label: 'Done',
            value: '${state.checkedItems}',
            icon: Icons.check_circle_rounded,
          ),
          _Divider(),
          _StatChip(
            label: 'Cost',
            value: '$currencySymbol${state.totalPrice.toStringAsFixed(0)}',
            icon: currencyIcon,
            highlight: true,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
          const Gap(4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: highlight ? 15 : 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withOpacity(0.2),
    );
  }
}