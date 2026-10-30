package com.example.mindful_minute

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import java.io.File
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mindful/guard")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasOverlay" -> result.success(Settings.canDrawOverlays(this))
                    "requestOverlay" -> {
                        startActivity(
                            Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName"))
                        )
                        result.success(null)
                    }
                    "isIgnoringBattery" -> {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "requestIgnoreBattery" -> {
                        startActivity(
                            Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                Uri.parse("package:$packageName"))
                        )
                        result.success(null)
                    }
                    "openBatterySettings" -> {
                        startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                        result.success(null)
                    }
                    "startMonitor" -> {
                        MonitorService.start(this)
                        result.success(null)
                    }
                    "stopMonitor" -> {
                        MonitorService.stop(this)
                        result.success(null)
                    }
                    "cancelWarnings" -> {
                        MonitorService.cancelWarnings(this, call.argument<String>("pkg") ?: "")
                        result.success(null)
                    }
                    "deviceInfo" -> result.success(
                        "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT}), " +
                            "${Build.MANUFACTURER} ${Build.MODEL}"
                    )
                    "sendEmail" -> {
                        val i = Intent(Intent.ACTION_SENDTO).apply {
                            data = Uri.parse("mailto:")
                            putExtra(Intent.EXTRA_EMAIL, arrayOf(call.argument<String>("to") ?: ""))
                            putExtra(Intent.EXTRA_SUBJECT, call.argument<String>("subject") ?: "")
                            putExtra(Intent.EXTRA_TEXT, call.argument<String>("body") ?: "")
                        }
                        try {
                            startActivity(Intent.createChooser(i, "Send feedback"))
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "hasAccessibility" -> {
                        val enabled = Settings.Secure.getString(
                            contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
                        ) ?: ""
                        result.success(enabled.contains("$packageName/"))
                    }
                    "requestAccessibility" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
