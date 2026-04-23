import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_shop.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE shopping_items (
        id          TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        quantity    REAL NOT NULL DEFAULT 1,
        price       REAL NOT NULL DEFAULT 0,
        is_checked  INTEGER NOT NULL DEFAULT 0,
        created_at  TEXT NOT NULL
      )
    ''');

    await db.execute('''
    CREATE TABLE settings (
      key   TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''');

    // Barcode -> {name, price} cache populated from the user's own prior
    // scans. Used to auto-fill the name and price the next time the same
    // barcode is scanned.
    await db.execute('''
      CREATE TABLE product_cache (
        barcode     TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        price       REAL NOT NULL DEFAULT 0,
        updated_at  TEXT NOT NULL
      )
    ''');
  }

  /// Migration 1 -> 2: drop the `unit` column.
  /// SQLite has `ALTER TABLE DROP COLUMN` only from 3.35+, and sqflite may
  /// bundle older SQLite on some platforms, so we rebuild the table the
  /// portable way: create new -> copy data -> drop old -> rename.
  ///
  /// Migration 2 -> 3: add the `product_cache` table so scanned barcodes
  /// remember the name + price the user last saved.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE shopping_items_new (
          id          TEXT PRIMARY KEY,
          name        TEXT NOT NULL,
          quantity    REAL NOT NULL DEFAULT 1,
          price       REAL NOT NULL DEFAULT 0,
          is_checked  INTEGER NOT NULL DEFAULT 0,
          created_at  TEXT NOT NULL
        )
      ''');
      await db.execute('''
        INSERT INTO shopping_items_new (id, name, quantity, price, is_checked, created_at)
        SELECT id, name, quantity, price, is_checked, created_at FROM shopping_items
      ''');
      await db.execute('DROP TABLE shopping_items');
      await db.execute('ALTER TABLE shopping_items_new RENAME TO shopping_items');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE product_cache (
          barcode     TEXT PRIMARY KEY,
          name        TEXT NOT NULL,
          price       REAL NOT NULL DEFAULT 0,
          updated_at  TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}
