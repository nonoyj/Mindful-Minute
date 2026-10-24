import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bridge to the native lock (Kotlin BreakGuard + BreakLockService).
/// Flags live in SharedPreferences so both Dart isolates can set them and the
/// native side reacts to them.
class GuardService {
  static const _ch = MethodChannel('mindful/guard');
  static const failsafe = Duration(minutes: 10);

  static Future<void> start(String packageName) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('guard_pkg', packageName);
    await p.setInt('guard_started_at', DateTime.now().millisecondsSinceEpoch);
    await p.setBool('guard_music', true); // music from the first moment
    await p.setBool('guard_active', true);
  }

  static Future<void> stop() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('guard_music', false);
    await p.setBool('guard_active', false);
  }

  /// Native music (alarm stream, un-mutable) on/off while the lock is active.
  static Future<void> setMusic(bool on) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('guard_music', on);
  }

  static Future<bool> isActive() async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    if (!(p.getBool('guard_active') ?? false)) return false;
    final at = p.getInt('guard_started_at') ?? 0;
    return DateTime.now().millisecondsSinceEpoch - at < failsafe.inMilliseconds;
  }

  static Future<String?> activePackage() async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    return p.getString('guard_pkg');
  }

  static Future<bool> _bool(String m) async {
    try {
      return (await _ch.invokeMethod<bool>(m)) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasOverlay() => _bool('hasOverlay');
  static Future<bool> isIgnoringBattery() => _bool('isIgnoringBattery');
  static Future<bool> hasAccessibility() => _bool('hasAccessibility');
  static Future<void> requestOverlay() => _ch.invokeMethod('requestOverlay');
  static Future<void> requestIgnoreBattery() =>
      _ch.invokeMethod('requestIgnoreBattery');
  static Future<void> requestAccessibility() =>
      _ch.invokeMethod('requestAccessibility');
}
