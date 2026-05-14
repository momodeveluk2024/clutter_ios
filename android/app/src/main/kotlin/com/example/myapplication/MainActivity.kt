package com.nutrimateapp

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.nutrimateapp/live_updates"
    private lateinit var liveUpdateManager: LiveUpdateManager

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        liveUpdateManager = LiveUpdateManager(context)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startIsland" -> {
                    liveUpdateManager.startIsland()
                    result.success(null)
                }
                "updateIsland" -> {
                    val progress = call.argument<Int>("progress") ?: 0
                    liveUpdateManager.updateIsland(progress)
                    result.success(null)
                }
                "stopIsland" -> {
                    liveUpdateManager.stopIsland()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
