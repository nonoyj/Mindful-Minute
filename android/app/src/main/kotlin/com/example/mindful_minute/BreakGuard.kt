package com.example.mindful_minute

import android.content.Context
import android.content.Intent

/**
 * V2: per-app blocking (no more full-phone lock).
 *
 * Dart and Kotlin share two SharedPreferences values:
 *   flutter.blocked_pkgs      comma-separated packages that are blocked
 *   flutter.pending_break_pkg package whose break Dart should show next
 *
 * MonitorService adds a package at 100%. Dart removes it when the activities
 * are finished. BreakLockService calls [onForeground] whenever a window
 * changes; if it belongs to a blocked app, the break screen is opened.
 */
object BreakGuard {
    private const val PREFS = "FlutterSharedPreferences"
    private const val KEY_BLOCKED = "flutter.blocked_pkgs"
    private const val KEY_PENDING = "flutter.pending_break_pkg"
    private const val DEBOUNCE_MS = 1500L

    private const val KEY_ACTIVITY_LOCK = "flutter.activity_lock_at"
    private const val ACTIVITY_LOCK_MAX_MS = 5 * 60 * 1000L // failsafe
    private const val FRONT_DEBOUNCE_MS = 400L

    /** Never fight these: incoming/emergency calls must always work. */
    private val CALL_PKGS = setOf(
        "com.android.server.telecom", "com.android.dialer", "com.google.android.dialer",
        "com.android.incallui", "com.samsung.android.incallui", "com.android.phone",
        "com.android.emergency", "com.google.android.apps.safetyhub"
    )

    private var lastFront = 0L
    private var appPkg: String? = null
    private var lastLaunch = 0L

    /** Kept so MindfulApp.kt (which calls BreakGuard.init) still compiles. */
    fun init(ctx: Context) {
        appPkg = ctx.applicationContext.packageName
    }

    private fun prefs(ctx: Context) =
        ctx.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun blocked(ctx: Context): Set<String> =
        (prefs(ctx).getString(KEY_BLOCKED, "") ?: "")
            .split(",").filter { it.isNotEmpty() }.toSet()

    fun isBlocked(ctx: Context, pkg: String) = pkg in blocked(ctx)

    fun block(ctx: Context, pkg: String) {
        val set = blocked(ctx).toMutableSet().apply { add(pkg) }
        prefs(ctx).edit().putString(KEY_BLOCKED, set.joinToString(",")).apply()
    }

    /** True while at least one app is blocked. */
    val isActive: Boolean get() = false.also { /* no global lock in V2 */ }

    /** Never treat our own app as a blocked app. */
    fun isAllowed(pkg: String?): Boolean = pkg == null || pkg == appPkg

    /** Asks Dart to show the break for [pkg] and brings Mindful Minute to the front. */
    fun openBreak(ctx: Context, pkg: String) {
        val now = System.currentTimeMillis()
        if (now - lastLaunch < DEBOUNCE_MS) return
        lastLaunch = now
        prefs(ctx).edit().putString(KEY_PENDING, pkg).apply()
        try {
            ctx.applicationContext.startActivity(
                Intent(ctx.applicationContext, MainActivity::class.java).addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                )
            )
        } catch (_: Exception) {
            // Android refused a background launch: the full-screen notification
            // (and the next time the app is opened) will still show the break.
        }
    }

    /**
     * True while an activity (the 60 s timer) is running in a real break.
     * Dart writes a timestamp; it expires after 5 minutes so the user can
     * never get stuck.
     */
    fun activityLocked(ctx: Context): Boolean = try {
        val at = prefs(ctx).getLong(KEY_ACTIVITY_LOCK, 0L)
        at > 0 && System.currentTimeMillis() - at < ACTIVITY_LOCK_MAX_MS
    } catch (_: Exception) { false }

    fun isCallApp(pkg: String) = pkg in CALL_PKGS

    /** Brings Mindful Minute back to the front (no new break is requested). */
    fun bringToFront(ctx: Context) {
        val now = System.currentTimeMillis()
        if (now - lastFront < FRONT_DEBOUNCE_MS) return
        lastFront = now
        try {
            ctx.applicationContext.startActivity(
                Intent(ctx.applicationContext, MainActivity::class.java).addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                )
            )
        } catch (_: Exception) {}
    }

    /** Called by the accessibility service when [pkg] came to the front. */
    fun onForeground(ctx: Context, pkg: String) {
        if (isAllowed(pkg)) return
        // An activity is running: nothing else may take the screen (except calls).
        if (activityLocked(ctx) && !isCallApp(pkg)) {
            bringToFront(ctx)
            return
        }
        if (isBlocked(ctx, pkg)) openBreak(ctx, pkg)
    }
}
