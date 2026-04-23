import '../../domain/entities/shopping_item.dart';
import '../../domain/repo/shopping_repository.dart';
import '../datasource/shopping_local_datasource.dart';
import '../model/shopping_item_model.dart';
class ShoppingRepositoryImpl implements ShoppingRepository {
  final ShoppingLocalDataSource _dataSource;

  ShoppingRepositoryImpl({ShoppingLocalDataSource? dataSource})
      : _dataSource = dataSource ?? ShoppingLocalDataSource();

  @override
  Future<List<ShoppingItem>> getAllItems() async {
    return await _dataSource.getAllItems();
  }

  @override
  Future<void> addItem(ShoppingItem item) async {
    await _dataSource.insertItem(ShoppingItemModel.fromEntity(item));
  }

  @override
  Future<void> updateItem(ShoppingItem item) async {
    await _dataSource.updateItem(ShoppingItemModel.fromEntity(item));
  }

  @override
  Future<void> deleteItem(String id) async {
    await _dataSource.deleteItem(id);
  }

  @override
  Future<void> toggleItem(String id) async {
    await _dataSource.toggleItem(id);
  }

  @override
  Future<void> clearCheckedItems() async {
    await _dataSource.clearCheckedItems();
  }

  @override
  Future<void> clearAllItems() async {
    await _dataSource.clearAllItems();
  }

  @override
  Future<ShoppingItem?> getItemById(String id) async {
    return await _dataSource.getItemById(id);
  }
}