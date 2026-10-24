package com.example.mindful_minute

import android.accessibilityservice.AccessibilityService
import android.os.Build
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent

/**
 * Accessibility service used ONLY while a wellness break is active:
 *  - reacts instantly when any other window appears (Home, Recents, apps),
 *  - collapses the notification shade / quick settings,
 *  - swallows volume keys so the break music can't be turned down.
 * It does nothing at all when no break is active.
 */
class BreakLockService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || !BreakGuard.isActive) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString()
        if (BreakGuard.isAllowed(pkg)) return

        if (pkg == "com.android.systemui" && Build.VERSION.SDK_INT >= 31) {
            performGlobalAction(GLOBAL_ACTION_DISMISS_NOTIFICATION_SHADE)
        }
        BreakGuard.bringToFront(true)
    }

    override fun onKeyEvent(event: KeyEvent): Boolean {
        if (BreakGuard.isActive && BreakGuard.musicPlaying) {
            when (event.keyCode) {
                KeyEvent.KEYCODE_VOLUME_DOWN,
                KeyEvent.KEYCODE_VOLUME_UP,
                KeyEvent.KEYCODE_VOLUME_MUTE -> return true
            }
        }
        return super.onKeyEvent(event)
    }

    override fun onInterrupt() {}
}
