package com.example.mindful_minute

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import org.json.JSONArray

/** Restarts the monitor after a reboot or an app update (if any break is on). */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(c: Context, i: Intent) {
        val json = c.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .getString("flutter.monitoredApps", null) ?: return
        try {
            val arr = JSONArray(json)
            var any = false
            for (k in 0 until arr.length()) {
                if (arr.getJSONObject(k).optBoolean("enabled", true)) any = true
            }
            if (any) MonitorService.start(c)
        } catch (_: Exception) {}
    }
}
