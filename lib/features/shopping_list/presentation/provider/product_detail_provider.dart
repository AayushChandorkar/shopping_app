import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopping_list/features/shopping_list/presentation/provider/shopping_list_provider.dart';
import '../../domain/entities/shopping_item.dart';
import '../../domain/usecase/shopping_usecases.dart';
import '../../domain/repo/shopping_repository.dart';

final getItemByIdUseCaseProvider = Provider<GetItemByIdUseCase>(
      (ref) => GetItemByIdUseCase(
    ref.read(shoppingRepositoryProvider),
  ),
);

final productDetailProvider = FutureProvider.autoDispose
    .family<ShoppingItem?, String>((ref, productId) async {
  final useCase = ref.read(getItemByIdUseCaseProvider);
  return useCase(productId);
});