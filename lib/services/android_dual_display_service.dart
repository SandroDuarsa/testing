import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AndroidDualDisplayService {
  static const MethodChannel _channel = MethodChannel('pos_dual_display');

  bool _isInitialized = false;
  bool _hasSecondaryDisplay = false;
  bool _isCustomerDisplayActive = false;

  bool get isInitialized => _isInitialized;
  bool get hasSecondaryDisplay => _hasSecondaryDisplay;
  bool get isCustomerDisplayActive => _isCustomerDisplayActive;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Cek apakah ada secondary display
      final result = await _channel.invokeMethod('checkSecondaryDisplay');
      _hasSecondaryDisplay = result['hasSecondaryDisplay'] ?? false;

      debugPrint('AndroidDualDisplayService initialized');
      debugPrint('Secondary display available: $_hasSecondaryDisplay');

      if (_hasSecondaryDisplay) {
        final displayInfo = result['displayInfo'] as Map?;
        if (displayInfo != null) {
          debugPrint('Secondary display info: $displayInfo');
        }
      }
    } catch (e) {
      debugPrint('Error initializing dual display service: $e');
      // Fallback: assume no secondary display
      _hasSecondaryDisplay = false;
    }

    _isInitialized = true;
  }

  Future<bool> openCustomerDisplay() async {
    if (!_isInitialized) {
      debugPrint('Service not initialized');
      return false;
    }

    try {
      if (_hasSecondaryDisplay) {
        // Buka presentation di secondary display
        final result = await _channel.invokeMethod('openPresentation', {
          'content': 'customer_screen',
          'theme': 'dark',
        });

        _isCustomerDisplayActive = result['success'] ?? false;
        debugPrint(
          'Presentation opened on secondary display: $_isCustomerDisplayActive',
        );
      } else {
        // Simulasi untuk single display
        _isCustomerDisplayActive = true;
        debugPrint('Customer display activated (simulation mode)');
      }

      return _isCustomerDisplayActive;
    } catch (e) {
      debugPrint('Error opening customer display: $e');
      return false;
    }
  }

  Future<void> closeCustomerDisplay() async {
    if (!_isCustomerDisplayActive) return;

    try {
      if (_hasSecondaryDisplay) {
        await _channel.invokeMethod('closePresentation');
        debugPrint('Presentation closed');
      } else {
        debugPrint('Customer display deactivated (simulation mode)');
      }

      _isCustomerDisplayActive = false;
    } catch (e) {
      debugPrint('Error closing customer display: $e');
    }
  }

  Future<void> updateCustomerContent({
    String? orderInfo,
    double? totalAmount,
    String? paymentStatus,
    String? promoMessage,
  }) async {
    if (!_isCustomerDisplayActive) return;

    try {
      final data = <String, dynamic>{};
      if (orderInfo != null) data['orderInfo'] = orderInfo;
      if (totalAmount != null) data['totalAmount'] = totalAmount;
      if (paymentStatus != null) data['paymentStatus'] = paymentStatus;
      if (promoMessage != null) data['promoMessage'] = promoMessage;

      if (_hasSecondaryDisplay) {
        await _channel.invokeMethod('updatePresentationContent', data);
        debugPrint('Customer display content updated: $data');
      } else {
        debugPrint('Customer display content updated (simulation): $data');
      }
    } catch (e) {
      debugPrint('Error updating customer content: $e');
    }
  }

  Future<void> testCustomerDisplay() async {
    try {
      if (_hasSecondaryDisplay) {
        await _channel.invokeMethod('testPresentation');
        debugPrint('Test presentation displayed');
      } else {
        debugPrint('Test display (simulation mode)');
      }
    } catch (e) {
      debugPrint('Error testing customer display: $e');
    }
  }

  void dispose() {
    if (_isCustomerDisplayActive) {
      closeCustomerDisplay();
    }
    _isInitialized = false;
    debugPrint('AndroidDualDisplayService disposed');
  }
}

// Native Android implementation guide:
/*
Untuk implementasi native Android, buat file berikut:

1. android/app/src/main/kotlin/MainActivity.kt:

```kotlin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.hardware.display.DisplayManager
import android.view.Display
import android.app.Presentation
import android.content.Context
import android.os.Bundle
import android.widget.TextView

class MainActivity: FlutterActivity() {
    private val CHANNEL = "pos_dual_display"
    private var customerPresentation: CustomerPresentation? = null
    private lateinit var displayManager: DisplayManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        displayManager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkSecondaryDisplay" -> {
                    val displays = displayManager.displays
                    val hasSecondary = displays.size > 1
                    val displayInfo = if (hasSecondary) {
                        mapOf(
                            "width" to displays[1].mode.physicalWidth,
                            "height" to displays[1].mode.physicalHeight,
                            "density" to displays[1].densityDpi
                        )
                    } else null
                    
                    result.success(mapOf(
                        "hasSecondaryDisplay" to hasSecondary,
                        "displayInfo" to displayInfo
                    ))
                }
                "openPresentation" -> {
                    val displays = displayManager.displays
                    if (displays.size > 1) {
                        customerPresentation = CustomerPresentation(this, displays[1])
                        customerPresentation?.show()
                        result.success(mapOf("success" to true))
                    } else {
                        result.success(mapOf("success" to false))
                    }
                }
                "closePresentation" -> {
                    customerPresentation?.dismiss()
                    customerPresentation = null
                    result.success(null)
                }
                "updatePresentationContent" -> {
                    customerPresentation?.updateContent(call.arguments as Map<String, Any>)
                    result.success(null)
                }
                "testPresentation" -> {
                    customerPresentation?.showTestContent()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}

class CustomerPresentation(context: Context, display: Display) : Presentation(context, display) {
    private lateinit var contentText: TextView
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Create customer display layout
        val layout = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#1565C0"))
            setPadding(50, 50, 50, 50)
        }
        
        // Welcome text
        val welcomeText = TextView(context).apply {
            text = "Selamat Datang!"
            textSize = 32f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
        }
        
        // Content text
        contentText = TextView(context).apply {
            text = "Terima kasih telah berbelanja"
            textSize = 18f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
        }
        
        layout.addView(welcomeText)
        layout.addView(contentText)
        setContentView(layout)
    }
    
    fun updateContent(data: Map<String, Any>) {
        val orderInfo = data["orderInfo"] as? String
        val totalAmount = data["totalAmount"] as? Double
        val paymentStatus = data["paymentStatus"] as? String
        
        var content = "Terima kasih telah berbelanja\n\n"
        if (orderInfo != null) content += "Pesanan: $orderInfo\n"
        if (totalAmount != null) content += "Total: Rp ${totalAmount.toInt()}\n"
        if (paymentStatus != null) content += "Status: $paymentStatus"
        
        contentText.text = content
    }
    
    fun showTestContent() {
        contentText.text = "TEST DISPLAY\nLayar customer berfungsi dengan baik!"
    }
}
```

2. android/app/src/main/AndroidManifest.xml:
Tambahkan permission:
```xml
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
```
*/
