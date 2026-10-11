import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a single app the user wants Mindful Minute to monitor,
/// along with the daily time limit (in minutes) before a wellness
/// break is triggered.
class MonitoredApp {
  final String packageName; // e.g. "com.zhiliaoapp.musically" for TikTok
  final String displayName; // e.g. "TikTok"
  final int dailyLimitMinutes; // e.g. 60

  MonitoredApp({
    required this.packageName,
    required this.displayName,
    required this.dailyLimitMinutes,
  });

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'displayName': displayName,
    'dailyLimitMinutes': dailyLimitMinutes,
  };

  factory MonitoredApp.fromJson(Map<String, dynamic> json) => MonitoredApp(
    packageName: json['packageName'] as String,
    displayName: json['displayName'] as String,
    dailyLimitMinutes: json['dailyLimitMinutes'] as int,
  );

  MonitoredApp copyWith({
    String? packageName,
    String? displayName,
    int? dailyLimitMinutes,
  }) {
    return MonitoredApp(
      packageName: packageName ?? this.packageName,
      displayName: displayName ?? this.displayName,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
    );
  }
}

/// The set of wellness-break activity types a user can enable.
/// The wellness break screen will only offer activities the user
/// has turned on here.
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
        return 'Calming Video';
      case WellnessActivityType.textReminder:
        return 'Text Reminder';
    }
  }
}

/// Holds and persists all user-configurable preferences:
/// which apps are monitored, their limits, and which wellness
/// activities are enabled.
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
            {
              WellnessActivityType.breathing,
              WellnessActivityType.quotes,
            };

  static const _monitoredAppsKey = 'monitoredApps';
  static const _enabledActivitiesKey = 'enabledActivities';
  static const _onboardingCompleteKey = 'onboardingComplete';

  /// Loads preferences from local storage. Returns defaults if
  /// nothing has been saved yet (first launch).
  static Future<UserPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();

    final appsJson = prefs.getString(_monitoredAppsKey);
    final List<MonitoredApp> apps = appsJson == null
        ? []
        : (jsonDecode(appsJson) as List)
        .map((e) => MonitoredApp.fromJson(e as Map<String, dynamic>))
        .toList();

    final activityNames = prefs.getStringList(_enabledActivitiesKey);
    final Set<WellnessActivityType> activities = activityNames == null
        ? {WellnessActivityType.breathing, WellnessActivityType.quotes}
        : activityNames
        .map((name) => WellnessActivityType.values.firstWhere(
          (e) => e.name == name,
      orElse: () => WellnessActivityType.breathing,
    ))
        .toSet();

    final onboardingComplete = prefs.getBool(_onboardingCompleteKey) ?? false;

    return UserPreferences(
      monitoredApps: apps,
      enabledActivities: activities,
      onboardingComplete: onboardingComplete,
    );
  }

  /// Persists the current preferences to local storage.
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    final appsJson =
    jsonEncode(monitoredApps.map((a) => a.toJson()).toList());
    await prefs.setString(_monitoredAppsKey, appsJson);

    await prefs.setStringList(
      _enabledActivitiesKey,
      enabledActivities.map((e) => e.name).toList(),
    );

    await prefs.setBool(_onboardingCompleteKey, onboardingComplete);
  }

  void addOrUpdateApp(MonitoredApp app) {
    final index =
    monitoredApps.indexWhere((a) => a.packageName == app.packageName);
    if (index >= 0) {
      monitoredApps[index] = app;
    } else {
      monitoredApps.add(app);
    }
  }

  void removeApp(String packageName) {
    monitoredApps.removeWhere((a) => a.packageName == packageName);
  }
}