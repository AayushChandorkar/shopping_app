import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../data/repo_impl/settings_repo_impl.dart';
import '../../domain/repo/settings_repository.dart';

class SettingsKeys {
  static const isDarkMode = 'is_dark_mode';
  static const currency = 'currency';
  static const defaultSort = 'default_sort';
}

class AppSettings {
  final bool isDarkMode;
  final String currency;
  final String defaultSort;

  const AppSettings({
    this.isDarkMode = false,
    this.currency = '₹ INR',
    this.defaultSort = 'Date Added',
  });

  AppSettings copyWith({
    bool? isDarkMode,
    String? currency,
    String? defaultSort,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      currency: currency ?? this.currency,
      defaultSort: defaultSort ?? this.defaultSort,
    );
  }

  factory AppSettings.fromMap(Map<String, String> map) {
    return AppSettings(
      isDarkMode: map[SettingsKeys.isDarkMode] == 'true',
      currency: map[SettingsKeys.currency] ?? '₹ INR',
      defaultSort: map[SettingsKeys.defaultSort] ?? 'Date Added',
    );
  }
}

class SettingsNotifier extends ChangeNotifier {
  final SettingsRepository _repo;
  AppSettings _settings = const AppSettings();
  bool _isLoaded = false;

  SettingsNotifier(this._repo) {
    _loadFromDb();
  }

  AppSettings get value => _settings;

  bool get isLoaded => _isLoaded;

  bool get isDarkMode => _settings.isDarkMode;

  String get currency => _settings.currency;

  String get defaultSort => _settings.defaultSort;

  String get currencySymbol => _settings.currency.split(' ').first;

  IconData get currencyIcon => currencyIconFor(_settings.currency);

  Future<void> _loadFromDb() async {
    final map = await _repo.loadAll();
    _settings = AppSettings.fromMap(map);
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _settings = _settings.copyWith(isDarkMode: !_settings.isDarkMode);
    await _repo.save(SettingsKeys.isDarkMode, _settings.isDarkMode.toString());
    notifyListeners();
  }

  Future<void> setCurrency(String currency) async {
    _settings = _settings.copyWith(currency: currency);
    await _repo.save(SettingsKeys.currency, currency);
    notifyListeners();
  }

  Future<void> setDefaultSort(String sort) async {
    _settings = _settings.copyWith(defaultSort: sort);
    await _repo.save(SettingsKeys.defaultSort, sort);
    notifyListeners();
  }
}

final settingsProvider = ChangeNotifierProvider<SettingsNotifier>(
  (ref) => SettingsNotifier(SettingsRepositoryImpl()),
);
