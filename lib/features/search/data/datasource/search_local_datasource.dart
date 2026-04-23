import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../shopping_list/data/model/shopping_item_model.dart';

class SearchLocalDataSource {
  final DatabaseHelper _dbHelper;

  SearchLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static const _table = 'shopping_items';

  Future<Database> get _db async => _dbHelper.database;

  Future<List<ShoppingItemModel>> searchItems(String query) async {
    final db = await _db;
    final trimmed = query.trim();

    if (trimmed.isEmpty) return [];

    final rows = await db.query(
      _table,
      where: 'name LIKE ?',
      whereArgs: ['%$trimmed%'],
      orderBy: 'created_at DESC',
    );

    return rows.map(ShoppingItemModel.fromMap).toList();
  }
}