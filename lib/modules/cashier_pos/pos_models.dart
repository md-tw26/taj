import 'package:flutter/material.dart';

import '../../core/theme/taj_colors.dart';

enum PaymentMethod {
  cash,
  credit,
  bank,
  sadad,
  numoQr,
  mobicash,
  bankTransfer,
  bankTransferSadad,
  bankTransferMobCash,
}

IconData posCategoryIcon(String category) => switch (category) {
  'قمصان' => Icons.checkroom_outlined,
  'بناطيل' => Icons.style_outlined,
  'فساتين' => Icons.woman_outlined,
  'جاكيتات' => Icons.thermostat_outlined,
  'أحذية' => Icons.directions_walk_outlined,
  'حقائب' => Icons.shopping_bag_outlined,
  'إكسسوارات' => Icons.watch_outlined,
  _ => Icons.inventory_2_outlined,
};

TajSwatch tajCategoryColor(String category, TajColors taj) {
  switch (category) {
    case 'عطور':
    case 'قمصان':
      return taj.primary;
    case 'بخور':
    case 'جاكيتات':
      return taj.warning;
    case 'زيوت':
    case 'تنانير':
      return taj.success;
    case 'هدايا':
    case 'بناطيل':
    case 'حقائب':
      return taj.info;
    case 'فساتين':
    case 'إكسسوارات':
      return taj.secondary;
    case 'أحذية':
      return taj.error;
    default:
      return taj.primary;
  }
}

class PosHeldOrder {
  const PosHeldOrder({
    required this.id,
    required this.name,
    required this.itemCount,
    required this.subtotal,
    required this.cart,
  });
  final String id;
  final String name;
  final int itemCount;
  final double subtotal;
  final Map<String, int> cart;
}

class PosProduct {
  const PosProduct({
    required this.id,
    required this.name,
    required this.barcode,
    required this.category,
    required this.price,
    this.stock = 999,
  });
  final String id;
  final String name;
  final String barcode;
  final String category;
  final double price;
  final int stock;
}

class PosCompletedSale {
  const PosCompletedSale({
    required this.method,
    required this.total,
    required this.itemCount,
    required this.time,
  });
  final PaymentMethod method;
  final double total;
  final int itemCount;
  final DateTime time;
}
