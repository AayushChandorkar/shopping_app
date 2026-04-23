import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../data/repo_impl/shopping_repo_impl.dart';
import '../../domain/entities/shopping_item.dart';
import '../../domain/usecase/shopping_usecases.dart';
import '../../domain/repo/shopping_repository.dart';
import '../../data/datasource/shopping_local_datasource.dart';

final shoppingRepositoryProvider = Provider<ShoppingRepository>(
  (ref) => ShoppingRepositoryImpl(dataSource: ShoppingLocalDataSource()),
);

final getAllItemsUseCaseProvider = Provider(
  (ref) => GetAllItemsUseCase(ref.read(shoppingRepositoryProvider)),
);
final addItemUseCaseProvider = Provider(
  (ref) => AddItemUseCase(ref.read(shoppingRepositoryProvider)),
);
final updateItemUseCaseProvider = Provider(
  (ref) => UpdateItemUseCase(ref.read(shoppingRepositoryProvider)),
);
final deleteItemUseCaseProvider = Provider(
  (ref) => DeleteItemUseCase(ref.read(shoppingRepositoryProvider)),
);
final toggleItemUseCaseProvider = Provider(
  (ref) => ToggleItemUseCase(ref.read(shoppingRepositoryProvider)),
);
final clearCheckedUseCaseProvider = Provider(
  (ref) => ClearCheckedUseCase(ref.read(shoppingRepositoryProvider)),
);
final clearAllUseCaseProvider = Provider(
  (ref) => ClearAllUseCase(ref.read(shoppingRepositoryProvider)),
);

final activeFilterProvider = StateProvider<String>((ref) => 'All');
final activeSortProvider = StateProvider<String>((ref) => 'Date Added');

class ShoppingListState {
  final List<ShoppingItem> items;
  final bool isLoading;
  final String? error;

  const ShoppingListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  ShoppingListState copyWith({
    List<ShoppingItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return ShoppingListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get totalItems => items.length;

  int get checkedItems => items.where((i) => i.isChecked).length;

  int get pendingItems => items.where((i) => !i.isChecked).length;

  double get totalPrice => items.fold(0, (sum, item) => sum + item.totalPrice);

  double get checkedPrice =>
      items.where((i) => i.isChecked).fold(0, (sum, i) => sum + i.totalPrice);
}

class ShoppingListNotifier extends StateNotifier<ShoppingListState> {
  final GetAllItemsUseCase _getAll;
  final AddItemUseCase _add;
  final UpdateItemUseCase _update;
  final DeleteItemUseCase _delete;
  final ToggleItemUseCase _toggle;
  final ClearCheckedUseCase _clearChecked;
  final ClearAllUseCase _clearAll;
  final _uuid = const Uuid();

  ShoppingListNotifier({
    required GetAllItemsUseCase getAll,
    required AddItemUseCase add,
    required UpdateItemUseCase update,
    required DeleteItemUseCase delete,
    required ToggleItemUseCase toggle,
    required ClearCheckedUseCase clearChecked,
    required ClearAllUseCase clearAll,
  }) : _getAll = getAll,
       _add = add,
       _update = update,
       _delete = delete,
       _toggle = toggle,
       _clearChecked = clearChecked,
       _clearAll = clearAll,
       super(const ShoppingListState()) {
    loadItems();
  }

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _getAll();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addItem({
    required String name,
    required double quantity,
    required double price,
  }) async {
    final item = ShoppingItem(
      id: const Uuid().v4(),
      name: name,
      quantity: quantity,
      price: price,
      isChecked: false,
      createdAt: DateTime.now(),
    );
    await _add(item);
    state = state.copyWith(items: [item, ...state.items]);
  }

  Future<void> updateItem({
    required String id,
    required String name,
    required double quantity,
    required double price,
  }) async {
    final updated = state.items.map((item) {
      if (item.id == id) {
        return item.copyWith(
          name: name,
          quantity: quantity,
          price: price,
        );
      }
      return item;
    }).toList();
    await _update(updated.firstWhere((i) => i.id == id));
    state = state.copyWith(items: updated);
  }

  Future<void> toggleItem(String id) async {
    await _toggle(id);
    state = state.copyWith(
      items: state.items.map((item) {
        if (item.id == id) return item.copyWith(isChecked: !item.isChecked);
        return item;
      }).toList(),
    );
  }

  Future<void> removeItem(String id) async {
    await _delete(id);
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
    );
  }

  Future<void> clearChecked() async {
    await _clearChecked();
    state = state.copyWith(
      items: state.items.where((item) => !item.isChecked).toList(),
    );
  }

  Future<void> clearAll() async {
    await _clearAll();
    state = state.copyWith(items: []);
  }

  /// Converts every stored item's price from [from] to [to] using the fixed
  /// rate table in `core/utils/currency_utils.dart`. Persists each updated
  /// item and refreshes the state so the dashboard re-renders immediately.
  Future<void> convertAllPrices(String from, String to) async {
    if (from == to || state.items.isEmpty) return;

    final converted = state.items.map((item) {
      final newPrice = convertPrice(item.price, from, to);
      return item.copyWith(price: newPrice);
    }).toList();

    for (final item in converted) {
      await _update(item);
    }

    state = state.copyWith(items: converted);
  }
}

final shoppingListProvider =
    StateNotifierProvider<ShoppingListNotifier, ShoppingListState>(
      (ref) => ShoppingListNotifier(
        getAll: ref.read(getAllItemsUseCaseProvider),
        add: ref.read(addItemUseCaseProvider),
        update: ref.read(updateItemUseCaseProvider),
        delete: ref.read(deleteItemUseCaseProvider),
        toggle: ref.read(toggleItemUseCaseProvider),
        clearChecked: ref.read(clearCheckedUseCaseProvider),
        clearAll: ref.read(clearAllUseCaseProvider),
      ),
    );

final totalPriceProvider = Provider<double>(
  (ref) => ref.watch(shoppingListProvider).totalPrice,
);

final filteredItemsProvider = Provider<List<ShoppingItem>>((ref) {
  final items = ref.watch(shoppingListProvider).items;
  final filter = ref.watch(activeFilterProvider);
  final sort = ref.watch(activeSortProvider);

  var result = [...items];

  if (filter == 'Pending') result = result.where((i) => !i.isChecked).toList();
  if (filter == 'Checked') result = result.where((i) => i.isChecked).toList();

  switch (sort) {
    case 'Name':
      result.sort((a, b) => a.name.compareTo(b.name));
      break;
    case 'Price':
      result.sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
      break;
    case 'Date Added':
    default:
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  return result;
});
