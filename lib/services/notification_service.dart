import 'package:flutter_local_notifications/flutter_local_notifications.dart';

typedef PayloadHandler = void Function(String? payload);

/// Works in BOTH the UI isolate and the background-service isolate.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const foregroundChannelId = 'mindful_foreground';
  static const foregroundNotificationId = 888;

  static Future<void> init({
    PayloadHandler? onTap,
    bool requestPermission = true,
  }) async {
    if (_initialized) return;

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse:
          onTap == null ? null : (r) => onTap(r.payload),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // Channel for the persistent "service is running" notification.
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      foregroundChannelId,
      'Mindful Minute monitoring',
      description: 'Keeps usage monitoring alive in the background.',
      importance: Importance.low,
    ));

    if (requestPermission) {
      await android?.requestNotificationsPermission();
      // Needed on Android 14+ so the 100% alert can open the app.
      await android?.requestFullScreenIntentPermission();
    }
    _initialized = true;
  }

  /// Payload of the notification that cold-started the app, if any.
  static Future<String?> launchPayload() async {
    final d = await _plugin.getNotificationAppLaunchDetails();
    if (d?.didNotificationLaunchApp ?? false) {
      return d!.notificationResponse?.payload;
    }
    return null;
  }

  /// Stable id per (app, tier) so repeats replace instead of stacking.
  static int idFor(String packageName, int tierIndex) {
    var h = 17;
    for (final c in packageName.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return (h ^ tierIndex) & 0x7fffffff;
  }

  static Future<void> showWarning({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool fullScreen = false,
  }) async {
    final details = AndroidNotificationDetails(
      fullScreen ? 'wellness_break' : 'usage_warnings',
      fullScreen ? 'Wellness Break' : 'Usage Warnings',
      channelDescription: fullScreen
          ? 'Opens Mindful Minute when a daily limit is reached.'
          : 'Alerts when a monitored app is approaching its daily limit.',
      importance: Importance.high,
      priority: Priority.high,
      fullScreenIntent: fullScreen,
      autoCancel: true,
    );
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: details),
      payload: payload,
    );
  }

  static Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
  }
}
