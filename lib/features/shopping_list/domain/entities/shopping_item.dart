class ShoppingItem {
  final String id;
  final String name;
  final double quantity;
  final double price;
  final bool isChecked;
  final DateTime createdAt;

  const ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.isChecked,
    required this.createdAt,
  });

  ShoppingItem copyWith({
    String? id,
    String? name,
    double? quantity,
    double? price,
    bool? isChecked,
    DateTime? createdAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      isChecked: isChecked ?? this.isChecked,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double get totalPrice => quantity * price;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ShoppingItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
