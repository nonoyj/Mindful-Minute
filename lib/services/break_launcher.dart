import 'package:flutter/material.dart';

import '../models/user_preferences.dart';
import '../screens/wellness_break_screen.dart';
import 'guard_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Opens the LOCKED wellness break (the 100% alert).
class BreakLauncher {
  static bool _open = false;

  static Future<void> handlePayload(String? payload) async {
    if (payload != null && payload.startsWith('break|')) {
      await openBreakFor(payload.substring('break|'.length));
    }
  }

  /// Called on cold start and every time the app returns to the foreground:
  /// if the native lock is armed, make sure the break screen is showing.
  static Future<void> checkGuard() async {
    if (await GuardService.isActive()) {
      final pkg = await GuardService.activePackage();
      if (pkg != null) await openBreakFor(pkg);
    }
  }

  static Future<void> openBreakFor(String packageName) async {
    if (_open) return;
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;

    final prefs = await UserPreferences.load(reload: true);
    MonitoredApp? app;
    for (final a in prefs.monitoredApps) {
      if (a.packageName == packageName) app = a;
    }
    app ??= MonitoredApp(
        packageName: packageName, displayName: 'your app', dailyLimitMinutes: 0);

    _open = true;
    try {
      await nav.push(MaterialPageRoute(
        builder: (_) => WellnessBreakScreen(app: app!, locked: true),
      ));
    } finally {
      _open = false;
    }
  }
}
