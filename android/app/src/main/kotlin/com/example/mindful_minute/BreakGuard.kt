package com.example.mindful_minute

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.graphics.PixelFormat
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import java.io.File
import kotlin.math.PI
import kotlin.math.sin

/**
 * The wellness-break lock.
 *
 * Dart arms it with SharedPreferences flags:
 *   flutter.guard_active : lock on/off
 *   flutter.guard_music  : calming music on/off (only while active)
 *
 * While active it:
 *  - relaunches MainActivity whenever another app/launcher/recents is in front
 *    (polling every 500 ms + instantly on screen on / unlock),
 *  - works with BreakLockService (accessibility) for instant reaction and to
 *    collapse the notification shade,
 *  - plays music on the ALARM stream (works with media muted) and keeps its
 *    volume up,
 *  - shows a 1px invisible overlay so Android allows background launches,
 *  - releases itself after 10 minutes (failsafe).
 */
object BreakGuard {
    private const val PREFS = "FlutterSharedPreferences"
    private const val KEY_ACTIVE = "flutter.guard_active"
    private const val KEY_MUSIC = "flutter.guard_music"
    private const val FAILSAFE_MS = 10 * 60 * 1000L
    private const val TICK_MS = 500L
    private const val EVENT_RESUMED = 1

    /** Never fight these: incoming/emergency calls must always work. */
    private val ALLOWED = setOf(
        "com.android.server.telecom", "com.android.dialer", "com.google.android.dialer",
        "com.android.incallui", "com.samsung.android.incallui", "com.android.phone",
        "com.android.emergency", "com.google.android.apps.safetyhub"
    )

    private lateinit var app: Context
    private val handler = Handler(Looper.getMainLooper())
    var isActive = false
        private set
    val musicPlaying: Boolean get() = track != null || player != null

    private var startedAt = 0L
    private var lastLaunch = 0L
    private var lastFg: String? = null
    private var track: AudioTrack? = null
    private var player: MediaPlayer? = null
    private var dot: View? = null

    private val prefsListener = SharedPreferences.OnSharedPreferenceChangeListener { p, key ->
        if (key == KEY_ACTIVE || key == KEY_MUSIC) sync(p)
    }

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(c: Context, i: Intent) {
            bringToFront(true)
        }
    }

    private val tick = object : Runnable {
        override fun run() {
            if (!isActive) return
            if (System.currentTimeMillis() - startedAt > FAILSAFE_MS) {
                app.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                    .putBoolean(KEY_ACTIVE, false).putBoolean(KEY_MUSIC, false).apply()
                return
            }
            enforce()
            keepVolume()
            handler.postDelayed(this, TICK_MS)
        }
    }

    fun init(ctx: Context) {
        app = ctx.applicationContext
        val p = app.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        p.registerOnSharedPreferenceChangeListener(prefsListener)
        sync(p) // process restarted mid-break -> resume
    }

    fun isAllowed(pkg: String?): Boolean =
        pkg == null || pkg == app.packageName || pkg in ALLOWED

    private fun sync(p: SharedPreferences) {
        if (p.getBoolean(KEY_ACTIVE, false)) start() else stop()
        if (isActive && p.getBoolean(KEY_MUSIC, false)) startMusic() else stopMusic()
    }

    private fun start() {
        if (isActive) return
        isActive = true
        startedAt = System.currentTimeMillis()
        lastFg = null
        val f = IntentFilter(Intent.ACTION_SCREEN_ON).apply { addAction(Intent.ACTION_USER_PRESENT) }
        if (Build.VERSION.SDK_INT >= 33) {
            app.registerReceiver(screenReceiver, f, Context.RECEIVER_NOT_EXPORTED)
        } else {
            app.registerReceiver(screenReceiver, f)
        }
        showDot()
        handler.post(tick)
        bringToFront(true)
    }

    private fun stop() {
        if (!isActive) return
        isActive = false
        handler.removeCallbacks(tick)
        try { app.unregisterReceiver(screenReceiver) } catch (_: Exception) {}
        hideDot()
    }

    // ---------------------------------------------------------- front-most
    private fun enforce() {
        val fg = foregroundPackage() ?: return
        if (!isAllowed(fg)) bringToFront(false)
    }

    private fun foregroundPackage(): String? = try {
        val usm = app.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val end = System.currentTimeMillis()
        val events = usm.queryEvents(end - 15_000, end)
        val e = UsageEvents.Event()
        var last: String? = null
        while (events.hasNextEvent()) {
            events.getNextEvent(e)
            if (e.eventType == EVENT_RESUMED) last = e.packageName
        }
        if (last != null) lastFg = last
        lastFg
    } catch (_: Exception) {
        lastFg
    }

    fun bringToFront(force: Boolean) {
        if (!isActive) return
        val now = System.currentTimeMillis()
        if (now - lastLaunch < (if (force) 150 else 700)) return
        lastLaunch = now
        try {
            app.startActivity(
                Intent(app, MainActivity::class.java).addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                )
            )
        } catch (_: Exception) {
            // no overlay permission: the full-screen notification is the fallback
        }
    }

    // 1px invisible overlay: having an overlay window makes background launches legal.
    private fun showDot() {
        if (dot != null) return
        try {
            if (!Settings.canDrawOverlays(app)) return
            val type = if (Build.VERSION.SDK_INT >= 26)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE
            val lp = WindowManager.LayoutParams(
                1, 1, type,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
                PixelFormat.TRANSLUCENT
            )
            lp.gravity = Gravity.TOP or Gravity.START
            val v = View(app)
            (app.getSystemService(Context.WINDOW_SERVICE) as WindowManager).addView(v, lp)
            dot = v
        } catch (_: Exception) {}
    }

    private fun hideDot() {
        try {
            dot?.let { (app.getSystemService(Context.WINDOW_SERVICE) as WindowManager).removeView(it) }
        } catch (_: Exception) {}
        dot = null
    }

    // ---------------------------------------------------------------- music
    private fun buildPad(): ShortArray {
        val rate = 22050
        val n = rate * 12 // frequencies are m/12 Hz => seamless loop
        val freqs = doubleArrayOf(130.75, 196.0, 261.5, 329.5)
        val out = ShortArray(n)
        for (i in 0 until n) {
            val t = i.toDouble() / rate
            var v = 0.0
            for (k in freqs.indices) {
                val lfo = 0.5 + 0.5 * sin(2 * PI * ((k + 1) / 12.0) * t)
                v += sin(2 * PI * freqs[k] * t) * lfo * 0.2
            }
            out[i] = (v * 32767).toInt().coerceIn(-32768, 32767).toShort()
        }
        return out
    }

    /** Copies the bundled mp3 (assets/audio/limit_screen.mp3) to cache so MediaPlayer can read it. */
    private fun musicFile(): File? = try {
        val f = File(app.cacheDir, "limit_screen.mp3")
        app.assets.open("flutter_assets/assets/audio/limit_screen.mp3").use { input ->
            f.outputStream().use { input.copyTo(it) }
        }
        f
    } catch (_: Exception) {
        null // asset missing -> falls back to the built-in tones
    }

    /** Your bundled mp3, looped; built-in tones only if the mp3 is missing. */
    private fun startMusic() {
        if (track != null || player != null) return
        val file = musicFile()
        if (file != null) {
            try {
                val mp = MediaPlayer()
                mp.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                mp.setDataSource(file.absolutePath)
                mp.isLooping = true
                mp.setOnErrorListener { _, _, _ -> stopMusic(); startPad(); true }
                mp.prepare()
                mp.start()
                player = mp
                keepVolume()
                return
            } catch (_: Exception) {
                try { player?.release() } catch (_: Exception) {}
                player = null
            }
        }
        startPad()
    }

    private fun startPad() {
        if (track != null) return
        try {
            val data = buildPad()
            val t = AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM) // plays even if media is muted
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(22050)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build()
                )
                .setBufferSizeInBytes(data.size * 2)
                .setTransferMode(AudioTrack.MODE_STATIC)
                .build()
            t.write(data, 0, data.size)
            t.setLoopPoints(0, data.size, -1)
            t.play()
            track = t
            keepVolume()
        } catch (_: Exception) {
            track = null
        }
    }

    private fun stopMusic() {
        try { player?.stop() } catch (_: Exception) {}
        try { player?.release() } catch (_: Exception) {}
        player = null
        try { track?.stop() } catch (_: Exception) {}
        try { track?.release() } catch (_: Exception) {}
        track = null
    }

    private fun keepVolume() {
        if (track == null && player == null) return
        try {
            val am = app.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val max = am.getStreamMaxVolume(AudioManager.STREAM_ALARM)
            if (am.getStreamVolume(AudioManager.STREAM_ALARM) < (max * 0.6).toInt()) {
                am.setStreamVolume(AudioManager.STREAM_ALARM, (max * 0.7).toInt(), 0)
            }
        } catch (_: Exception) {}
    }
}
