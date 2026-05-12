import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../provider/product_detail_provider.dart';
import '../provider/shopping_list_provider.dart';
import '../widgets/add_item_bottom_sheet.dart';
import '../../domain/entities/shopping_item.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../settings/presentation/provider/settings_provider.dart';
import '../widgets/detail_info_card.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productId = ModalRoute.of(context)!.settings.arguments as String;
    final itemAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      body: itemAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => _buildError(context, e.toString()),
        data: (item) {
          if (item == null) return _buildNotFound(context);
          return _buildDetail(context, ref, item);
        },
      ),
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref, ShoppingItem item) {
    final settings = ref.watch(settingsProvider);
    final currencySymbol = settings.currencySymbol;
    final currencyIcon = settings.currencyIcon;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            title: Text(
              item.name,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Gap(40),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_bag_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              onPressed: () => _showEditSheet(context, item),
              tooltip: 'Edit',
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Row(
              children: [
                _StatusBadge(isChecked: item.isChecked),
                const Spacer(),
                Text(
                  'Added ${_formatDate(item.createdAt)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              DetailInfoCard(
                label: 'Price per Item',
                value: '$currencySymbol${item.price.toStringAsFixed(2)}',
                icon: currencyIcon,
                color: AppColors.info,
              ),
              DetailInfoCard(
                label: 'Number of Items',
                value: _formatQty(item.quantity),
                icon: Icons.numbers_rounded,
                color: AppColors.warning,
              ),
              DetailInfoCard(
                label: 'Total Cost',
                value: '$currencySymbol${item.totalPrice.toStringAsFixed(2)}',
                icon: Icons.receipt_rounded,
                color: AppColors.primary,
              ),
              DetailInfoCard(
                label: 'Status',
                value: item.isChecked ? 'Purchased' : 'Pending',
                icon: item.isChecked
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: item.isChecked ? AppColors.success : AppColors.error,
              ),
            ],
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref
                          .read(shoppingListProvider.notifier)
                          .toggleItem(item.id);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.isChecked
                          ? AppColors.surfaceVariantColor(context)
                          : AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: Icon(
                      item.isChecked
                          ? Icons.remove_done_rounded
                          : Icons.check_rounded,
                      color: item.isChecked
                          ? AppColors.textSecondaryColor(context)
                          : Colors.white,
                    ),
                    label: Text(
                      item.isChecked ? 'Mark as Pending' : 'Mark as Purchased',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: item.isChecked
                            ? AppColors.textSecondaryColor(context)
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
                const Gap(12),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => _showDeleteDialog(context, ref, item),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.delete_rounded,
                      color: AppColors.error,
                    ),
                    label: Text(
                      'Remove from List',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 48,
          ),
          const Gap(16),
          Text(
            'Something went wrong',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryColor(context),
            ),
          ),
          const Gap(8),
          Text(
            message,
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondaryColor(context),
            ),
          ),
          const Gap(24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              'Go Back',
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            color: AppColors.textHintColor(context),
            size: 56,
          ),
          const Gap(16),
          Text(
            'Item not found',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryColor(context),
            ),
          ),
          const Gap(24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              'Go Back',
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, ShoppingItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddItemBottomSheet(existingItem: item),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    ShoppingItem item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceColor(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove Item',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryColor(ctx),
          ),
        ),
        content: Text(
          'Remove "${item.name}" from your list?',
          style: GoogleFonts.dmSans(color: AppColors.textSecondaryColor(ctx)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondaryColor(ctx),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              ref.read(shoppingListProvider.notifier).removeItem(item.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(
              'Remove',
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatQty(double qty) =>
      qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();
}

class _StatusBadge extends StatelessWidget {
  final bool isChecked;

  const _StatusBadge({required this.isChecked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isChecked
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isChecked
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isChecked ? Icons.check_circle_rounded : Icons.pending_rounded,
            size: 14,
            color: isChecked ? AppColors.primary : AppColors.warning,
          ),
          const Gap(6),
          Text(
            isChecked ? 'Purchased' : 'Pending',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isChecked ? AppColors.primary : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
