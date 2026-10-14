import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionStats {
  final int total;
  final int streak;
  final List<String> timestamps;
  SessionStats(this.total, this.streak, this.timestamps);
}

/// Single place that reads/writes completed-session data.
class SessionService {
  /// Bumps every time a session is saved so Home/History can refresh.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<SessionStats> load() async {
    final p = await SharedPreferences.getInstance();
    final last = p.getString('lastCompletedDate');
    var streak = p.getInt('currentStreak') ?? 0;
    // A streak is only alive if the last session was today or yesterday.
    final today = _fmt(DateTime.now());
    final yesterday = _fmt(DateTime.now().subtract(const Duration(days: 1)));
    if (last != today && last != yesterday) streak = 0;
    return SessionStats(p.getInt('totalSessions') ?? 0, streak,
        p.getStringList('sessionTimestamps') ?? []);
  }

  static Future<void> recordCompletion() async {
    final p = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = _fmt(now);
    final yesterday = _fmt(now.subtract(const Duration(days: 1)));
    final last = p.getString('lastCompletedDate');
    final streak = p.getInt('currentStreak') ?? 0;

    final newStreak = last == today
        ? streak
        : (last == yesterday ? streak + 1 : 1);

    final stamps = List<String>.from(p.getStringList('sessionTimestamps') ?? [])
      ..add(now.toIso8601String());

    await p.setInt('totalSessions', (p.getInt('totalSessions') ?? 0) + 1);
    await p.setInt('currentStreak', newStreak);
    await p.setString('lastCompletedDate', today);
    await p.setStringList('sessionTimestamps', stamps);
    changes.value++;
  }
}
