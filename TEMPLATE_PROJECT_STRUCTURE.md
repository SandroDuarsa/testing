# Template Project Structure untuk iMin Dual Display

## 📁 Struktur File yang Harus Ada

```
your_flutter_project/
├── android/
│   └── app/
│       └── src/
│           └── main/
│               ├── kotlin/com/yourcompany/yourapp/
│               │   ├── MainApplication.kt          ⭐ WAJIB
│               │   └── MainActivity.kt             ⭐ WAJIB
│               └── AndroidManifest.xml             ⭐ UPDATE
├── lib/
│   ├── main.dart                                   ⭐ UPDATE
│   ├── screens/
│   │   ├── cashier_screen.dart                     ⭐ BUAT BARU
│   │   └── customer_screen.dart                    ⭐ BUAT BARU
│   └── services/                                   📁 OPTIONAL
│       └── dual_display_service.dart               📄 OPTIONAL
└── pubspec.yaml                                    ⭐ CEK DEPENDENCIES
```

## 🔧 Langkah-langkah Setup

### 1. Buat MainApplication.kt

**Path:** `android/app/src/main/kotlin/com/yourcompany/yourapp/MainApplication.kt`

```kotlin
package com.yourcompany.yourapp  // ⚠️ GANTI SESUAI PROJECT ANDA

import io.flutter.app.FlutterApplication
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

class MainApplication : FlutterApplication() {
    lateinit var engineMain: FlutterEngine
    lateinit var engineSecondary: FlutterEngine

    override fun onCreate() {
        super.onCreate()

        engineMain = FlutterEngine(this)
        engineMain.navigationChannel.setInitialRoute("/main")

        engineSecondary = FlutterEngine(this)
        engineSecondary.navigationChannel.setInitialRoute("/customer")

        engineMain.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )

        engineSecondary.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
    }
}
```

### 2. Update MainActivity.kt

**Path:** `android/app/src/main/kotlin/com/yourcompany/yourapp/MainActivity.kt`

```kotlin
package com.yourcompany.yourapp  // ⚠️ GANTI SESUAI PROJECT ANDA

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.hardware.display.DisplayManager
import android.app.Presentation
import android.view.Display
import android.os.Bundle
import android.widget.LinearLayout
import android.widget.TextView
import android.graphics.Color
import android.view.Gravity

class MainActivity : FlutterActivity() {
    private val CHANNEL = "dual_display"
    private var customerPresentation: CustomerPresentation? = null

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return (applicationContext as MainApplication).engineMain
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkSecondaryDisplay" -> {
                    try {
                        val displayManager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
                        val displays = displayManager.displays
                        val hasSecondary = displays.size > 1

                        var iMinSecondaryDisplay: Display? = null
                        for (display in displays) {
                            if (display.displayId != Display.DEFAULT_DISPLAY) {
                                iMinSecondaryDisplay = display
                                break
                            }
                        }

                        val displayInfo = if (hasSecondary && iMinSecondaryDisplay != null) {
                            mapOf(
                                "width" to iMinSecondaryDisplay.mode.physicalWidth,
                                "height" to iMinSecondaryDisplay.mode.physicalHeight,
                                "name" to (iMinSecondaryDisplay.name ?: "iMin Customer Display"),
                                "displayId" to iMinSecondaryDisplay.displayId,
                                "isIMinDevice" to true
                            )
                        } else null

                        result.success(mapOf(
                            "hasSecondaryDisplay" to hasSecondary,
                            "displayInfo" to displayInfo,
                            "totalDisplays" to displays.size,
                            "deviceType" to "iMin POS"
                        ))
                    } catch (e: Exception) {
                        result.success(mapOf(
                            "hasSecondaryDisplay" to false,
                            "error" to e.message,
                            "deviceType" to "iMin POS"
                        ))
                    }
                }
                "openSecondary" -> {
                    try {
                        val displayManager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
                        val displays = displayManager.displays

                        if (displays.size > 1) {
                            var secondaryDisplay: Display? = null
                            for (display in displays) {
                                if (display.displayId != Display.DEFAULT_DISPLAY) {
                                    secondaryDisplay = display
                                    break
                                }
                            }

                            if (secondaryDisplay != null) {
                                customerPresentation = CustomerPresentation(this, secondaryDisplay)
                                customerPresentation?.show()

                                result.success(mapOf(
                                    "success" to true,
                                    "message" to "iMin Customer Display opened"
                                ))
                            } else {
                                result.success(mapOf("success" to false, "error" to "No secondary display"))
                            }
                        } else {
                            result.success(mapOf("success" to false, "error" to "Single display only"))
                        }
                    } catch (e: Exception) {
                        result.success(mapOf("success" to false, "error" to e.message))
                    }
                }
                "closeSecondary" -> {
                    try {
                        customerPresentation?.dismiss()
                        customerPresentation = null
                        result.success(mapOf("success" to true))
                    } catch (e: Exception) {
                        result.success(mapOf("success" to false, "error" to e.message))
                    }
                }
                "updateCustomerDisplay" -> {
                    try {
                        val data = call.arguments as? Map<String, Any>
                        customerPresentation?.updateContent(data ?: emptyMap())
                        result.success(mapOf("success" to true))
                    } catch (e: Exception) {
                        result.success(mapOf("success" to false, "error" to e.message))
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}

class CustomerPresentation(context: Context, display: Display) : Presentation(context, display) {
    private lateinit var welcomeText: TextView
    private lateinit var contentText: TextView
    private lateinit var promoText: TextView
    private lateinit var orderText: TextView
    private lateinit var totalText: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val layout = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#1565C0"))  // ⚠️ GANTI WARNA SESUAI BRAND
            setPadding(40, 40, 40, 40)
        }

        welcomeText = TextView(context).apply {
            text = "🎉 SELAMAT DATANG! 🎉"
            textSize = 32f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 30)
        }

        val storeText = TextView(context).apply {
            text = "NAMA TOKO ANDA"  // ⚠️ GANTI DENGAN NAMA TOKO ANDA
            textSize = 24f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 40)
        }

        orderText = TextView(context).apply {
            text = ""
            textSize = 18f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 20)
        }

        totalText = TextView(context).apply {
            text = ""
            textSize = 24f
            setTextColor(Color.parseColor("#FFD700"))
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 30)
        }

        contentText = TextView(context).apply {
            text = "Terima kasih telah berbelanja\nPesanan Anda sedang diproses..."
            textSize = 16f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 30)
        }

        promoText = TextView(context).apply {
            text = "🎊 PROMO HARI INI 🎊\nBeli 2 Gratis 1!"  // ⚠️ GANTI SESUAI PROMO ANDA
            textSize = 14f
            setTextColor(Color.parseColor("#FFD700"))
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#FF6600"))
            setPadding(20, 15, 20, 15)
        }

        layout.addView(welcomeText)
        layout.addView(storeText)
        layout.addView(orderText)
        layout.addView(totalText)
        layout.addView(contentText)
        layout.addView(promoText)
        setContentView(layout)

        window?.let { window ->
            window.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            window.addFlags(android.view.WindowManager.LayoutParams.FLAG_FULLSCREEN)
        }
    }

    fun updateContent(data: Map<String, Any>) {
        val message = data["message"] as? String
        val orderInfo = data["orderInfo"] as? String
        val totalAmount = data["totalAmount"] as? Number
        val paymentStatus = data["paymentStatus"] as? String
        val promoMessage = data["promoMessage"] as? String

        if (message != null) {
            welcomeText.text = message
        }

        if (orderInfo != null) {
            orderText.text = "📋 Pesanan:\n$orderInfo"
        } else {
            orderText.text = ""
        }

        if (totalAmount != null) {
            totalText.text = "💰 Total: Rp ${String.format("%,.0f", totalAmount.toDouble())}"
        } else {
            totalText.text = ""
        }

        val content = when (paymentStatus) {
            "processing" -> "⏳ Sedang memproses pembayaran..."
            "success" -> "✅ Pembayaran berhasil!\nTerima kasih!"
            "failed" -> "❌ Pembayaran gagal\nSilakan coba lagi"
            else -> "Terima kasih telah berbelanja\nPesanan Anda sedang diproses..."
        }

        contentText.text = content

        if (promoMessage != null) {
            promoText.text = "🎊 PROMO SPESIAL 🎊\n$promoMessage"
        }
    }
}
```

### 3. Update AndroidManifest.xml

**Path:** `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />

    <application
        android:label="your_app_name"
        android:name=".MainApplication"  <!-- ⚠️ TAMBAHKAN INI -->
        android:icon="@mipmap/ic_launcher">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme" />

            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

### 4. Update main.dart

**Path:** `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/cashier_screen.dart';
import 'screens/customer_screen.dart';

void main() {
  runApp(const YourPOSApp());  // ⚠️ GANTI NAMA APP
}

class YourPOSApp extends StatelessWidget {  // ⚠️ GANTI NAMA CLASS
  const YourPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your POS App',  // ⚠️ GANTI TITLE
      theme: ThemeData(
        primarySwatch: Colors.blue,  // ⚠️ GANTI WARNA SESUAI BRAND
        useMaterial3: true,
      ),
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
    if (!isMethodChannelReady) return;

    try {
      final result = await platform.invokeMethod('checkSecondaryDisplay');
      setState(() {
        hasSecondaryDisplay = result['hasSecondaryDisplay'] ?? false;
        final totalDisplays = result['totalDisplays'] ?? 1;
        final deviceType = result['deviceType'] ?? 'Unknown';
        final isIMinDevice = result['displayInfo']?['isIMinDevice'] ?? false;

        if (hasSecondaryDisplay && isIMinDevice) {
          displayStatus = 'iMin Customer Display ready ($totalDisplays displays)';
        } else if (hasSecondaryDisplay) {
          displayStatus = 'Dual display ready ($totalDisplays displays)';
        } else {
          displayStatus = '$deviceType - Single display ($totalDisplays display)';
        }
      });
    } catch (e) {
      setState(() {
        displayStatus = 'Error: $e';
      });
    }
  }

  Future<void> _toggleCustomerDisplay() async {
    if (!isMethodChannelReady) return;

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

        await _updateCustomerContent({
          'message': 'Selamat datang di Toko Anda!',  // ⚠️ GANTI PESAN
          'status': 'ready'
        });
      }
    } catch (e) {
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
    } catch (e) {
      debugPrint('Error updating customer content: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS - Layar Kasir'),  // ⚠️ GANTI TITLE
        backgroundColor: Colors.blue[700],  // ⚠️ GANTI WARNA
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
            onPressed: isMethodChannelReady ? _toggleCustomerDisplay : null,
            tooltip: 'Toggle Customer Display',
          ),

          // ⚠️ TAMBAHKAN TOMBOL TEST
          if (isCustomerDisplayActive)
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () => _updateCustomerContent({
                'message': 'Test dari kasir',
                'orderInfo': 'Nasi Gudeg + Es Teh',
                'totalAmount': 25000,
                'paymentStatus': 'processing',
              }),
              tooltip: 'Test Update',
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: isCustomerDisplayActive ? Colors.green[50] : Colors.orange[50],
            child: Text(
              displayStatus,
              style: TextStyle(
                color: isCustomerDisplayActive ? Colors.green[700] : Colors.orange[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Expanded(
            child: CashierScreen(),  // ⚠️ IMPLEMENTASIKAN SCREEN INI
          ),
        ],
      ),
    );
  }
}

class CustomerDisplayScreen extends StatelessWidget {
  const CustomerDisplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.blue,
      body: CustomerScreen(),  // ⚠️ IMPLEMENTASIKAN SCREEN INI
    );
  }
}
```

### 5. Buat cashier_screen.dart

**Path:** `lib/screens/cashier_screen.dart`

```dart
import 'package:flutter/material.dart';

class CashierScreen extends StatelessWidget {
  const CashierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.point_of_sale,
            size: 100,
            color: Colors.blue,
          ),
          SizedBox(height: 20),
          Text(
            'Interface Kasir Anda',  // ⚠️ IMPLEMENTASIKAN UI KASIR DI SINI
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(height: 10),
          Text(
            'Tambahkan menu, keranjang, dan pembayaran di sini',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
```

### 6. Buat customer_screen.dart

**Path:** `lib/screens/customer_screen.dart`

```dart
import 'package:flutter/material.dart';

class CustomerScreen extends StatelessWidget {
  const CustomerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '🎉 SELAMAT DATANG! 🎉',
            style: TextStyle(
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Terima kasih telah berbelanja',  // ⚠️ KUSTOMISASI PESAN
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
```

## ✅ Checklist Setup

- [ ] Copy `MainApplication.kt` dan ganti package name
- [ ] Copy `MainActivity.kt` dan ganti package name
- [ ] Update `AndroidManifest.xml` tambahkan `android:name=".MainApplication"`
- [ ] Copy `main.dart` dan ganti nama app/class
- [ ] Buat `cashier_screen.dart`
- [ ] Buat `customer_screen.dart`
- [ ] Ganti nama toko di `CustomerPresentation`
- [ ] Ganti warna brand di semua file
- [ ] Test di device iMin fisik

## 🎯 Yang Harus Diganti

| File                 | Yang Harus Diganti | Contoh                           |
| -------------------- | ------------------ | -------------------------------- |
| `MainApplication.kt` | Package name       | `com.yourcompany.yourapp`        |
| `MainActivity.kt`    | Package name       | `com.yourcompany.yourapp`        |
| `MainActivity.kt`    | Nama toko          | `"NAMA TOKO ANDA"`               |
| `MainActivity.kt`    | Warna background   | `Color.parseColor("#1565C0")`    |
| `MainActivity.kt`    | Pesan promo        | `"Beli 2 Gratis 1!"`             |
| `main.dart`          | Nama app           | `YourPOSApp`                     |
| `main.dart`          | Title              | `"Your POS App"`                 |
| `main.dart`          | Warna tema         | `Colors.blue`                    |
| `main.dart`          | Pesan welcome      | `"Selamat datang di Toko Anda!"` |

## 🚀 Ready to Go!

Setelah semua file di-copy dan disesuaikan, jalankan:

```bash
flutter clean
flutter pub get
flutter run -d [imin_device_id]
```

**Selamat! Dual display iMin POS Anda sudah siap! 🎉**
