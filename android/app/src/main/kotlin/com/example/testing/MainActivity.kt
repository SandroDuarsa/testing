package com.example.testing

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.content.Intent
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
                                // This could be iMin customer display
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
                            // Find secondary display (iMin customer display)
                            var secondaryDisplay: Display? = null
                            for (display in displays) {
                                if (display.displayId != Display.DEFAULT_DISPLAY) {
                                    secondaryDisplay = display
                                    break
                                }
                            }
                            
                            if (secondaryDisplay != null) {
                                // Create presentation on iMin customer display
                                customerPresentation = CustomerPresentation(this, secondaryDisplay)
                                customerPresentation?.show()
                                
                                result.success(mapOf(
                                    "success" to true, 
                                    "message" to "iMin Customer Display opened",
                                    "displayId" to secondaryDisplay.displayId
                                ))
                            } else {
                                result.success(mapOf(
                                    "success" to false, 
                                    "error" to "No secondary display found"
                                ))
                            }
                        } else {
                            result.success(mapOf(
                                "success" to false, 
                                "error" to "Only one display available"
                            ))
                        }
                    } catch (e: Exception) {
                        result.success(mapOf(
                            "success" to false, 
                            "error" to e.message
                        ))
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
            text = "WARUNG MAKAN BAHAGIA"
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
    
    fun showTestContent() {
        welcomeText.text = "🔧 TEST MODE - iMin POS 🔧"
        orderText.text = "📋 Test Order:\nNasi Gudeg + Es Teh Manis"
        totalText.text = "💰 Total: Rp 20.000"
        contentText.text = "✅ SISTEM iMin CUSTOMER DISPLAY\nBERFUNGSI DENGAN BAIK!"
        promoText.text = "🎉 iMin POS DUAL DISPLAY READY! 🎉"
    }
}