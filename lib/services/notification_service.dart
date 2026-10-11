import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Wraps flutter_local_notifications: handles one-time setup and
/// showing real notification-bar alerts for usage warnings.
///
/// This is still fully offline — flutter_local_notifications talks
/// directly to the Android notification system, no network involved.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Call once, before runApp(). Sets up the plugin and requests
  /// notification permission (required at runtime on Android 13+).
  static Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    // Newer flutter_local_notifications versions use a named
    // `settings` parameter here instead of a positional one.
    await _plugin.initialize(settings: settings);

    // Android 13+ (API 33+) requires this explicit runtime request;
    // it's a no-op (returns true) on older versions.
    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Shows a notification-bar alert for a usage warning.
  ///
  /// [id] should be stable per (app, tier) pair so repeated warnings
  /// for the same app/tier replace each other instead of stacking up
  /// endlessly in the notification shade.
  static Future<void> showWarning({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'usage_warnings', // channel id
      'Usage Warnings', // channel name, shown in system settings
      channelDescription:
      'Alerts when a monitored app is approaching or has hit its '
          'daily time limit.',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    // Newer flutter_local_notifications versions require id, title,
    // body, and notificationDetails to all be passed as named
    // arguments (the old positional-args signature is gone, and the
    // `details` param was renamed to `notificationDetails`).
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}