import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final products = await _databaseService.getAllProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load products: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2D3142);
    final cardColor = Theme.of(context).cardColor;
    final shadowColor = isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.1);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Text(
              'Inventory',
              style: TextStyle(color: textColor),
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            actions: [
              IconButton(
                icon: Icon(Icons.search, color: textColor),
                onPressed: () {
                  // TODO: Implement search functionality
                },
              ),
              IconButton(
                icon: Icon(Icons.filter_list, color: textColor),
                onPressed: () {
                  // TODO: Implement filter functionality
                },
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _errorMessage != null
                    ? SliverFillRemaining(
                        child: Center(
                          child: Text(_errorMessage!),
                        ),
                      )
                    : _products.isEmpty
                        ? const SliverFillRemaining(
                            child: Center(
                              child: Text('No products found. Add some products!'),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final product = _products[index];
                                return FadeInUp(
                                  duration: Duration(milliseconds: 300 + (index * 100)),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: Material(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(16),
                                      elevation: 2,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditProductScreen(product: product),
                                            ),
                                          );
                                          if (result == true) {
                                            _loadProducts(); // Refresh the list after editing
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.inventory_2,
                                                  color: Color(0xFF6C63FF),
                                                  size: 30,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      product.name,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                    if (product.sku != null && product.sku!.isNotEmpty) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'SKU: ${product.sku}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          '\$${product.price.toStringAsFixed(2)}',
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w600,
                                                            color: Color(0xFF6C63FF),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 16),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: product.stock <= 5
                                                                ? const Color(0xFFFF6B6B).withOpacity(0.1)
                                                                : const Color(0xFF4CAF50).withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          child: Text(
                                                            'Stock: ${product.stock}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w600,
                                                              color: product.stock <= 5
                                                                  ? const Color(0xFFFF6B6B)
                                                                  : const Color(0xFF4CAF50),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons.chevron_right,
                                                color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: _products.length,
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FadeInUp(
        duration: const Duration(milliseconds: 300),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddProductScreen(),
              ),
            );
            if (result == true) {
              setState(() {
                _loadProducts(); // Refresh the product list
              });
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Product'),
          backgroundColor: const Color(0xFF6C63FF),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
