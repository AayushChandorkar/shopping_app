import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';

class SettingsLocalDataSource {
  final DatabaseHelper _dbHelper;

  SettingsLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static const _table = 'settings';

  Future<Database> get _db async => _dbHelper.database;

  Future<String?> getValue(String key) async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> setValue(String key, String value) async {
    final db = await _db;
    await db.insert(
      _table,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, String>> getAllSettings() async {
    final db = await _db;
    final rows = await db.query(_table);
    return {
      for (final row in rows)
        row['key'] as String: row['value'] as String,
    };
  }
}