abstract class SettingsRepository {
  Future<Map<String, String>> loadAll();
  Future<void> save(String key, String value);
}