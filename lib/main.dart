import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/themes/app_colors.dart';
import 'features/shopping_list/presentation/ui/shopping_list_screen.dart';
import 'features/settings/presentation/ui/settings_screen.dart';
import 'features/search/presentation/ui/search_screen.dart';
import 'features/shopping_list/presentation/ui/product_detail_screen.dart';
import 'features/settings/presentation/provider/settings_provider.dart';

void main() {
  runApp(const ProviderScope(child: SmartShopApp()));
}

class SmartShopApp extends ConsumerWidget {
  const SmartShopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Smart Shop',
      debugShowCheckedModeBanner: false,
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      initialRoute: '/',

      onGenerateRoute: (routeSettings) {
        switch (routeSettings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (_) => const ShoppingListScreen(),
            );
          case '/settings':
            return MaterialPageRoute(builder: (_) => const SettingsScreen());
          case '/search':
            return MaterialPageRoute(builder: (_) => const SearchScreen());
          case '/product-detail':
            final productId = routeSettings.arguments as String?;
            if (productId == null) {
              return MaterialPageRoute(
                builder: (_) => const ShoppingListScreen(),
              );
            }
            return MaterialPageRoute(
              builder: (_) => ProductDetailScreen(productId: productId),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const ShoppingListScreen(),
            );
        }
      },
    );
  }

  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.dmSansTextTheme(),
      dividerColor: colorScheme.outlineVariant,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF15181D),
      surfaceContainerHighest: const Color(0xFF20242B),
      onSurface: const Color(0xFFF5F7FA),
      onSurfaceVariant: const Color(0xFFB0B7C3),
      outlineVariant: const Color(0xFF343A45),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0E1116),
      textTheme: GoogleFonts.dmSansTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
      dividerColor: colorScheme.outlineVariant,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0E1116),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
