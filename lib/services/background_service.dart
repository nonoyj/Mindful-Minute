import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'guard_service.dart';
import 'monitoring_service.dart';
import 'notification_service.dart';

/// Call once from main(). Starts an Android foreground service that keeps
/// polling usage every 15s even after Android kills the Flutter UI.
Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      autoStartOnBoot: true,
      isForegroundMode: true,
      notificationChannelId: NotificationService.foregroundChannelId,
      initialNotificationTitle: 'Mindful Minute',
      initialNotificationContent: 'Watching your app limits',
      foregroundServiceNotificationId: NotificationService.foregroundNotificationId,
      foregroundServiceTypes: [AndroidForegroundType.specialUse],
    ),
    iosConfiguration: IosConfiguration(autoStart: false),
  );
  if (!await service.isRunning()) {
    await service.startService();
  }
}

/// Entry point of the background isolate.
@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await NotificationService.init(requestPermission: false);

  service.on('stopService').listen((_) => service.stopSelf());

  final monitor = MonitoringService(
    onWarning: (w) async {
      final limit = w.tier == WarningTier.limitReached;
      // Arm the native lock BEFORE anything else: it reopens the app and
      // keeps it in front until the break is finished.
      if (limit) await GuardService.start(w.app.packageName);
      await NotificationService.showWarning(
        id: NotificationService.idFor(w.app.packageName, w.tier.index),
        title: 'Mindful Minute',
        body: w.message,
        // At 100% the notification carries a full-screen intent that opens
        // the app and starts the wellness break for this app.
        payload: limit ? 'break|${w.app.packageName}' : null,
        fullScreen: limit,
      );
      // Tell the UI (if it's alive) so it can show the in-app message.
      service.invoke('warning', {
        'package': w.app.packageName,
        'tier': w.tier.name,
        'message': w.message,
      });
    },
    onInactivityReset: (pkg) async {
      for (final t in WarningTier.values) {
        await NotificationService.cancel(NotificationService.idFor(pkg, t.index));
      }
    },
  );
  monitor.start();
}
