package com.example.testing

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