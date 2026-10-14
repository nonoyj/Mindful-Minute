import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// An app the user wants Mindful Minute to monitor, its daily limit (minutes)
/// and (optionally) the wellness activity to launch when the limit is reached.
class MonitoredApp {
  final String packageName;
  final String displayName;
  final int dailyLimitMinutes;
  final WellnessActivityType? activity; // null = "let me choose each time"

  MonitoredApp({
    required this.packageName,
    required this.displayName,
    required this.dailyLimitMinutes,
    this.activity,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'displayName': displayName,
        'dailyLimitMinutes': dailyLimitMinutes,
        'activity': activity?.name,
      };

  factory MonitoredApp.fromJson(Map<String, dynamic> json) {
    final name = json['activity'] as String?;
    WellnessActivityType? act;
    for (final t in WellnessActivityType.values) {
      if (t.name == name) act = t;
    }
    return MonitoredApp(
      packageName: json['packageName'] as String,
      displayName: json['displayName'] as String,
      dailyLimitMinutes: json['dailyLimitMinutes'] as int,
      activity: act,
    );
  }
}

/// NOTE: `video` is kept as the enum name so previously saved preferences
/// still load; it now represents the calming nature animation.
enum WellnessActivityType {
  breathing,
  quotes,
  miniGame,
  audio,
  video,
  textReminder,
}

extension WellnessActivityTypeLabel on WellnessActivityType {
  String get label {
    switch (this) {
      case WellnessActivityType.breathing:
        return 'Breathing Exercise';
      case WellnessActivityType.quotes:
        return 'Anti-Procrastination Quotes';
      case WellnessActivityType.miniGame:
        return 'Minute Mini-Game';
      case WellnessActivityType.audio:
        return 'Relaxing Audio';
      case WellnessActivityType.video:
        return 'Calming Nature Animation';
      case WellnessActivityType.textReminder:
        return 'Text Reminder';
    }
  }
}

class UserPreferences {
  List<MonitoredApp> monitoredApps;
  Set<WellnessActivityType> enabledActivities;
  bool onboardingComplete;

  UserPreferences({
    List<MonitoredApp>? monitoredApps,
    Set<WellnessActivityType>? enabledActivities,
    this.onboardingComplete = false,
  })  : monitoredApps = monitoredApps ?? [],
        enabledActivities = enabledActivities ??
            {WellnessActivityType.breathing, WellnessActivityType.quotes};

  static const _monitoredAppsKey = 'monitoredApps';
  static const _enabledActivitiesKey = 'enabledActivities';
  static const _onboardingCompleteKey = 'onboardingComplete';

  /// Loads from storage. [reload] forces a re-read from disk — required in
  /// the background-service isolate, which has its own SharedPreferences cache.
  static Future<UserPreferences> load({bool reload = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (reload) await prefs.reload();

    final appsJson = prefs.getString(_monitoredAppsKey);
    final List<MonitoredApp> apps = appsJson == null
        ? []
        : (jsonDecode(appsJson) as List)
            .map((e) => MonitoredApp.fromJson(e as Map<String, dynamic>))
            .toList();

    final names = prefs.getStringList(_enabledActivitiesKey);
    final Set<WellnessActivityType> activities = names == null
        ? {WellnessActivityType.breathing, WellnessActivityType.quotes}
        : names
            .map((n) => WellnessActivityType.values.firstWhere(
                  (e) => e.name == n,
                  orElse: () => WellnessActivityType.breathing,
                ))
            .toSet();

    return UserPreferences(
      monitoredApps: apps,
      enabledActivities: activities,
      onboardingComplete: prefs.getBool(_onboardingCompleteKey) ?? false,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _monitoredAppsKey, jsonEncode(monitoredApps.map((a) => a.toJson()).toList()));
    await prefs.setStringList(
        _enabledActivitiesKey, enabledActivities.map((e) => e.name).toList());
    await prefs.setBool(_onboardingCompleteKey, onboardingComplete);
  }

  void addOrUpdateApp(MonitoredApp app) {
    final i = monitoredApps.indexWhere((a) => a.packageName == app.packageName);
    if (i >= 0) {
      monitoredApps[i] = app;
    } else {
      monitoredApps.add(app);
    }
  }

  void removeApp(String packageName) {
    monitoredApps.removeWhere((a) => a.packageName == packageName);
  }
}
