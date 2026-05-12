import 'package:flutter/material.dart';

import 'shop_interior_page.dart';

class ThreadShopPage extends StatelessWidget {
  const ThreadShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShopInteriorPage(
      backgroundAsset: 'assets/images/threadshop1.png',
      title: 'Threads',
      subtitle: 'The Gilded Thread',
    );
  }
}
