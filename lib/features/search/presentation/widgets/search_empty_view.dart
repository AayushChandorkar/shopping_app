import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

import '../../../../core/themes/app_colors.dart';

class SearchEmptyView extends StatelessWidget {
  final bool isInitial;

  const SearchEmptyView({super.key, required this.isInitial});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isInitial
                  ? Icons.search_rounded
                  : Icons.search_off_rounded,
              size: 42,
              color: AppColors.primary,
            ),
          ),
          const Gap(20),
          Text(
            isInitial ? 'Search your list' : 'No results found',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Gap(8),
          Text(
            isInitial
                ? 'Type a name to find items\nin your shopping list'
                : 'Try a different search term',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}