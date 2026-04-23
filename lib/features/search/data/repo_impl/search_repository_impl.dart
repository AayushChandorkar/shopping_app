import '../../../shopping_list/domain/entities/shopping_item.dart';
import '../../domain/repo/search_repository.dart';
import '../datasource/search_local_datasource.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchLocalDataSource _dataSource;

  SearchRepositoryImpl({SearchLocalDataSource? dataSource})
      : _dataSource = dataSource ?? SearchLocalDataSource();

  @override
  Future<List<ShoppingItem>> searchItems(String query) async {
    return await _dataSource.searchItems(query);
  }
}