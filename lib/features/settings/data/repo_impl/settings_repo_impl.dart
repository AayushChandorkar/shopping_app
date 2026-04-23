import '../../domain/repo/settings_repository.dart';
import '../datasource/settings_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _dataSource;

  SettingsRepositoryImpl({SettingsLocalDataSource? dataSource})
      : _dataSource = dataSource ?? SettingsLocalDataSource();

  @override
  Future<Map<String, String>> loadAll() => _dataSource.getAllSettings();

  @override
  Future<void> save(String key, String value) =>
      _dataSource.setValue(key, value);
}