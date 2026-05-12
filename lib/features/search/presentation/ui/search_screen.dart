import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../../core/themes/app_colors.dart';
import '../provider/search_provider.dart';
import '../../../shopping_list/presentation/provider/shopping_list_provider.dart';
import '../../../shopping_list/domain/entities/shopping_item.dart';
import '../widgets/search_empty_view.dart';
import '../widgets/search_result_widget_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider(query));

    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor(context),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimaryColor(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildSearchBar(context),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                'Results for "$query"',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textSecondaryColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Expanded(
            child: query.isEmpty
                ? const SearchEmptyView(isInitial: true)
                : resultsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Something went wrong',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textSecondaryColor(context),
                  ),
                ),
              ),
              data: (items) => items.isEmpty
                  ? const SearchEmptyView(isInitial: false)
                  : _buildResults(items),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        style: GoogleFonts.dmSans(
          fontSize: 15,
          color: AppColors.textPrimaryColor(context),
        ),
        decoration: InputDecoration(
          hintText: 'Search your shopping list...',
          hintStyle: GoogleFonts.dmSans(
            color: AppColors.textHintColor(context),
            fontSize: 15,
          ),
          filled: true,
          fillColor: AppColors.surfaceVariantColor(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textHintColor(context),
            size: 20,
          ),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: AppColors.textHintColor(context),
              size: 18,
            ),
            onPressed: () {
              _searchCtrl.clear();
              ref.read(searchQueryProvider.notifier).state = '';
            },
          )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).state = value;
        },
      ),
    );
  }

  Widget _buildResults(List<ShoppingItem> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      itemCount: items.length,
      separatorBuilder: (context, index) => const Gap(8),
      itemBuilder: (context, index) {
        final item = items[index];
        return SearchResultTile(
          item: item,
          onAddToList: () => _addToList(item),
          onViewDetail: () => Navigator.pushNamed(
            context,
            '/product-detail',
            arguments: item.id,
          ),
        );
      },
    );
  }

  void _addToList(ShoppingItem item) {
    ref.read(shoppingListProvider.notifier).addItem(
      name: item.name,
      quantity: item.quantity,
      price: item.price,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${item.name} added to list!',
          style: GoogleFonts.dmSans(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
