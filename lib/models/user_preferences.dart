import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Activities. (Old saved names quotes/audio/video/textReminder are migrated
/// to [reminders] automatically.)
enum WellnessActivityType { breathing, miniGame, reminders }

extension WellnessActivityTypeLabel on WellnessActivityType {
  String get label {
    switch (this) {
      case WellnessActivityType.breathing:
        return 'Breathing Exercise';
      case WellnessActivityType.miniGame:
        return 'Minute Mini-Game';
      case WellnessActivityType.reminders:
        return 'Wellness Reminders';
    }
  }
}

WellnessActivityType? _activityFromName(String? n) {
  switch (n) {
    case 'breathing':
      return WellnessActivityType.breathing;
    case 'miniGame':
      return WellnessActivityType.miniGame;
    case 'reminders':
    case 'quotes':
    case 'audio':
    case 'video':
    case 'textReminder':
      return WellnessActivityType.reminders;
  }
  return null;
}

/// One "wellness break": an app, its daily limit, whether it's on, and the
/// ordered activities to complete when the limit is reached.
class MonitoredApp {
  final String packageName;
  final String displayName;
  final int dailyLimitMinutes;
  final List<WellnessActivityType> activities;
  final bool enabled;

  MonitoredApp({
    required this.packageName,
    required this.displayName,
    required this.dailyLimitMinutes,
    List<WellnessActivityType>? activities,
    this.enabled = true,
  }) : activities = (activities == null || activities.isEmpty)
            ? const [WellnessActivityType.breathing]
            : activities;

  MonitoredApp copyWith({
    int? dailyLimitMinutes,
    List<WellnessActivityType>? activities,
    bool? enabled,
  }) =>
      MonitoredApp(
        packageName: packageName,
        displayName: displayName,
        dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
        activities: activities ?? this.activities,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'displayName': displayName,
        'dailyLimitMinutes': dailyLimitMinutes,
        'activities': activities.map((e) => e.name).toList(),
        'enabled': enabled,
      };

  factory MonitoredApp.fromJson(Map<String, dynamic> json) {
    var acts = (json['activities'] as List?)
        ?.map((e) => _activityFromName(e as String?))
        .whereType<WellnessActivityType>()
        .toSet() // merges old quotes/audio/video/text into ONE reminders entry
        .toList();
    final legacy = _activityFromName(json['activity'] as String?);
    if ((acts == null || acts.isEmpty) && legacy != null) acts = [legacy];
    return MonitoredApp(
      packageName: json['packageName'] as String,
      displayName: json['displayName'] as String,
      dailyLimitMinutes: json['dailyLimitMinutes'] as int,
      activities: acts,
      enabled: json['enabled'] as bool? ?? true,
    );
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
        enabledActivities = enabledActivities ?? WellnessActivityType.values.toSet();

  static const _monitoredAppsKey = 'monitoredApps';
  static const _enabledActivitiesKey = 'enabledActivities';
  static const _onboardingCompleteKey = 'onboardingComplete';

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
    final activities = names == null
        ? WellnessActivityType.values.toSet()
        : names.map(_activityFromName).whereType<WellnessActivityType>().toSet();

    return UserPreferences(
      monitoredApps: apps,
      enabledActivities:
          activities.isEmpty ? WellnessActivityType.values.toSet() : activities,
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
