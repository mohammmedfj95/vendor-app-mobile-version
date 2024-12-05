import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import '../models/sale.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final List<SaleItem> _saleItems = [];
  final TextEditingController _searchController = TextEditingController();
  List<Product> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  double _totalAmount = 0.0;
  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void dispose() {
    _searchController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final products = await _databaseService.searchProducts(query);
      if (!mounted) return;
      setState(() {
        _searchResults = products;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching products: $e')),
      );
    }
  }

  void _addSaleItem(Product product) {
    final existingItemIndex = _saleItems.indexWhere(
      (item) => item.product.id == product.id,
    );

    setState(() {
      if (existingItemIndex == -1) {
        // Add new item if product doesn't exist
        _saleItems.add(SaleItem(product: product, quantity: 1));
      } else {
        // Increment quantity if product already exists
        final existingItem = _saleItems[existingItemIndex];
        _saleItems[existingItemIndex] = SaleItem(
          product: product,
          quantity: existingItem.quantity + 1,
        );
      }
      _updateTotal();

      // Clear search results after adding item
      _searchResults = [];
      _searchController.clear();
    });
  }

  void _removeSaleItem(int index) {
    setState(() {
      _saleItems.removeAt(index);
      _updateTotal();
    });
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeSaleItem(index);
    } else {
      setState(() {
        _saleItems[index] = SaleItem(
          product: _saleItems[index].product,
          quantity: newQuantity,
        );
        _updateTotal();
      });
    }
  }

  void _updateTotal() {
    setState(() {
      _totalAmount = _saleItems.fold(
        0.0,
        (sum, item) => sum + (item.product.price * item.quantity),
      );
    });
  }

  Future<void> _createSale() async {
    print('Starting sale creation...');
    if (_saleItems.isEmpty) {
      print('No items in sale');
      setState(() {
        _hasError = true;
        _errorMessage = 'Please add items to the sale';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      print('Creating sale with ${_saleItems.length} items');
      print('Total amount: $_totalAmount');

      // Create a copy of sale items to prevent modification during processing
      final items = List<SaleItem>.from(_saleItems);

      // Validate all items before creating sale
      for (final item in items) {
        print('Validating item: ${item.product.name}');
        if (item.product.id == null) {
          throw Exception('Invalid product ID for ${item.product.name}');
        }
        if (item.quantity <= 0) {
          throw Exception('Invalid quantity for ${item.product.name}');
        }
      }

      final sale = Sale(
        saleItems: items,
        totalAmount: _totalAmount,
        dateTime: DateTime.now(), // Add the current date and time
      );

      print('Calling database service to create sale...');
      final result = await _databaseService.addSale(sale);
      print('Sale created with ID: $result');

      if (!mounted) {
        print('Widget not mounted after sale creation');
        return;
      }

      setState(() {
        _saleItems.clear();
        _searchResults.clear();
        _totalAmount = 0.0;
        _isLoading = false;
        _hasError = false;
        _errorMessage = '';
      });

      // Show success message before popping
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sale completed successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Wait a moment before popping to show the success message
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e, stackTrace) {
      print('Error creating sale: $e');
      print('Stack trace: $stackTrace');

      if (!mounted) {
        print('Widget not mounted after error');
        return;
      }

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });

      // Show error in snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code == null) continue;

      setState(() => _isSearching = true);
      try {
        final products = await _databaseService.searchProducts(code);
        if (!mounted) return;

        if (products.isNotEmpty) {
          _addSaleItem(products.first);
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finding product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
      ),
      body: Column(
        children: [
          if (_hasError)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.red.shade100,
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or SKU',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchProducts('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _searchProducts,
            ),
          ),

          // Search results or scanner
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            child: _searchResults.isNotEmpty
                ? ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final product = _searchResults[index];
                      return ListTile(
                        title: Text(product.name),
                        subtitle: Text(
                          'SKU: ${product.sku ?? 'N/A'} - Stock: ${product.stock}',
                        ),
                        trailing: Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onTap: () => _addSaleItem(product),
                      );
                    },
                  )
                : _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : MobileScanner(
                        controller: _scannerController,
                        onDetect: _onDetect,
                      ),
          ),

          // Sale items list
          Expanded(
            child: _saleItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No items added yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _saleItems.length,
                    itemBuilder: (context, index) {
                      final item = _saleItems[index];
                      return Dismissible(
                        key: Key('${item.product.id}_${item.quantity}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) => _removeSaleItem(index),
                        child: ListTile(
                          title: Text(item.product.name),
                          subtitle: Text(
                            '${item.quantity} × \$${item.product.price.toStringAsFixed(2)} = \$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => _updateQuantity(
                                  index,
                                  item.quantity - 1,
                                ),
                              ),
                              Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => _updateQuantity(
                                  index,
                                  item.quantity + 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Total and checkout button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '\$${_totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _createSale,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Complete Sale'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
