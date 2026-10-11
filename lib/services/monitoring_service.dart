import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_preferences.dart';
import 'usage_service.dart';

/// Represents a warning tier that can fire for a monitored app.
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

/// A warning event fired for a specific app crossing a specific tier.
class UsageWarning {
  final MonitoredApp app;
  final WarningTier tier;
  final int usedMinutes;

  UsageWarning({
    required this.app,
    required this.tier,
    required this.usedMinutes,
  });
}

/// Polls usage stats periodically and determines which warnings
/// should fire for the user's monitored apps, avoiding repeats
/// within the same day.
class MonitoringService {
  Timer? _pollTimer;
  final void Function(UsageWarning warning) onWarning;

  MonitoringService({required this.onWarning});

  /// Starts polling every [interval] (default 15 seconds).
  void start({Duration interval = const Duration(seconds: 15)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => _checkUsage());
    // Also run an immediate check on start rather than waiting for
    // the first interval to elapse.
    _checkUsage();
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _checkUsage() async {
    final hasAccess = await UsageService.hasUsageAccess();
    if (!hasAccess) return;

    final prefs = await UserPreferences.load();
    if (prefs.monitoredApps.isEmpty) return;

    final packageNames =
    prefs.monitoredApps.map((a) => a.packageName).toList();
    final usageMap = await UsageService.getTodayUsageForApps(packageNames);

    for (final app in prefs.monitoredApps) {
      final usedMinutes = usageMap[app.packageName] ?? 0;
      if (app.dailyLimitMinutes <= 0) continue;

      final fraction = usedMinutes / app.dailyLimitMinutes;

      // Check tiers from highest to lowest so if usage jumps quickly
      // (e.g. app was closed a while, usage caught up), we fire the
      // highest relevant tier rather than every lower one at once.
      for (final tier in [
        WarningTier.limitReached,
        WarningTier.ninety,
        WarningTier.eighty,
        WarningTier.seventy,
      ]) {
        if (fraction >= tier.thresholdFraction) {
          final alreadyFired = await _hasFiredToday(app.packageName, tier);
          if (!alreadyFired) {
            await _markFiredToday(app.packageName, tier);
            onWarning(
              UsageWarning(app: app, tier: tier, usedMinutes: usedMinutes),
            );
          }
          break; // Only fire the single highest applicable tier per check
        }
      }
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _prefsKey(String packageName, WarningTier tier) {
    return 'warned_${packageName}_${tier.storageSuffix}_${_todayKey()}';
  }

  Future<bool> _hasFiredToday(String packageName, WarningTier tier) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey(packageName, tier)) ?? false;
  }

  Future<void> _markFiredToday(String packageName, WarningTier tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey(packageName, tier), true);
  }
}