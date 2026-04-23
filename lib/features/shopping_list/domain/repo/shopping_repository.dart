import '../entities/shopping_item.dart';

abstract class ShoppingRepository {
  Future<List<ShoppingItem>> getAllItems();
  Future<void> addItem(ShoppingItem item);
  Future<void> updateItem(ShoppingItem item);
  Future<void> deleteItem(String id);
  Future<void> toggleItem(String id);
  Future<void> clearCheckedItems();
  Future<void> clearAllItems();
  Future<ShoppingItem?> getItemById(String id);
}