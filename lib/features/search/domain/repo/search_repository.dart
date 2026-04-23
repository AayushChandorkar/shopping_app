import '../../../shopping_list/domain/entities/shopping_item.dart';

abstract class SearchRepository {
  Future<List<ShoppingItem>> searchItems(String query);
}