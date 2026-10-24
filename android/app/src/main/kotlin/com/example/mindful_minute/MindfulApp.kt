package com.example.mindful_minute

import android.app.Application

class MindfulApp : Application() {
    override fun onCreate() {
        super.onCreate()
        // Lives as long as the process (kept alive by the foreground service).
        BreakGuard.init(this)
    }
}
