import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../settings/presentation/provider/settings_provider.dart';
import '../provider/shopping_list_provider.dart';
import '../widgets/add_item_bottom_sheet.dart';
import '../widgets/empty_list_view.dart';
import '../widgets/shopping_item_tile.dart';
import '../widgets/summary_bar.dart';

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  PopupMenuItem<String> _sortMenuItem(
    BuildContext context,
    String value,
    IconData icon,
    String currentSort,
  ) {
    final isSelected = currentSort == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected
                ? AppColors.primary
                : AppColors.textSecondaryColor(context),
          ),
          const Gap(12),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textPrimaryColor(context),
            ),
          ),
          const Spacer(),
          if (isSelected)
            const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shoppingListProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, ref),
          if (state.items.isNotEmpty) ...[
            _buildSummaryBar(ref),
            _buildFilterChips(context, ref, state),
            _buildList(context, ref, state),
          ] else
            const SliverFillRemaining(child: EmptyListView()),
        ],
      ),
      floatingActionButton: _buildFAB(context, ref),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.backgroundColor(context),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          '🛒 Smart Shop',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryColor(context),
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
        ),
      ),
      actions: [
        Consumer(
          builder: (context, ref, _) {
            final currentSort = ref.watch(activeSortProvider);
            final currencyIcon = ref.watch(settingsProvider).currencyIcon;
            return PopupMenuButton<String>(
              icon: const Icon(Icons.sort_rounded, color: Colors.white70),
              tooltip: 'Sort',
              color: AppColors.surfaceColor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                ref.read(activeSortProvider.notifier).state = value;
              },
              itemBuilder: (_) => [
                _sortMenuItem(
                  context,
                  'Date Added',
                  Icons.calendar_today_rounded,
                  currentSort,
                ),
                _sortMenuItem(
                  context,
                  'Name',
                  Icons.sort_by_alpha_rounded,
                  currentSort,
                ),
                _sortMenuItem(
                  context,
                  'Price',
                  currencyIcon,
                  currentSort,
                ),
              ],
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white70),
          onPressed: () => Navigator.pushNamed(context, '/search'),
          tooltip: 'Search',
        ),
        IconButton(
          icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white70),
          onPressed: () => _showClearDialog(context, ref),
          tooltip: 'Clear checked',
        ),
        IconButton(
          icon: const Icon(Icons.settings_rounded, color: Colors.white70),
          onPressed: () => Navigator.pushNamed(context, '/settings'),
          tooltip: 'Settings',
        ),
        const Gap(8),
      ],
    );
  }

  Widget _buildSummaryBar(WidgetRef ref) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: SummaryBar(),
      ),
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    WidgetRef ref,
    ShoppingListState state,
  ) {
    final filters = ['All', 'Pending', 'Checked'];
    final selected = ref.watch(activeFilterProvider);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: filters.map((filter) {
            final isSelected = selected == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  filter,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondaryColor(context),
                  ),
                ),
                selected: isSelected,
                onSelected: (_) =>
                    ref.read(activeFilterProvider.notifier).state = filter,
                backgroundColor: AppColors.surfaceColor(context),
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.borderColor(context),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    ShoppingListState state,
  ) {
    final filtered = ref.watch(filteredItemsProvider);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      sliver: SliverList.separated(
        itemCount: filtered.length,
        separatorBuilder: (context, index) => const Gap(8),
        itemBuilder: (context, index) {
          final item = filtered[index];
          return ShoppingItemTile(
            key: ValueKey(item.id),
            item: item,
            onToggle: () =>
                ref.read(shoppingListProvider.notifier).toggleItem(item.id),
            onDelete: () =>
                ref.read(shoppingListProvider.notifier).removeItem(item.id),
            onEdit: () => _showEditSheet(context, ref, item),
          );
        },
      ),
    );
  }

  Widget _buildFAB(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddSheet(context, ref),
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: Text(
        'Add Item',
        style: GoogleFonts.dmSans(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddItemBottomSheet(),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddItemBottomSheet(existingItem: item),
    );
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceColor(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear Checked Items',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryColor(ctx),
          ),
        ),
        content: Text(
          'Remove all checked items from your list?',
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
              ref.read(shoppingListProvider.notifier).clearChecked();
              Navigator.pop(ctx);
            },
            child: Text(
              'Clear',
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
