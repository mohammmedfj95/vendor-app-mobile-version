import 'package:flutter/material.dart';
import 'package:store_management_app/services/auth_service.dart';
import 'package:store_management_app/services/store_service.dart';
import 'package:store_management_app/models/store.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _ownerEmailController = TextEditingController();

  final _authService = AuthService();
  final _storeService = StoreService();

  bool _isLoading = false;
  String _selectedRole = 'owner';
  bool _showStoreFields = true;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (_selectedRole == 'business_user') {
          // Check if store owner exists before creating account
          final ownerExists = await _storeService.checkStoreOwnerExists(
            _ownerEmailController.text.trim(),
          );

          if (!ownerExists) {
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Store owner not found. Please check the email address.'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
            return;
          }
        }

        // Register the user with Firebase Auth
        await _authService.registerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (_selectedRole == 'owner') {
          try {
            // Create store for owner
            final store = Store(
              storeName: _storeNameController.text,
              address: _storeAddressController.text,
              businessType: _businessTypeController.text,
              accountCreationDate: DateTime.now(),
              subscriptionPlan: 'Monthly',
              numberOfStoreUsers: 1,
              subscriptionActive: true,
            );

            await _storeService.createStore(store, _phoneNumberController.text);

            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          } catch (storeError) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to create store: $storeError')),
              );
              // Navigate to login since the user is created but store creation failed
              Navigator.of(context).pushReplacementNamed('/login');
            }
          }
        } else {
          // Register as business user
          try {
            await _storeService.registerAsBusinessUser(
              _ownerEmailController.text.trim(),
              _phoneNumberController.text,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Registration successful. Waiting for owner approval.'),
                  duration: Duration(seconds: 3),
                ),
              );
              Navigator.of(context).pushReplacementNamed('/login');
            }
          } catch (businessError) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Failed to register as business user: $businessError'),
                  duration: const Duration(seconds: 3),
                ),
              );
              Navigator.of(context).pushReplacementNamed('/login');
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration failed: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Role Selection
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'owner',
                      label: Text('Store Owner'),
                      icon: Icon(Icons.store),
                    ),
                    ButtonSegment(
                      value: 'business_user',
                      label: Text('Business User'),
                      icon: Icon(Icons.person),
                    ),
                  ],
                  selected: {_selectedRole},
                  onSelectionChanged: (Set<String> selection) {
                    setState(() {
                      _selectedRole = selection.first;
                      _showStoreFields = _selectedRole == 'owner';
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Basic Info Fields
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Conditional Fields based on role
                if (_showStoreFields) ...[
                  // Store Owner Fields
                  TextFormField(
                    controller: _storeNameController,
                    decoration: const InputDecoration(
                      labelText: 'Store Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: _showStoreFields
                        ? (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter store name';
                            }
                            return null;
                          }
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _storeAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Store Address',
                      border: OutlineInputBorder(),
                    ),
                    validator: _showStoreFields
                        ? (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter store address';
                            }
                            return null;
                          }
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _businessTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Business Type',
                      border: OutlineInputBorder(),
                    ),
                    validator: _showStoreFields
                        ? (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter business type';
                            }
                            return null;
                          }
                        : null,
                  ),
                ] else ...[
                  // Business User Fields
                  TextFormField(
                    controller: _ownerEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Store Owner Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: !_showStoreFields
                        ? (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter store owner email';
                            }
                            return null;
                          }
                        : null,
                  ),
                ],
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Register'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneNumberController.dispose();
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _businessTypeController.dispose();
    _ownerEmailController.dispose();
    super.dispose();
  }
}
