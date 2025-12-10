import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/cart_item.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final List<Product> products = [
    Product(id: '1', name: 'Nasi Gudeg', price: 15000, image: '🍛'),
    Product(id: '2', name: 'Es Teh Manis', price: 5000, image: '🧊'),
    Product(id: '3', name: 'Ayam Bakar', price: 25000, image: '🍗'),
    Product(id: '4', name: 'Soto Ayam', price: 12000, image: '🍜'),
    Product(id: '5', name: 'Kopi Hitam', price: 8000, image: '☕'),
    Product(id: '6', name: 'Gado-gado', price: 18000, image: '🥗'),
  ];

  final List<CartItem> cartItems = [];
  double total = 0;

  void _addToCart(Product product) {
    setState(() {
      final existingIndex = cartItems.indexWhere(
        (item) => item.product.id == product.id,
      );

      if (existingIndex >= 0) {
        cartItems[existingIndex].quantity++;
      } else {
        cartItems.add(CartItem(product: product, quantity: 1));
      }

      _calculateTotal();
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      if (cartItems[index].quantity > 1) {
        cartItems[index].quantity--;
      } else {
        cartItems.removeAt(index);
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    total = cartItems.fold(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
  }

  void _clearCart() {
    setState(() {
      cartItems.clear();
      total = 0;
    });
  }

  void _processPayment() {
    if (cartItems.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total: Rp ${total.toStringAsFixed(0)}'),
            const SizedBox(height: 16),
            const Text('Pilih metode pembayaran:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _completeTransaction('Tunai');
            },
            child: const Text('Tunai'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _completeTransaction('Kartu');
            },
            child: const Text('Kartu'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _completeTransaction('QRIS');
            },
            child: const Text('QRIS'),
          ),
        ],
      ),
    );
  }

  void _completeTransaction(String paymentMethod) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaksi Berhasil'),
        content: Text(
          'Pembayaran $paymentMethod berhasil!\nTotal: Rp ${total.toStringAsFixed(0)}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCart();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Kasir'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearCart,
            tooltip: 'Clear Cart',
          ),
        ],
      ),
      body: Row(
        children: [
          // Product Grid
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Menu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Card(
                          child: InkWell(
                            onTap: () => _addToCart(product),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    product.image,
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    product.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rp ${product.price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Cart
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: const Row(
                      children: [
                        Icon(Icons.shopping_cart),
                        SizedBox(width: 8),
                        Text(
                          'Keranjang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cart Items
                  Expanded(
                    child: cartItems.isEmpty
                        ? const Center(
                            child: Text(
                              'Keranjang kosong',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: cartItems.length,
                            itemBuilder: (context, index) {
                              final item = cartItems[index];
                              return ListTile(
                                leading: Text(
                                  item.product.image,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                title: Text(
                                  item.product.name,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                subtitle: Text(
                                  'Rp ${item.product.price.toStringAsFixed(0)} x ${item.quantity}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Rp ${(item.product.price * item.quantity).toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle,
                                        size: 16,
                                      ),
                                      onPressed: () => _removeFromCart(index),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // Total and Payment
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Rp ${total.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: cartItems.isEmpty
                                ? null
                                : _processPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'BAYAR',
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
