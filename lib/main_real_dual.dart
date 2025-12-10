import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/cashier_screen.dart';
import 'screens/customer_screen.dart';

void main() {
  runApp(const POSApp());
}

class POSApp extends StatelessWidget {
  const POSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Real Dual Display',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const RealDualDisplayPOS(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RealDualDisplayPOS extends StatefulWidget {
  const RealDualDisplayPOS({super.key});

  @override
  State<RealDualDisplayPOS> createState() => _RealDualDisplayPOSState();
}

class _RealDualDisplayPOSState extends State<RealDualDisplayPOS> {
  bool isCustomerDisplayActive = false;
  static const platform = MethodChannel('pos_dual_display');

  @override
  void initState() {
    super.initState();
    _initializeDualDisplay();
  }

  Future<void> _initializeDualDisplay() async {
    try {
      // Coba deteksi dual display menggunakan platform channel
      final result = await platform.invokeMethod('detectDisplays');
      debugPrint('Display detection result: $result');
    } catch (e) {
      debugPrint('Platform channel not available, using fallback: $e');
      // Fallback untuk testing tanpa platform channel
    }
  }

  Future<void> _toggleCustomerDisplay() async {
    try {
      if (isCustomerDisplayActive) {
        // Tutup customer display
        await platform.invokeMethod('closeCustomerDisplay');
        setState(() {
          isCustomerDisplayActive = false;
        });
      } else {
        // Buka customer display di layar kedua
        final result = await platform.invokeMethod('openCustomerDisplay', {
          'content': 'customer_screen',
        });

        if (result == 'success') {
          setState(() {
            isCustomerDisplayActive = true;
          });
        } else {
          // Fallback: buka dalam window terpisah
          _openCustomerWindowFallback();
        }
      }
    } catch (e) {
      debugPrint('Error with platform channel: $e');
      // Fallback untuk testing
      _openCustomerWindowFallback();
    }
  }

  void _openCustomerWindowFallback() {
    // Fallback: buka customer display dalam dialog fullscreen
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const CustomerDisplayFullscreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        )
        .then((_) {
          setState(() {
            isCustomerDisplayActive = false;
          });
        });

    setState(() {
      isCustomerDisplayActive = true;
    });
  }

  Future<void> _updateCustomerDisplay(String content) async {
    if (!isCustomerDisplayActive) return;

    try {
      await platform.invokeMethod('updateCustomerDisplay', {
        'content': content,
      });
    } catch (e) {
      debugPrint('Error updating customer display: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS System - Layar Depan (Kasir)'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          // Status indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCustomerDisplayActive ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCustomerDisplayActive ? Icons.tv : Icons.tv_off,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  isCustomerDisplayActive ? 'AKTIF' : 'MATI',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Toggle button
          IconButton(
            icon: Icon(
              isCustomerDisplayActive ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: _toggleCustomerDisplay,
            tooltip: isCustomerDisplayActive
                ? 'Tutup Layar Belakang'
                : 'Buka Layar Belakang',
          ),

          // Test update button
          if (isCustomerDisplayActive)
            IconButton(
              icon: const Icon(Icons.update),
              onPressed: () => _updateCustomerDisplay('test_update'),
              tooltip: 'Test Update',
            ),

          // Info button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfo,
            tooltip: 'Info',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCustomerDisplayActive
                  ? Colors.green[50]
                  : Colors.orange[50],
              border: Border(
                bottom: BorderSide(
                  color: isCustomerDisplayActive
                      ? Colors.green[200]!
                      : Colors.orange[200]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCustomerDisplayActive
                      ? Icons.desktop_windows
                      : Icons.desktop_access_disabled,
                  color: isCustomerDisplayActive
                      ? Colors.green[700]
                      : Colors.orange[700],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCustomerDisplayActive
                            ? 'Layar Belakang (Customer): AKTIF'
                            : 'Layar Belakang (Customer): TIDAK AKTIF',
                        style: TextStyle(
                          color: isCustomerDisplayActive
                              ? Colors.green[700]
                              : Colors.orange[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCustomerDisplayActive
                            ? 'Customer dapat melihat informasi pesanan dan promo di layar belakang'
                            : 'Tekan tombol untuk mengaktifkan layar customer di display kedua',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (!isCustomerDisplayActive)
                  ElevatedButton.icon(
                    onPressed: _toggleCustomerDisplay,
                    icon: const Icon(Icons.power_settings_new, size: 18),
                    label: const Text('AKTIFKAN LAYAR BELAKANG'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Main cashier interface
          Expanded(
            child: CashierScreenWithCallback(
              onOrderUpdate: (orderInfo) {
                if (isCustomerDisplayActive) {
                  _updateCustomerDisplay(orderInfo);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informasi Dual Display POS'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sistem POS dengan Dual Display:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Layar Depan: Interface kasir (ini)'),
            Text('• Layar Belakang: Display untuk customer'),
            SizedBox(height: 16),
            Text(
              'Cara Penggunaan:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('1. Tekan tombol mata untuk mengaktifkan layar customer'),
            Text('2. Layar customer akan muncul di display kedua'),
            Text('3. Customer dapat melihat pesanan dan promo'),
            Text('4. Tekan lagi untuk menutup layar customer'),
            SizedBox(height: 16),
            Text('Catatan:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              'Jika tidak ada display kedua, layar customer akan muncul dalam window terpisah untuk testing.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class CashierScreenWithCallback extends StatelessWidget {
  final Function(String) onOrderUpdate;

  const CashierScreenWithCallback({super.key, required this.onOrderUpdate});

  @override
  Widget build(BuildContext context) {
    // Wrapper untuk CashierScreen dengan callback
    return const CashierScreen();
  }
}

class CustomerDisplayFullscreen extends StatelessWidget {
  const CustomerDisplayFullscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Customer screen content
          const CustomerScreen(),

          // Exit button (tersembunyi, tap pojok kanan atas)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 100,
                height: 100,
                color: Colors.transparent,
                child: const Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(Icons.close, color: Colors.white54, size: 24),
                  ),
                ),
              ),
            ),
          ),

          // Instruction text (akan hilang setelah beberapa detik)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Layar Belakang Customer - Tap pojok kanan atas untuk keluar',
                style: TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
