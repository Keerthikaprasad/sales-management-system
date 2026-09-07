import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = 'http://127.0.0.1:8000';

void main() {
  runApp(const SalesmanApp());
}

class SalesmanApp extends StatelessWidget {
  const SalesmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sales Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const StartupScreen(),
    );
  }
}

// ================= STARTUP =================

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => token != null && token.isNotEmpty
            ? const HomeScreen()
            : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// ================= LOGIN =================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showMessage('Please enter email and password');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'username': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString(
          'access_token',
          data['access_token'],
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );
      } else {
        String message = 'Invalid email or password';

        try {
          final data = jsonDecode(response.body);
          message = data['detail'] ?? message;
        } catch (_) {}

        showMessage(message);
      }
    } catch (_) {
      showMessage(
        'Unable to connect to server. Make sure FastAPI is running.',
      );
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    const Icon(
                      Icons.store,
                      size: 70,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Sales Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Salesman Login',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      onSubmitted: (_) {
                        if (!loading) {
                          login();
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: loading ? null : login,
                        child: loading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'LOGIN',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================= API HELPER =================

Future<Map<String, String>> authHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  return {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
}

// ================= HOME =================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sales Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome, Salesman!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage customers, products and orders.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  HomeCard(
                    icon: Icons.people,
                    title: 'Customers',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomersScreen(),
                        ),
                      );
                    },
                  ),
                  HomeCard(
                    icon: Icons.inventory_2,
                    title: 'Products',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductsScreen(),
                        ),
                      );
                    },
                  ),
                  HomeCard(
                    icon: Icons.shopping_cart,
                    title: 'Create Order',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateOrderScreen(),
                        ),
                      );
                    },
                  ),
                  HomeCard(
                    icon: Icons.receipt_long,
                    title: 'Order History',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OrdersScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const HomeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= CUSTOMERS =================

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<dynamic> customers = [];
  bool loading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    loadCustomers();
  }

  Future<void> loadCustomers([String search = '']) async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final headers = await authHeaders();

      final uri = Uri.parse('$baseUrl/api/customers').replace(
        queryParameters:
            search.trim().isEmpty ? null : {'search': search.trim()},
      );

      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        setState(() {
          customers = jsonDecode(response.body);
        });
      } else {
        if (!mounted) return;

        setState(() {
          error = 'Failed to load customers';
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        error = 'Unable to connect to server';
      });
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  void showCustomer(dynamic customer) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(customer['name'] ?? 'Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${customer['email'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Phone: ${customer['phone'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Address: ${customer['address'] ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: loadCustomers,
            ),
          ),
          if (loading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (error.isNotEmpty)
            Expanded(
              child: Center(
                child: Text(error),
              ),
            )
          else if (customers.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No customers found'),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: customers.length,
                itemBuilder: (_, index) {
                  final customer = customers[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(customer['name'] ?? ''),
                      subtitle: Text(
                        '${customer['phone'] ?? ''}\n'
                        '${customer['email'] ?? ''}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => showCustomer(customer),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ================= PRODUCTS =================

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<dynamic> products = [];
  bool loading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts([String search = '']) async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final headers = await authHeaders();

      final uri = Uri.parse('$baseUrl/api/products').replace(
        queryParameters:
            search.trim().isEmpty ? null : {'search': search.trim()},
      );

      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        setState(() {
          products = jsonDecode(response.body);
        });
      } else {
        if (!mounted) return;

        setState(() {
          error = 'Failed to load products';
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        error = 'Unable to connect to server';
      });
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  void showProduct(dynamic product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(product['name'] ?? 'Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${product['sku']}'),
            const SizedBox(height: 8),
            Text('Price: ₹${product['price']}'),
            const SizedBox(height: 8),
            Text('Stock: ${product['stock_quantity']}'),
            const SizedBox(height: 8),
            Text(
              'Description: ${product['description'] ?? 'N/A'}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: loadProducts,
            ),
          ),
          if (loading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (error.isNotEmpty)
            Expanded(
              child: Center(
                child: Text(error),
              ),
            )
          else if (products.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No products found'),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (_, index) {
                  final product = products[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.inventory_2),
                      ),
                      title: Text(product['name'] ?? ''),
                      subtitle: Text(
                        'SKU: ${product['sku']}\n'
                        '₹${product['price']} • '
                        'Stock: ${product['stock_quantity']}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => showProduct(product),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ================= CREATE ORDER =================

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  List<dynamic> customers = [];
  List<dynamic> products = [];

  dynamic selectedCustomer;

  final Map<int, int> quantities = {};

  bool loading = true;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final headers = await authHeaders();

      final customerResponse = await http.get(
        Uri.parse('$baseUrl/api/customers'),
        headers: headers,
      );

      final productResponse = await http.get(
        Uri.parse('$baseUrl/api/products'),
        headers: headers,
      );

      if (customerResponse.statusCode == 200 &&
          productResponse.statusCode == 200) {
        if (!mounted) return;

        setState(() {
          customers = jsonDecode(customerResponse.body);
          products = jsonDecode(productResponse.body);
          loading = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  double get total {
    double result = 0;

    for (final product in products) {
      final id = product['id'] as int;
      final quantity = quantities[id] ?? 0;

      final price =
          double.tryParse(product['price'].toString()) ?? 0;

      result += quantity * price;
    }

    return result;
  }

  List<dynamic> get selectedProducts {
    return products.where((product) {
      final id = product['id'] as int;
      return (quantities[id] ?? 0) > 0;
    }).toList();
  }

  Future<void> submitOrder() async {
    if (selectedCustomer == null) {
      showMessage('Please select a customer');
      return;
    }

    if (selectedProducts.isEmpty) {
      showMessage('Please select at least one product');
      return;
    }

    setState(() {
      submitting = true;
    });

    try {
      final headers = await authHeaders();

      final items = selectedProducts.map((product) {
        final id = product['id'] as int;

        return {
          'product_id': id,
          'quantity': quantities[id],
        };
      }).toList();

      final response = await http.post(
        Uri.parse('$baseUrl/api/orders'),
        headers: headers,
        body: jsonEncode({
          'customer_id': selectedCustomer['id'],
          'items': items,
        }),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;

        showMessage('Order created successfully');

        Navigator.pop(context);
      } else {
        String message = 'Failed to create order';

        try {
          final data = jsonDecode(response.body);
          message = data['detail'] ?? message;
        } catch (_) {}

        showMessage(message);
      }
    } catch (_) {
      showMessage('Unable to connect to server');
    }

    if (mounted) {
      setState(() {
        submitting = false;
      });
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Order'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Order'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<dynamic>(
              initialValue: selectedCustomer,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Select Customer',
                border: OutlineInputBorder(),
              ),
              items: customers.map((customer) {
                return DropdownMenuItem<dynamic>(
                  value: customer,
                  child: Text(
                    '${customer['name']} - ${customer['phone']}',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCustomer = value;
                });
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Products',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (_, index) {
                final product = products[index];

                final id = product['id'] as int;
                final quantity = quantities[id] ?? 0;
                final stock = product['stock_quantity'] as int;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.inventory_2,
                          size: 40,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('₹${product['price']}'),
                              Text('Stock: $stock'),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: quantity > 0
                              ? () {
                                  setState(() {
                                    quantities[id] = quantity - 1;
                                  });
                                }
                              : null,
                          icon: const Icon(
                            Icons.remove_circle_outline,
                          ),
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          onPressed: quantity < stock
                              ? () {
                                  setState(() {
                                    quantities[id] = quantity + 1;
                                  });
                                }
                              : null,
                          icon: const Icon(
                            Icons.add_circle_outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed:
                          submitting ? null : submitOrder,
                      icon: submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        submitting
                            ? 'Submitting...'
                            : 'SUBMIT ORDER',
                      ),
                    ),
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

// ================= ORDERS =================

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> orders = [];
  bool loading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final headers = await authHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/api/orders'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        setState(() {
          orders = jsonDecode(response.body);
        });
      } else {
        if (!mounted) return;

        setState(() {
          error = 'Failed to load orders';
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        error = 'Unable to connect to server';
      });
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  void showOrder(dynamic order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Order #${order['id']}'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer: ${order['customer_name']}',
                ),
                const SizedBox(height: 6),
                Text(
                  'Status: ${order['status']}',
                ),
                const SizedBox(height: 6),
                Text(
                  'Date: ${formatDate(order['created_at'])}',
                ),
                const Divider(height: 25),
                const Text(
                  'Items',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                ...(order['items'] as List).map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item['product_name']),
                    subtitle: Text(
                      '${item['quantity']} × ₹${item['unit_price']}',
                    ),
                    trailing: Text(
                      '₹${item['subtotal']}',
                    ),
                  ),
                ),
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total: ₹${order['total_amount']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String formatDate(String? value) {
    if (value == null) {
      return 'N/A';
    }

    try {
      final date = DateTime.parse(value);

      return '${date.day}/${date.month}/${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value;
    }
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.blue;
      case 'shipped':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        actions: [
          IconButton(
            onPressed: loadOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : error.isNotEmpty
              ? Center(
                  child: Text(error),
                )
              : orders.isEmpty
                  ? const Center(
                      child: Text('No orders found'),
                    )
                  : RefreshIndicator(
                      onRefresh: loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: orders.length,
                        itemBuilder: (_, index) {
                          final order = orders[index];

                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  '#${order['id']}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              title: Text(
                                order['customer_name'] ??
                                    'Customer',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${formatDate(order['created_at'])}\n'
                                'Status: ${order['status']}',
                              ),
                              isThreeLine: true,
                              trailing: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${order['total_amount']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Icon(
                                    Icons.circle,
                                    size: 10,
                                    color: statusColor(
                                      order['status'],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => showOrder(order),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}