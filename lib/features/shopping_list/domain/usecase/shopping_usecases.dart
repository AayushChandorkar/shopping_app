import '../entities/shopping_item.dart';
import '../repo/shopping_repository.dart';

class GetAllItemsUseCase {
  final ShoppingRepository _repo;
  GetAllItemsUseCase(this._repo);
  Future<List<ShoppingItem>> call() => _repo.getAllItems();
}

class AddItemUseCase {
  final ShoppingRepository _repo;
  AddItemUseCase(this._repo);
  Future<void> call(ShoppingItem item) => _repo.addItem(item) ;
}

class UpdateItemUseCase {
  final ShoppingRepository _repo;
  UpdateItemUseCase(this._repo);
  Future<void> call(ShoppingItem item) => _repo.updateItem(item);
}

class DeleteItemUseCase {
  final ShoppingRepository _repo;
  DeleteItemUseCase(this._repo);
  Future<void> call(String id) => _repo.deleteItem(id);
}

class ToggleItemUseCase {
  final ShoppingRepository _repo;
  ToggleItemUseCase(this._repo);
  Future<void> call(String id) => _repo.toggleItem(id);
}

class ClearCheckedUseCase {
  final ShoppingRepository _repo;
  ClearCheckedUseCase(this._repo);
  Future<void> call() => _repo.clearCheckedItems();
}

class ClearAllUseCase {
  final ShoppingRepository _repo;
  ClearAllUseCase(this._repo);
  Future<void> call() => _repo.clearAllItems();
}

class GetItemByIdUseCase {
  final ShoppingRepository _repo;
  GetItemByIdUseCase(this._repo);

  Future<ShoppingItem?> call(String id) => _repo.getItemById(id);
}