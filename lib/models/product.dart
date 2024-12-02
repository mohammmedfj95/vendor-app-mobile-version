class Product {
  final int? id;
  final String name;
  final String? sku;
  final String? category;
  final double price;
  final int stock;

  Product({
    this.id,
    required this.name,
    this.sku,
    this.category,
    required this.price,
    required this.stock,
  }) {
    if (name.isEmpty) {
      throw ArgumentError('Product name cannot be empty');
    }
    if (price < 0) {
      throw ArgumentError('Price cannot be negative');
    }
    if (stock < 0) {
      throw ArgumentError('Stock cannot be negative');
    }
  }

  factory Product.empty() {
    return Product(
      name: '',
      price: 0,
      stock: 0,
      category: 'Uncategorized',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name.trim(),
      'sku': sku?.trim() ?? '',
      'category': category?.trim() ?? '',
      'price': price,
      'stock': stock,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    if (!map.containsKey('name') ||
        !map.containsKey('price') ||
        !map.containsKey('stock')) {
      throw const FormatException(
          'Invalid product data: missing required fields');
    }

    final price = map['price'];
    if (price is! num) {
      throw const FormatException('Invalid price format');
    }

    final stock = map['stock'];
    if (stock is! int) {
      throw const FormatException('Invalid stock format');
    }

    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      sku: map['sku']?.toString().trim().isEmpty ?? true
          ? null
          : map['sku'] as String,
      category: map['category']?.toString().trim().isEmpty ?? true
          ? null
          : map['category'] as String,
      price: price.toDouble(),
      stock: stock,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? sku,
    String? category,
    double? price,
    int? stock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, sku: $sku, category: $category, price: $price, stock: $stock)';
  }
}
