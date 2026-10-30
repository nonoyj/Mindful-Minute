package com.example.mindful_minute

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.SystemClock
import org.json.JSONArray
import java.util.Calendar
import kotlin.math.max
import kotlin.math.roundToInt

/**
 * Native, sticky foreground service that watches your monitored apps.
 * It does NOT depend on the Flutter UI, so it keeps working after you close
 * (swipe away) the app. It reads the same settings the app saves, warns at
 * 70/80/90/100% and at 100% arms the wellness-break lock (BreakGuard).
 */
class MonitorService : Service() {

    companion object {
        private const val PREFS = "FlutterSharedPreferences"
        private const val FG_CHANNEL = "mindful_foreground"
        private const val WARN_CHANNEL = "usage_warnings"
        private const val BREAK_CHANNEL = "wellness_break"
        private const val FG_ID = 888
        private const val POLL_MS = 15_000L
        private const val MAX_SESSION_MS = 2L * 60 * 60 * 1000
        private const val INACTIVITY_MS = 30L * 60 * 1000

        // threshold, storage suffix, tier index (0=70% .. 3=100%)
        private val TIERS = listOf(
            Triple(1.0, "100", 3), Triple(0.9, "90", 2),
            Triple(0.8, "80", 1), Triple(0.7, "70", 0)
        )

        fun start(ctx: Context) {
            val i = Intent(ctx, MonitorService::class.java)
            try {
                if (Build.VERSION.SDK_INT >= 26) ctx.startForegroundService(i) else ctx.startService(i)
            } catch (_: Exception) {}
        }

        fun stop(ctx: Context) {
            ctx.stopService(Intent(ctx, MonitorService::class.java))
        }

        fun notifId(pkg: String, tier: Int): Int {
            var h = 17
            for (c in pkg) h = (h * 31 + c.code) and 0x7fffffff
            return (h xor tier) and 0x7fffffff
        }

        fun cancelWarnings(ctx: Context, pkg: String) {
            val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            for (t in 0..3) nm.cancel(notifId(pkg, t))
        }
    }

    private data class App(val pkg: String, val name: String, val limit: Int)

    private lateinit var thread: HandlerThread
    private lateinit var handler: Handler
    private val lastUsage = HashMap<String, Int>()
    private val lastChange = HashMap<String, Long>()
    private val activeWarnings = HashSet<String>()

    private val tick = object : Runnable {
        override fun run() {
            try { check() } catch (_: Exception) {}
            handler.postDelayed(this, POLL_MS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        thread = HandlerThread("mindful-monitor").also { it.start() }
        handler = Handler(thread.looper)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createChannels()
        try {
            goForeground()
        } catch (_: Exception) {
            stopSelf()
            return START_NOT_STICKY
        }
        handler.removeCallbacks(tick)
        handler.post(tick)
        return START_STICKY // Android restarts us if the system kills us
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // App swiped from recents: ask Android to make sure we are still alive.
        try {
            val pi = PendingIntent.getService(
                applicationContext, 1, Intent(applicationContext, MonitorService::class.java),
                PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
            )
            (getSystemService(Context.ALARM_SERVICE) as AlarmManager)
                .set(AlarmManager.ELAPSED_REALTIME, SystemClock.elapsedRealtime() + 1500, pi)
        } catch (_: Exception) {}
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        thread.quitSafely()
        super.onDestroy()
    }

    // ------------------------------------------------------------ monitoring
    private fun check() {
        val sp = getSharedPreferences(PREFS, MODE_PRIVATE)
        val apps = ArrayList<App>()
        sp.getString("flutter.monitoredApps", null)?.let { json ->
            val arr = JSONArray(json)
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                if (o.optBoolean("enabled", true)) {
                    val p = o.getString("packageName")
                    apps.add(App(p, o.optString("displayName", p), o.optInt("dailyLimitMinutes", 0)))
                }
            }
        }
        if (apps.isEmpty()) {
            stopSelf()
            return
        }

        val resets = HashMap<String, Long>()
        for (a in apps) resets[a.pkg] = sp.getLong("flutter.usage_reset_${a.pkg}", 0L)
        val usage = usageMinutes(apps.map { it.pkg }.toSet(), resets)
        val now = System.currentTimeMillis()

        for (a in apps) {
            val used = usage[a.pkg] ?: 0
            val prev = lastUsage[a.pkg]
            if (prev == null || used != prev) lastChange[a.pkg] = now
            lastUsage[a.pkg] = used

            // 30 minutes away from the app: clear its warning notifications
            if (a.pkg in activeWarnings && now - (lastChange[a.pkg] ?: now) >= INACTIVITY_MS) {
                activeWarnings.remove(a.pkg)
                cancelWarnings(this, a.pkg)
            }

            if (a.limit <= 0) continue
            val fraction = used.toDouble() / a.limit
            for ((threshold, suffix, idx) in TIERS) {
                if (fraction >= threshold) {
                    val key = "flutter.warned_${a.pkg}_${suffix}_${today()}"
                    if (!sp.getBoolean(key, false)) {
                        sp.edit().putBoolean(key, true).apply()
                        activeWarnings.add(a.pkg)
                        notifyTier(a, used, suffix, idx)
                        if (idx == 3) armBreak(sp, a.pkg)
                    }
                    break // only the highest applicable tier
                }
            }
        }
    }

    /** Foreground time today per package, counting only time after the last reset. */
    private fun usageMinutes(pkgs: Set<String>, resets: Map<String, Long>): Map<String, Int> {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
        }
        val now = System.currentTimeMillis()
        val events = usm.queryEvents(cal.timeInMillis, now)
        val e = UsageEvents.Event()
        val open = HashMap<String, Long>() // "pkg/class" -> start
        val total = HashMap<String, Long>()

        fun add(pkg: String, start: Long, end: Long) {
            val s = max(start, resets[pkg] ?: 0L)
            var d = end - s
            if (d <= 0) return
            if (d > MAX_SESSION_MS) d = MAX_SESSION_MS
            total[pkg] = (total[pkg] ?: 0L) + d
        }

        while (events.hasNextEvent()) {
            events.getNextEvent(e)
            val t = e.timeStamp
            val type = e.eventType
            val pkg = e.packageName ?: ""
            if (type == 16) { // SCREEN_NON_INTERACTIVE ends everything
                for ((k, s) in open) {
                    val p = k.substringBefore('/')
                    if (p in pkgs) add(p, s, t)
                }
                open.clear()
            } else if (pkg in pkgs) {
                val key = "$pkg/${e.className}"
                if (type == 1) {
                    if (!open.containsKey(key)) open[key] = t
                } else if (type == 2 || type == 23) {
                    val s = open.remove(key)
                    if (s != null) add(pkg, s, t)
                }
            }
        }
        for ((k, s) in open) {
            val p = k.substringBefore('/')
            if (p in pkgs) add(p, s, now)
        }
        return total.mapValues { (it.value / 60000.0).roundToInt() }
    }

    private fun today(): String {
        val c = Calendar.getInstance()
        return String.format("%04d-%02d-%02d", c.get(Calendar.YEAR), c.get(Calendar.MONTH) + 1, c.get(Calendar.DAY_OF_MONTH))
    }

    /** At 100%: lock the phone into the wellness break (see BreakGuard). */
    private fun armBreak(sp: android.content.SharedPreferences, pkg: String) {
        sp.edit()
            .putString("flutter.guard_pkg", pkg)
            .putLong("flutter.guard_started_at", System.currentTimeMillis())
            .putBoolean("flutter.guard_music", true)
            .putBoolean("flutter.guard_active", true)
            .apply()
    }

    // --------------------------------------------------------- notifications
    private fun createChannels() {
        if (Build.VERSION.SDK_INT < 26) return
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(NotificationChannel(FG_CHANNEL, "Mindful Minute monitoring", NotificationManager.IMPORTANCE_LOW))
        nm.createNotificationChannel(NotificationChannel(WARN_CHANNEL, "Usage Warnings", NotificationManager.IMPORTANCE_HIGH))
        nm.createNotificationChannel(NotificationChannel(BREAK_CHANNEL, "Wellness Break", NotificationManager.IMPORTANCE_HIGH))
    }

    private fun builder(channel: String): Notification.Builder =
        if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, channel)
        else @Suppress("DEPRECATION") Notification.Builder(this)

    private fun openAppIntent(code: Int): PendingIntent = PendingIntent.getActivity(
        this, code,
        Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
    )

    private fun goForeground() {
        val n = builder(FG_CHANNEL)
            .setContentTitle("Mindful Minute")
            .setContentText("Watching your app limits")
            .setSmallIcon(applicationInfo.icon)
            .setContentIntent(openAppIntent(0))
            .setOngoing(true)
            .build()
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(FG_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(FG_ID, n)
        }
    }

    private fun notifyTier(a: App, used: Int, suffix: String, idx: Int) {
        val msg = when (suffix) {
            "70" -> "${a.name}: ${used}m of ${a.limit}m used (70%). Take a one-minute break?"
            "80" -> "${a.name}: 80% of your daily limit used. Try a one-minute activity."
            "90" -> "${a.name}: almost there, 90% used! A Mindful Minute can help."
            else -> "${a.name}: daily limit reached. Time for your Mindful Minute!"
        }
        val pi = openAppIntent(idx + 1)
        val b = builder(if (idx == 3) BREAK_CHANNEL else WARN_CHANNEL)
            .setContentTitle("Mindful Minute")
            .setContentText(msg)
            .setStyle(Notification.BigTextStyle().bigText(msg))
            .setSmallIcon(applicationInfo.icon)
            .setContentIntent(pi)
            .setAutoCancel(true)
        if (idx == 3) b.setFullScreenIntent(pi, true) // fallback way to open the app
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(notifId(a.pkg, idx), b.build())
    }
}
