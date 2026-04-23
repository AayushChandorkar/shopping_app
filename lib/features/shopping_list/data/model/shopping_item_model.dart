import '../../domain/entities/shopping_item.dart';

class ShoppingItemModel extends ShoppingItem {
  const ShoppingItemModel({
    required super.id,
    required super.name,
    required super.quantity,
    required super.price,
    required super.isChecked,
    required super.createdAt,
  });

  factory ShoppingItemModel.fromMap(Map<String, dynamic> map) {
    return ShoppingItemModel(
      id: map['id'] as String,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      price: (map['price'] as num).toDouble(),
      isChecked: (map['is_checked'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'is_checked': isChecked ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ShoppingItemModel.fromEntity(ShoppingItem entity) {
    return ShoppingItemModel(
      id: entity.id,
      name: entity.name,
      quantity: entity.quantity,
      price: entity.price,
      isChecked: entity.isChecked,
      createdAt: entity.createdAt,
    );
  }

  @override
  ShoppingItemModel copyWith({
    String? id,
    String? name,
    double? quantity,
    double? price,
    bool? isChecked,
    DateTime? createdAt,
  }) {
    return ShoppingItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      isChecked: isChecked ?? this.isChecked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
