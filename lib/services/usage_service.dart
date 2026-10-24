import 'dart:async';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart';

/// Reads real foreground time from usage EVENTS (resume/pause pairs), which
/// avoids the double counting you get from summing queryUsageStats buckets.
/// Also supports a per-app "reset" (used when a wellness break is completed).
class UsageService {
  static Future<void> openUsageAccessSettings() async {
    await UsageStats.grantUsagePermission();
  }

  static Future<bool> hasUsageAccess() async {
    final bool? granted = await UsageStats.checkUsagePermission();
    return granted ?? false;
  }

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  /// Minutes used today per package, counting only time after the app's last reset.
  static Future<Map<String, int>> getTodayUsageForApps(
      List<String> packageNames) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final wanted = packageNames.toSet();
    final result = {for (final p in packageNames) p: 0};
    if (wanted.isEmpty) return result;

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // may have been written by the other isolate
    final resetAt = <String, int>{
      for (final p in wanted) p: prefs.getInt('usage_reset_$p') ?? 0,
    };

    const maxSession = 2 * 60 * 60 * 1000; // sanity cap per session
    final nowMs = now.millisecondsSinceEpoch;
    final totalMs = <String, int>{};

    void add(String pkg, int start, int end) {
      final s = math.max(start, resetAt[pkg] ?? 0);
      var d = end - s;
      if (d <= 0) return;
      if (d > maxSession) d = maxSession;
      totalMs[pkg] = (totalMs[pkg] ?? 0) + d;
    }

    try {
      final events = await UsageStats.queryEvents(startOfDay, now);
      final list = <List<dynamic>>[]; // [timeMs, type, pkg, class]
      for (final e in events) {
        final t = int.tryParse('${e.timeStamp}');
        final type = int.tryParse('${e.eventType}');
        if (t == null || type == null) continue;
        list.add([t, type, '${e.packageName}', '${e.className}']);
      }
      list.sort((a, b) => (a[0] as int).compareTo(b[0] as int));

      final open = <String, int>{}; // "pkg/class" -> start ms
      for (final ev in list) {
        final t = ev[0] as int;
        final type = ev[1] as int;
        final pkg = ev[2] as String;
        final key = '$pkg/${ev[3]}';
        if (type == 16) {
          // SCREEN_NON_INTERACTIVE: screen off ends every open session.
          for (final k in open.keys.toList()) {
            final p = k.split('/').first;
            if (wanted.contains(p)) add(p, open[k]!, t);
          }
          open.clear();
        } else if (!wanted.contains(pkg)) {
          continue;
        } else if (type == 1) {
          open.putIfAbsent(key, () => t); // ACTIVITY_RESUMED
        } else if (type == 2 || type == 23) {
          // ACTIVITY_PAUSED / STOPPED
          final s = open.remove(key);
          if (s != null) add(pkg, s, t);
        }
      }
      // Still in the foreground right now.
      open.forEach((k, s) {
        final p = k.split('/').first;
        if (wanted.contains(p)) add(p, s, nowMs);
      });
    } catch (_) {}

    totalMs.forEach((p, ms) => result[p] = (ms / 60000).round());
    return result;
  }

  /// Called when a wellness break is completed: the app's limit starts over.
  static Future<void> resetApp(String packageName) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('usage_reset_$packageName', DateTime.now().millisecondsSinceEpoch);
    for (final s in const ['70', '80', '90', '100']) {
      await p.remove('warned_${packageName}_${s}_${_todayKey()}');
    }
  }
}
