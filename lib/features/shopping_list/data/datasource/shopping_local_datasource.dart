import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../model/shopping_item_model.dart';

class ShoppingLocalDataSource {
  final DatabaseHelper _dbHelper;

  ShoppingLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static const _table = 'shopping_items';

  Future<Database> get _db async => _dbHelper.database;

  Future<List<ShoppingItemModel>> getAllItems() async {
    final db = await _db;
    final rows = await db.query(_table, orderBy: 'created_at DESC');
    return rows.map(ShoppingItemModel.fromMap).toList();
  }

  Future<void> insertItem(ShoppingItemModel model) async {
    final db = await _db;
    await db.insert(
      _table,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateItem(ShoppingItemModel model) async {
    final db = await _db;
    await db.update(
      _table,
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<void> toggleItem(String id) async {
    final db = await _db;
    await db.rawUpdate('''
      UPDATE $_table
      SET is_checked = CASE WHEN is_checked = 1 THEN 0 ELSE 1 END
      WHERE id = ?
    ''', [id]);
  }

  Future<void> deleteItem(String id) async {
    final db = await _db;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearCheckedItems() async {
    final db = await _db;
    await db.delete(_table, where: 'is_checked = ?', whereArgs: [1]);
  }

  Future<void> clearAllItems() async {
    final db = await _db;
    await db.delete(_table);
  }

  Future<ShoppingItemModel?> getItemById(String id) async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ShoppingItemModel.fromMap(rows.first);
  }
}