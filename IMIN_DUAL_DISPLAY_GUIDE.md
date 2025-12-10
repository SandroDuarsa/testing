# Panduan Implementasi Dual Display untuk iMin POS

Dokumentasi lengkap untuk mengimplementasikan dual display (layar kasir + customer display) pada device iMin POS menggunakan Flutter.

## 📋 Daftar Isi

1. [Persyaratan](#persyaratan)
2. [Struktur Project](#struktur-project)
3. [Implementasi Android Native](#implementasi-android-native)
4. [Implementasi Flutter](#implementasi-flutter)
5. [Konfigurasi](#konfigurasi)
6. [Testing](#testing)
7. [Troubleshooting](#troubleshooting)

## 🔧 Persyaratan

### Hardware

- Device iMin POS dengan dual display support
- Android API level 21+ (Android 5.0+)

### Software

- Flutter SDK 3.8.1+
- Android Studio / VS Code
- Kotlin support

### Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
```

## 🏗️ Struktur Project

```
your_project/
├── lib/
│   ├── main.dart                 # Entry point dengan routing
│   ├── screens/
│   │   ├── cashier_screen.dart   # Interface kasir
│   │   └── customer_screen.dart  # Interface customer
│   └── services/
│       └── dual_display_service.dart  # Service untuk komunikasi
├── android/
│   └── app/src/main/kotlin/com/yourpackage/yourapp/
│       ├── MainApplication.kt    # Inisialisasi FlutterEngine
│       └── MainActivity.kt       # Method channel & Presentation API
└── android/app/src/main/AndroidManifest.xml
```

## 📱 Implementasi Android Native

### 1. MainApplication.kt

Buat file `android/app/src/main/kotlin/com/yourpackage/yourapp/MainApplication.kt`:

```kotlin
package com.yourpackage.yourapp

import io.flutter.app.FlutterApplication
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

class MainApplication : FlutterApplication() {
    lateinit var engineMain: FlutterEngine
    lateinit var engineSecondary: FlutterEngine

    override fun onCreate() {
        super.onCreate()

        // Initialize main engine for cashier screen
        engineMain = FlutterEngine(this)
        engineMain.navigationChannel.setInitialRoute("/main")

        // Initialize secondary engine for customer display
        engineSecondary = FlutterEngine(this)
        engineSecondary.navigationChannel.setInitialRoute("/customer")

        // Start Dart execution for both engines
        engineMain.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )

        engineSecondary.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
    }
}
```

### 2. MainActivity.kt

Update `android/app/src/main/kotlin/com/yourpackage/yourapp/MainActivity.kt`:

```kotlin
package com.yourpackage.yourapp

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

                        // Check for iMin specific displays
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
                                    "message" to "iMin Customer Display opened",
                                    "displayId" to secondaryDisplay.displayId
                                ))
                            } else {
                                result.success(mapOf("success" to false, "error" to "No secondary display found"))
                            }
                        } else {
                            result.success(mapOf("success" to false, "error" to "Only one display available"))
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

        // Create iMin customer display layout
        val layout = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#1565C0"))
            setPadding(40, 40, 40, 40)
        }

        // Welcome text
        welcomeText = TextView(context).apply {
            text = "🎉 SELAMAT DATANG! 🎉"
            textSize = 32f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 30)
        }

        // Store name
        val storeText = TextView(context).apply {
            text = "NAMA TOKO ANDA"  // Ganti dengan nama toko
            textSize = 24f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 40)
        }

        // Order info
        orderText = TextView(context).apply {
            text = ""
            textSize = 18f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 20)
        }

        // Total amount
        totalText = TextView(context).apply {
            text = ""
            textSize = 24f
            setTextColor(Color.parseColor("#FFD700"))
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 30)
        }

        // Content text
        contentText = TextView(context).apply {
            text = "Terima kasih telah berbelanja\nPesanan Anda sedang diproses..."
            textSize = 16f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 30)
        }

        // Promo text
        promoText = TextView(context).apply {
            text = "🎊 PROMO HARI INI 🎊\nBeli 2 Gratis 1 untuk semua minuman!"
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

        // Set window properties for iMin customer display
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
        val timestamp = data["timestamp"] as? String

        // Update welcome message
        if (message != null) {
            welcomeText.text = message
        }

        // Update order info
        if (orderInfo != null) {
            orderText.text = "📋 Pesanan Anda:\n$orderInfo"
        } else {
            orderText.text = ""
        }

        // Update total amount
        if (totalAmount != null) {
            totalText.text = "💰 Total: Rp ${String.format("%,.0f", totalAmount.toDouble())}"
        } else {
            totalText.text = ""
        }

        // Update content based on status
        var content = when (paymentStatus) {
            "processing" -> "⏳ Sedang memproses pembayaran..."
            "success" -> "✅ Pembayaran berhasil!\nTerima kasih!"
            "failed" -> "❌ Pembayaran gagal\nSilakan coba lagi"
            else -> "Terima kasih telah berbelanja\nPesanan Anda sedang diproses..."
        }

        if (timestamp != null) {
            content += "\n\nUpdate: ${timestamp.substring(11, 19)}"
        }

        contentText.text = content

        // Update promo
        if (promoMessage != null) {
            promoText.text = "🎊 PROMO SPESIAL 🎊\n$promoMessage"
        }
    }
}
```

### 3. AndroidManifest.xml

Update `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions for dual display functionality -->
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />

    <application
        android:label="your_app_name"
        android:name=".MainApplication"  <!-- Penting: gunakan MainApplication -->
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

## 🎯 Implementasi Flutter

### 1. main.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/cashier_screen.dart';
import 'screens/customer_screen.dart';

void main() {
  runApp(const YourPOSApp());
}

class YourPOSApp extends StatelessWidget {
  const YourPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your POS App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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

        // Send initial content
        await _updateCustomerContent({
          'message': 'Selamat datang di Toko Anda!',
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
        title: const Text('POS - Layar Kasir'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          // Status indicators
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

          // Toggle button
          IconButton(
            icon: Icon(
              isCustomerDisplayActive
                ? Icons.visibility_off
                : Icons.visibility,
            ),
            onPressed: isMethodChannelReady ? _toggleCustomerDisplay : null,
            tooltip: 'Toggle Customer Display',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
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

          // Your cashier interface here
          const Expanded(
            child: CashierScreen(),
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
      body: CustomerScreen(),
    );
  }
}
```

### 2. Buat Screen Files

Buat file `lib/screens/cashier_screen.dart`:

```dart
import 'package:flutter/material.dart';

class CashierScreen extends StatelessWidget {
  const CashierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Interface Kasir Anda',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
```

Buat file `lib/screens/customer_screen.dart`:

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
            'Terima kasih telah berbelanja',
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

## ⚙️ Konfigurasi

### 1. Update Package Name

Ganti `com.yourpackage.yourapp` dengan package name project Anda di:

- `MainApplication.kt`
- `MainActivity.kt`
- `AndroidManifest.xml`

### 2. Update App Name

Ganti nama aplikasi di:

- `AndroidManifest.xml` (`android:label`)
- `main.dart` (`title`)

### 3. Kustomisasi Customer Display

Edit `CustomerPresentation.kt` untuk:

- Mengubah nama toko
- Menyesuaikan warna dan layout
- Menambah logo atau branding

## 🧪 Testing

### 1. Test di Device iMin

```bash
flutter run -d [device_id]
```

### 2. Test Method Channel

Tambahkan tombol test di interface kasir:

```dart
ElevatedButton(
  onPressed: () => _updateCustomerContent({
    'message': 'Test Message',
    'orderInfo': 'Nasi Gudeg + Es Teh',
    'totalAmount': 25000,
    'paymentStatus': 'processing',
  }),
  child: const Text('Test Customer Display'),
)
```

### 3. Debug Logs

Monitor logs untuk troubleshooting:

```bash
flutter logs
```

## 🔧 Troubleshooting

### Problem: Method Channel Error

**Solution:**

- Pastikan `MainApplication` terdaftar di `AndroidManifest.xml`
- Cek package name sudah benar
- Restart aplikasi setelah perubahan native code

### Problem: Customer Display Tidak Muncul

**Solution:**

- Cek device iMin memiliki dual display
- Pastikan permission `SYSTEM_ALERT_WINDOW` granted
- Test dengan `adb shell dumpsys display`

### Problem: Content Tidak Update

**Solution:**

- Cek method channel connection
- Pastikan `updateContent()` dipanggil dengan data yang benar
- Monitor logs untuk error

### Problem: Build Error

**Solution:**

- Clean project: `flutter clean`
- Rebuild: `flutter pub get && flutter run`
- Cek Kotlin version compatibility

## 📚 API Reference

### Method Channel Methods

| Method                  | Parameters             | Return                 | Description                    |
| ----------------------- | ---------------------- | ---------------------- | ------------------------------ |
| `checkSecondaryDisplay` | -                      | `Map<String, dynamic>` | Cek ketersediaan dual display  |
| `openSecondary`         | -                      | `Map<String, dynamic>` | Buka customer display          |
| `closeSecondary`        | -                      | `Map<String, dynamic>` | Tutup customer display         |
| `updateCustomerDisplay` | `Map<String, dynamic>` | `Map<String, dynamic>` | Update konten customer display |

### Update Content Parameters

| Parameter       | Type     | Description                                           |
| --------------- | -------- | ----------------------------------------------------- |
| `message`       | `String` | Pesan welcome                                         |
| `orderInfo`     | `String` | Info pesanan                                          |
| `totalAmount`   | `Number` | Total harga                                           |
| `paymentStatus` | `String` | Status pembayaran (`processing`, `success`, `failed`) |
| `promoMessage`  | `String` | Pesan promo                                           |
| `timestamp`     | `String` | Waktu update                                          |

## 🎯 Best Practices

1. **Error Handling**: Selalu wrap method channel calls dengan try-catch
2. **State Management**: Gunakan proper state management untuk sync data
3. **Performance**: Hindari update terlalu sering ke customer display
4. **UI/UX**: Pastikan customer display mudah dibaca dari jarak jauh
5. **Testing**: Test di device fisik, bukan emulator

## 📞 Support

Untuk pertanyaan atau issue:

1. Cek dokumentasi iMin: https://oss-sg.imin.sg/docs/en/CustomerDisplay.html
2. Review kode implementasi di repository ini
3. Test dengan device iMin yang sebenarnya

---

**© 2024 - Panduan Implementasi Dual Display iMin POS**
