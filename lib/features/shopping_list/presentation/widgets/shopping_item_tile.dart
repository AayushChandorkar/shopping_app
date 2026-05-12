import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../settings/presentation/provider/settings_provider.dart';
import '../../domain/entities/shopping_item.dart';

class ShoppingItemTile extends ConsumerWidget {
  final ShoppingItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencySymbol = ref.watch(settingsProvider).currencySymbol;
    return Slidable(
      key: ValueKey(item.id),
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: AppColors.info,
            foregroundColor: Colors.white,
            icon: Icons.edit_rounded,
            label: 'Edit',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: Icons.delete_rounded,
            label: 'Delete',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: item.isChecked
              ? AppColors.checkedOverlayColor(context)
              : AppColors.surfaceColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isChecked
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.borderColor(context),
          ),
          boxShadow: item.isChecked ? [] : AppColors.cardShadow(context),
        ),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _buildCheckbox(context),
                const Gap(12),
                Expanded(child: _buildContent(context, currencySymbol)),
                const Gap(12),
                _buildPrice(context, currencySymbol),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: item.isChecked ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: item.isChecked
              ? AppColors.primary
              : AppColors.borderColor(context),
          width: 2,
        ),
      ),
      child: item.isChecked
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
          : null,
    );
  }

  Widget _buildContent(BuildContext context, String currencySymbol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: item.isChecked
                ? AppColors.textSecondaryColor(context)
                : AppColors.textPrimaryColor(context),
            decoration: item.isChecked ? TextDecoration.lineThrough : null,
            decorationColor: AppColors.textSecondaryColor(context),
          ),
        ),
        const Gap(3),
        Text(
          '${_formatQty(item.quantity)} × $currencySymbol${item.price.toStringAsFixed(2)}',
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: AppColors.textSecondaryColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildPrice(BuildContext context, String currencySymbol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$currencySymbol${item.totalPrice.toStringAsFixed(2)}',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: item.isChecked
                ? AppColors.textSecondaryColor(context)
                : AppColors.primary,
          ),
        ),
      ],
    );
  }

  String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) return qty.toInt().toString();
    return qty.toString();
  }
}
