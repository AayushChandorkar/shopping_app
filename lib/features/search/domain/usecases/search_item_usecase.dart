import '../../../shopping_list/domain/entities/shopping_item.dart';
import '../repo/search_repository.dart';

class SearchItemsUseCase {
  final SearchRepository _repo;
  SearchItemsUseCase(this._repo);

  Future<List<ShoppingItem>> call(String query) => _repo.searchItems(query);
}