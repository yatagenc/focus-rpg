class ProfileItem {
  const ProfileItem({
    required this.profileId,
    required this.itemId,
    required this.quantity,
  });

  final int profileId;
  final int itemId;
  final int quantity;

  factory ProfileItem.fromMap(Map<String, Object?> map) {
    return ProfileItem(
      profileId: map['profile_id'] as int,
      itemId: map['item_id'] as int,
      quantity: map['quantity'] as int,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'profile_id': profileId,
      'item_id': itemId,
      'quantity': quantity,
    };
  }
}
