package com.example.mindful_minute

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.os.Build
import android.view.accessibility.AccessibilityEvent

/**
 * Accessibility service (V2).
 *  1) When a window of a BLOCKED app comes to the front, it opens the break.
 *  2) ONLY while an activity timer is running, Home/Recents/other apps are
 *     bounced back to Mindful Minute (Cancel in the app ends this).
 * It never touches volume keys and cannot read screen content.
 */
class BreakLockService : AccessibilityService() {

    companion object {
        @Volatile private var instance: BreakLockService? = null

        /**
         * Switches the accessibility service OFF from inside the app
         * (API 24+). Returns false if it isn't running or the phone is too old.
         */
        fun disable(): Boolean {
            val s = instance ?: return false
            if (Build.VERSION.SDK_INT < 24) return false
            s.disableSelf()
            instance = null
            return true
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onUnbind(intent: Intent?): Boolean {
        instance = null
        return super.onUnbind(intent)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return
        // While an activity runs, also close the notification shade / quick settings.
        if (pkg == "com.android.systemui" && Build.VERSION.SDK_INT >= 31 &&
            BreakGuard.activityLocked(this)) {
            performGlobalAction(GLOBAL_ACTION_DISMISS_NOTIFICATION_SHADE)
        }
        BreakGuard.onForeground(this, pkg)
    }

    override fun onInterrupt() {}
}
