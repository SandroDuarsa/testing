import 'package:flutter/material.dart';
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
      title: 'POS Dual Display Testing',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const DualDisplaySimulator(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DualDisplaySimulator extends StatefulWidget {
  const DualDisplaySimulator({super.key});

  @override
  State<DualDisplaySimulator> createState() => _DualDisplaySimulatorState();
}

class _DualDisplaySimulatorState extends State<DualDisplaySimulator> {
  bool isCustomerDisplayActive = false;
  bool showBothDisplays = true;

  void _toggleCustomerDisplay() {
    setState(() {
      isCustomerDisplayActive = !isCustomerDisplayActive;
    });
  }

  void _toggleDisplayMode() {
    setState(() {
      showBothDisplays = !showBothDisplays;
    });
  }

  void _openCustomerFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Layar Belakang - Customer Display'),
            backgroundColor: Colors.blue[900],
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.fullscreen_exit),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Exit Fullscreen',
              ),
            ],
          ),
          body: const CustomerScreen(),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!showBothDisplays) {
      // Show only cashier display (simulating single display mode)
      return Scaffold(
        appBar: AppBar(
          title: const Text('POS System - Layar Depan (Kasir)'),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          actions: [
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
            IconButton(
              icon: Icon(
                isCustomerDisplayActive
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: _toggleCustomerDisplay,
              tooltip: 'Toggle Customer Display',
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: _openCustomerFullscreen,
              tooltip: 'Open Customer Display',
            ),
            IconButton(
              icon: const Icon(Icons.view_sidebar),
              onPressed: _toggleDisplayMode,
              tooltip: 'Show Dual Display View',
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: isCustomerDisplayActive
                  ? Colors.green[50]
                  : Colors.orange[50],
              child: Row(
                children: [
                  Icon(
                    isCustomerDisplayActive
                        ? Icons.check_circle
                        : Icons.warning,
                    color: isCustomerDisplayActive
                        ? Colors.green[700]
                        : Colors.orange[700],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isCustomerDisplayActive
                          ? 'Layar Customer AKTIF - Customer dapat melihat informasi'
                          : 'Layar Customer TIDAK AKTIF - Tekan tombol untuk mengaktifkan',
                      style: TextStyle(
                        color: isCustomerDisplayActive
                            ? Colors.green[700]
                            : Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(child: CashierScreen()),
          ],
        ),
      );
    }

    // Show dual display simulation
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Dual Display Simulator'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.desktop_windows, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'DUAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isCustomerDisplayActive ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: _toggleCustomerDisplay,
            tooltip: 'Toggle Customer Display',
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen),
            onPressed: _openCustomerFullscreen,
            tooltip: 'Customer Display Fullscreen',
          ),
          IconButton(
            icon: const Icon(Icons.view_agenda),
            onPressed: _toggleDisplayMode,
            tooltip: 'Single Display Mode',
          ),
        ],
      ),
      body: Row(
        children: [
          // Layar Depan (Kasir) - 70% width
          Expanded(
            flex: 7,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue[300]!, width: 3),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: Colors.blue[100],
                    child: const Row(
                      children: [
                        Icon(Icons.computer, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'LAYAR DEPAN - KASIR',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(child: CashierScreen()),
                ],
              ),
            ),
          ),

          // Divider
          Container(
            width: 4,
            color: Colors.grey[400],
            child: Center(
              child: Container(width: 2, height: 100, color: Colors.grey[600]),
            ),
          ),

          // Layar Belakang (Customer) - 30% width
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isCustomerDisplayActive
                      ? Colors.green[300]!
                      : Colors.grey[300]!,
                  width: 3,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: isCustomerDisplayActive
                        ? Colors.green[100]
                        : Colors.grey[100],
                    child: Row(
                      children: [
                        Icon(
                          isCustomerDisplayActive ? Icons.tv : Icons.tv_off,
                          color: isCustomerDisplayActive
                              ? Colors.green
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'LAYAR BELAKANG - CUSTOMER',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isCustomerDisplayActive
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        Switch(
                          value: isCustomerDisplayActive,
                          onChanged: (value) => _toggleCustomerDisplay(),
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: isCustomerDisplayActive
                        ? const CustomerScreen()
                        : Container(
                            color: Colors.black,
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.tv_off,
                                    size: 64,
                                    color: Colors.white54,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'LAYAR CUSTOMER\nTIDAK AKTIF',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Aktifkan untuk menampilkan\ninformasi ke customer',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey[100],
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Simulasi Dual Display POS - Layar kiri untuk kasir, layar kanan untuk customer',
                style: TextStyle(fontSize: 12),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _openCustomerFullscreen,
              icon: const Icon(Icons.fullscreen, size: 16),
              label: const Text('Test Fullscreen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
