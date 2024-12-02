import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../services/database_service.dart';
import 'new_sale_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Sale> _sales = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final sales = await _databaseService.getAllSales();
      setState(() {
        _sales = sales;
        _sales.sort((a, b) => b.dateTime.compareTo(a.dateTime)); // Sort by newest first
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load sales: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSales,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewSaleScreen(),
            ),
          );
          _loadSales(); // Refresh sales list after returning
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSales,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_sales.isEmpty) {
      return const Center(
        child: Text(
          'No sales yet.\nTap + to create a new sale.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSales,
      child: ListView.builder(
        itemCount: _sales.length,
        itemBuilder: (context, index) {
          final sale = _sales[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            elevation: 2,
            child: ExpansionTile(
              title: Text(
                'Sale on ${DateFormat('MMM d, y HH:mm').format(sale.dateTime)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Total: \$${sale.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.green),
              ),
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sale.saleItems.length,
                  itemBuilder: (context, itemIndex) {
                    final item = sale.saleItems[itemIndex];
                    return ListTile(
                      dense: true,
                      title: Text(item.product.name),
                      subtitle: Text(
                        '${item.quantity} x \$${item.product.price.toStringAsFixed(2)}',
                      ),
                      trailing: Text(
                        '\$${(item.quantity * item.product.price).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Total Items: ${sale.saleItems.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
