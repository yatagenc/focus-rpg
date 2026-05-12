class InventoryPotion {
  const InventoryPotion({
    required this.potionId,
    required this.quantity,
  });

  final String potionId;
  final int quantity;

  InventoryPotion copyWith({
    String? potionId,
    int? quantity,
  }) {
    return InventoryPotion(
      potionId: potionId ?? this.potionId,
      quantity: quantity ?? this.quantity,
    );
  }
}
