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
      title: 'POS Dual Engine',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (context) => const RouteHandler(),
        '/main': (context) => const CashierMainScreen(),
        '/customer': (context) => const CustomerDisplayScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class RouteHandler extends StatelessWidget {
  const RouteHandler({super.key});

  @override
  Widget build(BuildContext context) {
    // Get initial route from navigation channel
    final route = ModalRoute.of(context)?.settings.name ?? '/main';

    switch (route) {
      case '/customer':
        return const CustomerDisplayScreen();
      case '/main':
      default:
        return const CashierMainScreen();
    }
  }
}

class CashierMainScreen extends StatefulWidget {
  const CashierMainScreen({super.key});

  @override
  State<CashierMainScreen> createState() => _CashierMainScreenState();
}

class _CashierMainScreenState extends State<CashierMainScreen> {
  static const platform = MethodChannel('dual_display');

  bool isCustomerDisplayActive = false;
  bool hasSecondaryDisplay = false;
  String displayStatus = 'Checking displays...';
  bool isMethodChannelReady = false;

  @override
  void initState() {
    super.initState();
    // Delay untuk memastikan method channel sudah siap
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          isMethodChannelReady = true;
        });
        _checkDisplays();
      }
    });
  }

  Future<void> _checkDisplays() async {
    if (!isMethodChannelReady) {
      setState(() {
        displayStatus = 'Method channel not ready';
      });
      return;
    }

    try {
      final result = await platform.invokeMethod('checkSecondaryDisplay');
      setState(() {
        hasSecondaryDisplay = result['hasSecondaryDisplay'] ?? false;
        final totalDisplays = result['totalDisplays'] ?? 1;
        final deviceType = result['deviceType'] ?? 'Unknown';
        final isIMinDevice = result['displayInfo']?['isIMinDevice'] ?? false;

        if (hasSecondaryDisplay && isIMinDevice) {
          displayStatus =
              'iMin Customer Display ready ($totalDisplays displays)';
        } else if (hasSecondaryDisplay) {
          displayStatus = 'Dual display ready ($totalDisplays displays)';
        } else {
          displayStatus =
              '$deviceType - Single display ($totalDisplays display)';
        }
      });
    } catch (e) {
      setState(() {
        displayStatus = 'Error: $e';
      });
      debugPrint('Error checking displays: $e');
    }
  }

  Future<void> _toggleCustomerDisplay() async {
    if (!isMethodChannelReady) {
      _showErrorDialog('Method channel not ready. Please wait...');
      return;
    }

    if (isCustomerDisplayActive) {
      await _closeCustomerDisplay();
    } else {
      await _openCustomerDisplay();
    }
  }

  Future<void> _openCustomerDisplay() async {
    try {
      final result = await platform.invokeMethod('openSecondary');
      if (result['success'] == true) {
        setState(() {
          isCustomerDisplayActive = true;
        });

        // Send initial content to customer display
        await Future.delayed(const Duration(milliseconds: 1000));
        await _updateCustomerContent({
          'message': 'Selamat datang di Warung Makan Bahagia!',
          'status': 'ready',
        });
      } else {
        _showErrorDialog(
          'Gagal membuka layar customer: ${result['error'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
      debugPrint('Error opening customer display: $e');
    }
  }

  Future<void> _closeCustomerDisplay() async {
    try {
      await platform.invokeMethod('closeSecondary');
      setState(() {
        isCustomerDisplayActive = false;
      });
    } catch (e) {
      debugPrint('Error closing customer display: $e');
    }
  }

  Future<void> _updateCustomerContent(Map<String, dynamic> data) async {
    if (!isCustomerDisplayActive || !isMethodChannelReady) return;

    try {
      await platform.invokeMethod('updateCustomerDisplay', data);
      debugPrint('Customer content updated: $data');
    } catch (e) {
      debugPrint('Error updating customer content: $e');
    }
  }

  Future<void> _testiMinDisplay() async {
    if (!isCustomerDisplayActive || !isMethodChannelReady) return;

    try {
      await platform.invokeMethod('updateCustomerDisplay', {
        'message': '🔧 TEST iMin CUSTOMER DISPLAY 🔧',
        'orderInfo': 'Ayam Bakar + Soto Ayam + Es Teh Manis',
        'totalAmount': 45000,
        'paymentStatus': 'success',
        'promoMessage':
            'Promo iMin POS - Diskon 10% untuk pembelian di atas Rp 50.000!',
        'timestamp': DateTime.now().toString(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('iMin Customer Display test berhasil!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error testing iMin display: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Info'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDisplayInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informasi Dual Display'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $displayStatus'),
            const SizedBox(height: 16),
            Text(
              'Method Channel: ${isMethodChannelReady ? "Ready" : "Not Ready"}',
            ),
            Text(
              'Customer Display: ${isCustomerDisplayActive ? "Active" : "Inactive"}',
            ),
            Text(
              'Secondary Display: ${hasSecondaryDisplay ? "Available" : "Not Available"}',
            ),
            const SizedBox(height: 16),
            const Text(
              'Implementasi iMin POS:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Device: iMin POS Terminal'),
            const Text('• Layar Utama: Interface kasir'),
            const Text('• Customer Display: iMin secondary screen'),
            const Text('• API: Native Android Presentation'),
            const Text('• Real-time updates via Method Channel'),
            const Text('• Support untuk promo dan status pembayaran'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Dual Engine - Layar Kasir'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          // Method channel status
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isMethodChannelReady ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isMethodChannelReady ? Icons.link : Icons.link_off,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  isMethodChannelReady ? 'READY' : 'WAIT',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Display type indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasSecondaryDisplay ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasSecondaryDisplay
                      ? Icons.desktop_windows
                      : Icons.phone_android,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  hasSecondaryDisplay ? 'DUAL' : 'SINGLE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Customer display status
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
                  isCustomerDisplayActive ? 'ON' : 'OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Toggle customer display
          IconButton(
            icon: Icon(
              isCustomerDisplayActive ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: isMethodChannelReady ? _toggleCustomerDisplay : null,
            tooltip: 'Toggle Customer Display',
          ),

          // Test update
          if (isCustomerDisplayActive)
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () => _updateCustomerContent({
                'message': 'Test update dari kasir iMin',
                'timestamp': DateTime.now().toString(),
                'orderInfo': 'Nasi Gudeg + Es Teh Manis',
                'totalAmount': 20000,
                'paymentStatus': 'processing',
              }),
              tooltip: 'Test Update',
            ),

          // iMin Test
          if (isCustomerDisplayActive)
            IconButton(
              icon: const Icon(Icons.science),
              onPressed: () => _testiMinDisplay(),
              tooltip: 'Test iMin Display',
            ),

          // Info
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showDisplayInfo,
            tooltip: 'Info',
          ),

          // Refresh displays
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isMethodChannelReady ? _checkDisplays : null,
            tooltip: 'Refresh',
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
              gradient: LinearGradient(
                colors: isCustomerDisplayActive
                    ? [Colors.green[400]!, Colors.green[600]!]
                    : [Colors.orange[400]!, Colors.orange[600]!],
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCustomerDisplayActive
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCustomerDisplayActive
                            ? 'Layar customer aktif dengan FlutterEngine terpisah'
                            : isMethodChannelReady
                            ? 'Tekan tombol untuk mengaktifkan layar customer'
                            : 'Menunggu method channel siap...',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isCustomerDisplayActive && isMethodChannelReady)
                  ElevatedButton.icon(
                    onPressed: _toggleCustomerDisplay,
                    icon: const Icon(Icons.power_settings_new, size: 16),
                    label: const Text('AKTIFKAN LAYAR BELAKANG'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Main cashier screen
          const Expanded(child: CashierScreen()),
        ],
      ),
    );
  }
}

class CustomerDisplayScreen extends StatefulWidget {
  const CustomerDisplayScreen({super.key});

  @override
  State<CustomerDisplayScreen> createState() => _CustomerDisplayScreenState();
}

class _CustomerDisplayScreenState extends State<CustomerDisplayScreen> {
  static const platform = MethodChannel('customer_display');
  Map<String, dynamic> displayData = {};
  Map<String, dynamic> displayInfo = {};

  @override
  void initState() {
    super.initState();
    _setupMethodChannel();
    _getDisplayInfo();
  }

  void _setupMethodChannel() {
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'updateContent':
          setState(() {
            displayData = Map<String, dynamic>.from(call.arguments);
          });
          debugPrint('Customer display content updated: $displayData');
          break;
      }
    });
  }

  Future<void> _getDisplayInfo() async {
    try {
      final result = await platform.invokeMethod('getDisplayInfo');
      setState(() {
        displayInfo = Map<String, dynamic>.from(result);
      });
      debugPrint('Customer display info: $displayInfo');
    } catch (e) {
      debugPrint('Error getting display info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      body: Stack(
        children: [
          // Main customer screen
          const CustomerScreen(),

          // Overlay with real-time data
          if (displayData.isNotEmpty)
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (displayData['message'] != null)
                      Text(
                        displayData['message'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    if (displayData['orderInfo'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Pesanan: ${displayData['orderInfo']}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                    if (displayData['totalAmount'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Total: Rp ${displayData['totalAmount']}',
                        style: const TextStyle(
                          color: Colors.yellow,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    if (displayData['timestamp'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Update: ${displayData['timestamp']}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Display info (for debugging)
          if (displayInfo.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Display: ${displayInfo['name'] ?? 'Unknown'}\n'
                  'ID: ${displayInfo['displayId']}\n'
                  'Secondary: ${displayInfo['isSecondary']}\n'
                  'Route: /customer',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
