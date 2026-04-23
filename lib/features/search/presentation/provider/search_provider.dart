import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../shopping_list/domain/entities/shopping_item.dart';
import '../../data/repo_impl/search_repository_impl.dart';
import '../../domain/repo/search_repository.dart';
import '../../domain/usecases/search_item_usecase.dart';

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepositoryImpl(),
);

final searchUseCaseProvider = Provider<SearchItemsUseCase>(
  (ref) => SearchItemsUseCase(ref.read(searchRepositoryProvider)),
);

final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose
    .family<List<ShoppingItem>, String>((ref, query) async {
      await Future.delayed(const Duration(milliseconds: 400));

      final useCase = ref.read(searchUseCaseProvider);
      return useCase(query);
    });
