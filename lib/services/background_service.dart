import '../models/user_preferences.dart';
import 'guard_service.dart';

/// The monitor runs in a NATIVE Android service (MonitorService.kt) that keeps
/// going after you close the app. This file only starts/stops it.
Future<void> initBackgroundService() => syncBackgroundService();

/// Runs the monitor only while at least one break is switched ON.
/// Call this after EVERY change to a break (on/off, add, delete).
/// When nothing is on, the native side stops the service and removes its
/// notification and any leftover warnings.
Future<void> syncBackgroundService() async {
  final prefs = await UserPreferences.load(reload: true);

  // Breaks that are switched off must not leave warnings in the shade.
  for (final a in prefs.monitoredApps.where((a) => !a.enabled)) {
    await GuardService.cancelWarnings(a.packageName);
  }

  await GuardService.setMonitor(prefs.monitoredApps.any((a) => a.enabled));
}
