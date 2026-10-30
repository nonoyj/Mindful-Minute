import '../models/user_preferences.dart';
import 'guard_service.dart';

/// The monitor now runs in a NATIVE Android service (MonitorService.kt) that
/// keeps going after you close the app. This file only starts/stops it.
Future<void> initBackgroundService() => syncBackgroundService();

/// Runs the monitor only while at least one break is switched ON.
Future<void> syncBackgroundService() async {
  final prefs = await UserPreferences.load(reload: true);
  await GuardService.setMonitor(prefs.monitoredApps.any((a) => a.enabled));
}
