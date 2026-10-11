import 'dart:async';
import 'package:usage_stats/usage_stats.dart';

/// Handles checking Usage Access permission and reading how much
/// time the user has spent in specific apps today.
class UsageService {
  /// Opens Android's Usage Access settings screen so the user can
  /// manually grant permission. Android does not allow this to be
  /// requested via a normal runtime permission popup.
  static Future<void> openUsageAccessSettings() async {
    await UsageStats.grantUsagePermission();
  }

  /// Checks whether Usage Access has already been granted.
  static Future<bool> hasUsageAccess() async {
    final bool? granted = await UsageStats.checkUsagePermission();
    return granted ?? false;
  }

  /// Returns today's usage, in minutes, for a single app identified
  /// by its package name. Returns 0 if no usage found or on error.
  static Future<int> getTodayUsageMinutes(String packageName) async {
    final DateTime now = DateTime.now();
    final DateTime startOfDay = DateTime(now.year, now.month, now.day);

    try {
      final List<UsageInfo> statsList = await UsageStats.queryUsageStats(
        startOfDay,
        now,
      );

      // Sum up usage across all returned entries matching this package,
      // since some devices return multiple fragmented entries per app.
      int totalMillis = 0;
      for (final stat in statsList) {
        if (stat.packageName == packageName) {
          totalMillis += int.tryParse(stat.totalTimeInForeground ?? '0') ?? 0;
        }
      }

      return (totalMillis / 60000).round(); // ms -> minutes
    } catch (e) {
      return 0;
    }
  }

  /// Returns today's usage, in minutes, for a whole list of package
  /// names at once. Useful for checking every monitored app together.
  static Future<Map<String, int>> getTodayUsageForApps(
      List<String> packageNames,
      ) async {
    final DateTime now = DateTime.now();
    final DateTime startOfDay = DateTime(now.year, now.month, now.day);

    final Map<String, int> result = {
      for (final pkg in packageNames) pkg: 0,
    };

    try {
      final List<UsageInfo> statsList = await UsageStats.queryUsageStats(
        startOfDay,
        now,
      );

      for (final stat in statsList) {
        final pkg = stat.packageName;
        if (pkg != null && result.containsKey(pkg)) {
          final millis =
              int.tryParse(stat.totalTimeInForeground ?? '0') ?? 0;
          result[pkg] = result[pkg]! + (millis / 60000).round();
        }
      }
    } catch (e) {
      // Leave result as all zeros if the query fails
    }

    return result;
  }
}