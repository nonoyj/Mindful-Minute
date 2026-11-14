import 'package:flutter/material.dart';

import '../models/user_preferences.dart';
import '../screens/wellness_break_screen.dart';
import 'guard_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Opens the wellness break for a BLOCKED app (V2: the user may leave, but the
/// app stays blocked until the activities are finished).
class BreakLauncher {
  static bool _open = false;

  static Future<void> handlePayload(String? payload) async {
    if (payload != null && payload.startsWith('break|')) {
      await openBreakFor(payload.substring('break|'.length));
    }
  }

  /// Called on cold start and every time the app returns to the foreground:
  /// if the native side flagged a blocked app that was opened, show its break.
  static Future<void> checkGuard() async {
    final pkg = await GuardService.takePendingBreak();
    if (pkg != null) await openBreakFor(pkg);
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

    // Safety net: make sure the app is on the blocked list.
    await GuardService.block(packageName);

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
