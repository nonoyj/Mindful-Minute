import 'package:flutter/material.dart';

import '../models/user_preferences.dart';
import '../screens/activities/activity_runner.dart';
import '../screens/activity_picker_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Opens the wellness break for a monitored app (used for the 100% alert).
class BreakLauncher {
  static bool _open = false;

  static Future<void> handlePayload(String? payload) async {
    if (payload != null && payload.startsWith('break|')) {
      await openBreakFor(payload.substring('break|'.length));
    }
  }

  static Future<void> openBreakFor(String packageName) async {
    if (_open) return; // avoid double-opening (stream event + notification tap)
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;

    final prefs = await UserPreferences.load(reload: true);
    MonitoredApp? app;
    for (final a in prefs.monitoredApps) {
      if (a.packageName == packageName) app = a;
    }
    final banner = app == null
        ? 'Time for a Mindful Minute'
        : "You've reached today's limit for ${app.displayName}";

    _open = true;
    try {
      await nav.push(MaterialPageRoute(
        builder: (_) => app?.activity != null
            ? ActivityRunnerScreen(type: app!.activity!, banner: banner)
            : ActivityPickerScreen(banner: banner),
      ));
    } finally {
      _open = false;
    }
  }
}
