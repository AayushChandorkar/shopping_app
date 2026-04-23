import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../settings/presentation/provider/settings_provider.dart';
import '../../../shopping_list/domain/entities/shopping_item.dart';

class SearchResultTile extends ConsumerWidget {
  final ShoppingItem item;
  final VoidCallback onAddToList;
  final VoidCallback onViewDetail;

  const SearchResultTile({
    super.key,
    required this.item,
    required this.onAddToList,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final currencySymbol = settings.currencySymbol;
    final currencyIcon = settings.currencyIcon;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          
          Expanded(
            child: InkWell(
              onTap: onViewDetail,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Gap(4),
                    Row(
                      children: [
                        _Chip(
                          '${_formatQty(item.quantity)} ${item.quantity == 1 ? 'item' : 'items'}',
                          Icons.numbers_rounded,
                        ),
                        const Gap(8),
                        _Chip(
                          '$currencySymbol${item.price.toStringAsFixed(2)}',
                          currencyIcon,
                        ),
                        const Gap(8),
                        if (item.isChecked)
                          _Chip('Checked', Icons.check_circle_rounded,
                              color: AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          
          Container(width: 1, height: 48, color: AppColors.border),

          
          InkWell(
            onTap: onAddToList,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                children: [
                  const Icon(
                    Icons.add_shopping_cart_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const Gap(3),
                  Text(
                    'Add',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatQty(double qty) =>
      qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _Chip(this.label, this.icon, {this.color = AppColors.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const Gap(3),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}