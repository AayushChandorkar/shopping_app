import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';

/// A single cached entry for a barcode the user has previously saved.
class CachedProduct {
  final String barcode;
  final String name;
  final double price;
  final DateTime updatedAt;

  const CachedProduct({
    required this.barcode,
    required this.name,
    required this.price,
    required this.updatedAt,
  });

  factory CachedProduct.fromMap(Map<String, dynamic> row) {
    return CachedProduct(
      barcode: row['barcode'] as String,
      name: row['name'] as String,
      price: (row['price'] as num).toDouble(),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}

/// Local barcode -> {name, price} cache, populated from the user's own
/// submissions. The next time the same barcode is scanned, both fields
/// can be auto-filled with no network call.
class ProductCacheLocalDataSource {
  ProductCacheLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;
  static const _table = 'product_cache';

  Future<Database> get _db async => _dbHelper.database;

  /// Returns the cached entry for [barcode], or `null` if the user has
  /// never saved this barcode before.
  Future<CachedProduct?> getByBarcode(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return null;
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'barcode = ?',
      whereArgs: [trimmed],
      limit: 1,
    );
    if (rows.isEmpty) {
      debugPrint('[ProductCache] miss barcode=$trimmed');
      return null;
    }
    final hit = CachedProduct.fromMap(rows.first);
    debugPrint(
      '[ProductCache] hit barcode=${hit.barcode}, name="${hit.name}", '
      'price=${hit.price}, updatedAt=${hit.updatedAt.toIso8601String()}',
    );
    return hit;
  }

  /// Insert or overwrite the cache entry for [barcode]. The most recent
  /// submission always wins — prices change over time and the user's last
  /// entry is the freshest.
  Future<void> upsert({
    required String barcode,
    required String name,
    required double price,
  }) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return;
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.insert(
      _table,
      {
        'barcode': trimmed,
        'name': name,
        'price': price,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint(
      '[ProductCache] upsert barcode=$trimmed, name="$name", price=$price',
    );
  }
}
