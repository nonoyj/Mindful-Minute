import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_preferences.dart';
import 'usage_service.dart';

enum WarningTier { seventy, eighty, ninety, limitReached }

extension WarningTierThreshold on WarningTier {
  double get thresholdFraction {
    switch (this) {
      case WarningTier.seventy:
        return 0.70;
      case WarningTier.eighty:
        return 0.80;
      case WarningTier.ninety:
        return 0.90;
      case WarningTier.limitReached:
        return 1.0;
    }
  }

  String get storageSuffix {
    switch (this) {
      case WarningTier.seventy:
        return '70';
      case WarningTier.eighty:
        return '80';
      case WarningTier.ninety:
        return '90';
      case WarningTier.limitReached:
        return '100';
    }
  }
}

class UsageWarning {
  final MonitoredApp app;
  final WarningTier tier;
  final int usedMinutes;

  UsageWarning({required this.app, required this.tier, required this.usedMinutes});

  String get message {
    final n = app.displayName;
    switch (tier) {
      case WarningTier.seventy:
        return '$n: ${usedMinutes}m of ${app.dailyLimitMinutes}m used (70%). '
            'Take a one-minute break?';
      case WarningTier.eighty:
        return '$n: 80% of your daily limit used. Try a one-minute activity.';
      case WarningTier.ninety:
        return '$n: almost there, 90% used! A Mindful Minute can help.';
      case WarningTier.limitReached:
        return '$n: daily limit reached. Time for your Mindful Minute!';
    }
  }
}

/// Runs inside the BACKGROUND SERVICE isolate (see background_service.dart).
class MonitoringService {
  static const Duration inactivityReset = Duration(minutes: 30);

  Timer? _pollTimer;
  bool _checking = false;

  final void Function(UsageWarning warning) onWarning;
  final void Function(String packageName)? onInactivityReset;

  final Map<String, int> _lastUsage = {};
  final Map<String, DateTime> _lastChange = {};
  final Set<String> _activeWarnings = {};

  MonitoringService({required this.onWarning, this.onInactivityReset});

  void start({Duration interval = const Duration(seconds: 15)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => _checkUsage());
    _checkUsage();
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _checkUsage() async {
    if (_checking) return;
    _checking = true;
    try {
      if (!await UsageService.hasUsageAccess()) return;

      // Separate isolate => separate prefs cache. Re-read from disk.
      final sp = await SharedPreferences.getInstance();
      await sp.reload();
      final prefs = await UserPreferences.load(reload: true);
      if (prefs.monitoredApps.isEmpty) return;

      final usageMap = await UsageService.getTodayUsageForApps(
          prefs.monitoredApps.map((a) => a.packageName).toList());
      final now = DateTime.now();

      for (final app in prefs.monitoredApps) {
        final used = usageMap[app.packageName] ?? 0;

        // --- 30-minute inactivity tracking ---
        final prev = _lastUsage[app.packageName];
        if (prev == null || used > prev) _lastChange[app.packageName] = now;
        _lastUsage[app.packageName] = used;

        if (_activeWarnings.contains(app.packageName) &&
            now.difference(_lastChange[app.packageName]!) >= inactivityReset) {
          _activeWarnings.remove(app.packageName);
          onInactivityReset?.call(app.packageName);
        }

        if (app.dailyLimitMinutes <= 0) continue;
        final fraction = used / app.dailyLimitMinutes;

        for (final tier in [
          WarningTier.limitReached,
          WarningTier.ninety,
          WarningTier.eighty,
          WarningTier.seventy,
        ]) {
          if (fraction >= tier.thresholdFraction) {
            if (!await _hasFiredToday(app.packageName, tier)) {
              await _markFiredToday(app.packageName, tier);
              _activeWarnings.add(app.packageName);
              onWarning(UsageWarning(app: app, tier: tier, usedMinutes: used));
            }
            break;
          }
        }
      }
    } finally {
      _checking = false;
    }
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  String _prefsKey(String pkg, WarningTier t) =>
      'warned_${pkg}_${t.storageSuffix}_${_todayKey()}';

  Future<bool> _hasFiredToday(String pkg, WarningTier t) async =>
      (await SharedPreferences.getInstance()).getBool(_prefsKey(pkg, t)) ?? false;

  Future<void> _markFiredToday(String pkg, WarningTier t) async =>
      (await SharedPreferences.getInstance()).setBool(_prefsKey(pkg, t), true);
}
