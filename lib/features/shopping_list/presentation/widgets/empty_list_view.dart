import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

import '../../../../core/themes/app_colors.dart';

class EmptyListView extends StatelessWidget {
  const EmptyListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primarySoftColor(context),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const Gap(20),
          Text(
            'Your list is empty',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryColor(context),
            ),
          ),
          const Gap(8),
          Text(
            'Tap the + button to add\nyour first shopping item',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.textSecondaryColor(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
