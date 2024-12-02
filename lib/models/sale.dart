import 'package:flutter/foundation.dart';
import 'product.dart';

class SaleItem {
  final Product product;
  final int quantity;

  SaleItem({
    required this.product,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'productName': product.name,
      'quantity': quantity,
      'price': product.price,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      product: Product(
        id: map['productId'] as int,
        name: map['productName'] as String,
        price: map['price'] as double,
        stock: 0, // Stock is not relevant for historical sales
      ),
      quantity: map['quantity'] as int,
    );
  }
}

class Sale {
  final int? id;
  final List<SaleItem> saleItems;
  final double totalAmount;
  final DateTime dateTime;

  Sale({
    this.id,
    required this.saleItems,
    required this.totalAmount,
    DateTime? dateTime,
  }) : dateTime = dateTime ?? DateTime.now() {
    if (saleItems.isEmpty) {
      throw ArgumentError('Sale must have at least one item');
    }
    for (final item in saleItems) {
      if (item.quantity <= 0) {
        throw ArgumentError('Item quantity must be greater than 0');
      }
      if (item.product.id == null) {
        throw ArgumentError('Product must have a valid ID');
      }
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'totalAmount': totalAmount,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int?,
      saleItems: [], // Items should be loaded separately
      totalAmount: (map['totalAmount'] as num).toDouble(),
      dateTime: DateTime.parse(map['dateTime'] as String),
    );
  }

  @override
  String toString() {
    return 'Sale(id: $id, items: ${saleItems.length}, total: $totalAmount, date: $dateTime)';
  }
}
