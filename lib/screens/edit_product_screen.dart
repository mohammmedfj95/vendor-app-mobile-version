import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import './barcode_scanner_screen.dart';

class EditProductScreen extends StatefulWidget {
  final Product? product;

  const EditProductScreen({Key? key, this.product}) : super(key: key);

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late String? _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _skuController = TextEditingController(text: widget.product?.sku ?? '');
    _priceController =
        TextEditingController(text: widget.product?.price.toString() ?? '');
    _stockController =
        TextEditingController(text: widget.product?.stock.toString() ?? '');
    _selectedCategory = widget.product?.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final product = Product(
        id: widget.product?.id,
        name: _nameController.text.trim(),
        sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
        category: _selectedCategory,
        price: double.parse(_priceController.text),
        stock: int.parse(_stockController.text),
      );

      if (widget.product == null) {
        await DatabaseService().addProduct(product);
      } else {
        await DatabaseService().updateProduct(product);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2D3142);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'Add Product' : 'Edit Product',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.product != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Product'),
                    content: const Text(
                        'Are you sure you want to delete this product?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  try {
                    await DatabaseService().deleteProduct(widget.product!.id!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Product deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context, true);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting product: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter product name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _skuController,
                        decoration: InputDecoration(
                          labelText: 'SKU (Optional)',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.qr_code),
                          helperText: 'Leave empty if not needed',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: () async {
                              final result = await Navigator.push<String>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const BarcodeScannerScreen(),
                                ),
                              );
                              if (result != null && mounted) {
                                setState(() {
                                  _skuController.text = result;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Electronics', child: Text('Electronics')),
                          DropdownMenuItem(
                              value: 'Clothing', child: Text('Clothing')),
                          DropdownMenuItem(
                              value: 'Books', child: Text('Books')),
                          DropdownMenuItem(value: 'Food', child: Text('Food')),
                          DropdownMenuItem(
                              value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter price';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid price';
                          }
                          if (double.parse(value) < 0) {
                            return 'Price cannot be negative';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _stockController,
                        decoration: const InputDecoration(
                          labelText: 'Stock Quantity',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.warehouse),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter stock quantity';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (int.parse(value) < 0) {
                            return 'Stock cannot be negative';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          widget.product == null ? 'Add Product' : 'Update Product',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
