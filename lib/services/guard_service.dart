import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bridge to the native side (Kotlin). V2: per-app blocking instead of a
/// full phone lock.
///
/// Blocked apps are stored as a comma-separated string under the key
/// "blocked_pkgs" (Kotlin reads it as "flutter.blocked_pkgs").
class GuardService {
  static const _ch = MethodChannel('mindful/guard');
  static const _blockedKey = 'blocked_pkgs';
  static const _pendingKey = 'pending_break_pkg';

  // ---------------------------------------------------------- blocked apps
  static Future<Set<String>> blockedPackages() async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    return (p.getString(_blockedKey) ?? '')
        .split(',')
        .where((e) => e.isNotEmpty)
        .toSet();
  }

  static Future<bool> isBlocked(String pkg) async =>
      (await blockedPackages()).contains(pkg);

  static Future<void> block(String pkg) async {
    final set = await blockedPackages()..add(pkg);
    final p = await SharedPreferences.getInstance();
    await p.setString(_blockedKey, set.join(','));
  }

  static Future<void> unblock(String pkg) async {
    final set = await blockedPackages()..remove(pkg);
    final p = await SharedPreferences.getInstance();
    await p.setString(_blockedKey, set.join(','));
  }

  /// Written by the native side when a blocked app was opened.
  /// Read once, then cleared.
  static Future<String?> takePendingBreak() async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    final pkg = p.getString(_pendingKey);
    if (pkg == null || pkg.isEmpty) return null;
    await p.remove(_pendingKey);
    return pkg;
  }

  /// While an activity is RUNNING the user may not leave the app (Home/Recents
  /// are bounced back by the accessibility service). Stored as a timestamp so
  /// the native side can expire it after a few minutes (failsafe).
  static Future<void> setActivityLock(bool on) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('activity_lock_at', on ? DateTime.now().millisecondsSinceEpoch : 0);
  }

  /// Sends the user to the home screen so Back doesn't return to the blocked app.
  static Future<void> goHome() async {
    try {
      await _ch.invokeMethod('goHome');
    } catch (_) {
      SystemNavigator.pop();
    }
  }

  // --- native monitor + helpers ---
  static Future<bool> _bool(String m) async {
    try {
      return (await _ch.invokeMethod<bool>(m)) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setMonitor(bool on) async {
    try {
      await _ch.invokeMethod(on ? 'startMonitor' : 'stopMonitor');
    } catch (_) {}
  }

  static Future<void> cancelWarnings(String pkg) async {
    try {
      await _ch.invokeMethod('cancelWarnings', {'pkg': pkg});
    } catch (_) {}
  }

  static Future<String> deviceInfo() async {
    try {
      return (await _ch.invokeMethod<String>('deviceInfo')) ?? 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  static Future<bool> sendEmail(String to, String subject, String body) async {
    try {
      return (await _ch.invokeMethod<bool>(
              'sendEmail', {'to': to, 'subject': subject, 'body': body})) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasOverlay() => _bool('hasOverlay');
  static Future<bool> isIgnoringBattery() => _bool('isIgnoringBattery');
  static Future<bool> hasAccessibility() => _bool('hasAccessibility');
  static Future<void> openBatterySettings() => _ch.invokeMethod('openBatterySettings');
  static Future<void> requestOverlay() => _ch.invokeMethod('requestOverlay');
  static Future<void> requestIgnoreBattery() => _ch.invokeMethod('requestIgnoreBattery');
  static Future<void> requestAccessibility() => _ch.invokeMethod('requestAccessibility');

  /// Opens this app's own Usage access page (falls back to the list).
  static Future<void> openUsageAccess() => _ch.invokeMethod('openUsageAccess');

  /// Turns the accessibility service OFF from inside the app. Returns false
  /// if Android refused -> open Settings instead.
  static Future<bool> disableAccessibility() => _bool('disableAccessibility');
}
