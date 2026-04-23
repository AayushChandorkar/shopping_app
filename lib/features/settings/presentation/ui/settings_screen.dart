import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../shopping_list/presentation/provider/shopping_list_provider.dart';
import '../provider/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context); 

    return Scaffold(
      
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface, 
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: theme.colorScheme.onSurface), 
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('Appearance'),
          const Gap(10),
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            label: 'Dark Mode',
            trailing: Switch.adaptive(
              value: settings.isDarkMode,
              activeColor: AppColors.primary,
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).toggleDarkMode(),
            ),
          ),
          const Gap(8),
          _SectionHeader('Currency'),
          const Gap(10),
          ...['₹ INR', '\$ USD', '€ EUR', '£ GBP'].map(
                (currency) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SettingsTile(
                icon: Icons.currency_exchange_rounded,
                label: currency,
                trailing: Radio<String>(
                  value: currency,
                  groupValue: settings.currency,
                  activeColor: AppColors.primary,
                  onChanged: (v) async {
                    if (v == null || v == settings.currency) return;
                    final oldCurrency = settings.currency;
                    await ref
                        .read(settingsProvider.notifier)
                        .setCurrency(v);
                    await ref
                        .read(shoppingListProvider.notifier)
                        .convertAllPrices(oldCurrency, v);
                  },
                ),
              ),
            ),
          ),
          const Gap(8),
          _SectionHeader('Sorting'),
          const Gap(10),
          ...['Date Added', 'Name', 'Price'].map(
                (sort) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SettingsTile(
                icon: Icons.sort_rounded,
                label: sort,
                trailing: Radio<String>(
                  value: sort,
                  groupValue: settings.defaultSort,
                  activeColor: AppColors.primary,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setDefaultSort(v!),
                ),
              ),
            ),
          ),
          const Gap(24),
          Center(
            child: Text(
              'Smart Shop v1.0.0',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.4), 
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), 
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); 
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,        
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant, 
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 20),
        title: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface, 
          ),
        ),
        trailing: trailing,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}