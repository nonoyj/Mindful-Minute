import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../services/monitoring_service.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int totalSeconds = 60;
  static const int breathCycleSeconds = 8; // 4s in, 4s out

  int secondsRemaining = totalSeconds;
  Timer? _timer;
  bool isRunning = false;

  int totalSessions = 0;
  int currentStreak = 0;
  String? lastCompletedDate;
  List<String> sessionTimestamps = [];

  MonitoringService? _monitoringService;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _monitoringService = MonitoringService(onWarning: _handleWarning);
    _monitoringService!.start();
  }

  void _handleWarning(UsageWarning warning) {
    String message;
    Color color;
    switch (warning.tier) {
      case WarningTier.seventy:
        message =
        '${warning.app.displayName}: you\'ve used ${warning.usedMinutes} of '
            '${warning.app.dailyLimitMinutes} min today (70%)';
        color = Colors.amber.shade700;
        break;
      case WarningTier.eighty:
        message = '${warning.app.displayName}: 80% of your daily limit used';
        color = Colors.orange.shade700;
        break;
      case WarningTier.ninety:
        message = '${warning.app.displayName}: almost there — 90% used!';
        color = Colors.deepOrange.shade700;
        break;
      case WarningTier.limitReached:
        message =
        '${warning.app.displayName}: daily limit reached. Time for a '
            'Mindful Minute!';
        color = Colors.red.shade700;
        break;
    }

    // Real notification-bar alert -- fires regardless of whether
    // Mindful Minute is the visible screen right now (as long as the
    // app process itself is still alive; see MonitoringService notes
    // on the background-service limitation).
    NotificationService.showWarning(
      id: _notificationId(warning.app.packageName, warning.tier),
      title: 'Mindful Minute',
      body: message,
    );

    // Keep the in-app SnackBar too, for immediate feedback when the
    // app is actually open and visible.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Builds a stable notification id from the package name + tier so
  /// a repeated warning for the same app/tier replaces the previous
  /// notification instead of stacking a new one every time.
  int _notificationId(String packageName, WarningTier tier) {
    return (packageName.hashCode ^ tier.index) & 0x7fffffff;
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalSessions = prefs.getInt('totalSessions') ?? 0;
      currentStreak = prefs.getInt('currentStreak') ?? 0;
      lastCompletedDate = prefs.getString('lastCompletedDate');
      sessionTimestamps = prefs.getStringList('sessionTimestamps') ?? [];
    });
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _yesterdayString() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveCompletedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final now = DateTime.now();

    int newStreak;
    if (lastCompletedDate == today) {
      newStreak = currentStreak;
    } else if (lastCompletedDate == _yesterdayString()) {
      newStreak = currentStreak + 1;
    } else {
      newStreak = 1;
    }

    final newTotal = totalSessions + 1;
    final newTimestamps = List<String>.from(sessionTimestamps)
      ..add(now.toIso8601String());

    await prefs.setInt('totalSessions', newTotal);
    await prefs.setInt('currentStreak', newStreak);
    await prefs.setString('lastCompletedDate', today);
    await prefs.setStringList('sessionTimestamps', newTimestamps);

    setState(() {
      totalSessions = newTotal;
      currentStreak = newStreak;
      lastCompletedDate = today;
      sessionTimestamps = newTimestamps;
    });
  }

  void _startTimer() {
    setState(() {
      isRunning = true;
      secondsRemaining = totalSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          secondsRemaining = 0;
          isRunning = false;
        });
        _onSessionComplete();
      } else {
        setState(() {
          secondsRemaining--;
        });
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    setState(() {
      isRunning = false;
      secondsRemaining = totalSeconds;
    });
  }

  Future<void> _onSessionComplete() async {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.mediumImpact();
    await _saveCompletedSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _monitoringService?.stop();
    super.dispose();
  }

  bool get _isInhaling {
    final elapsed = totalSeconds - secondsRemaining;
    final posInCycle = elapsed % breathCycleSeconds;
    return posInCycle < (breathCycleSeconds / 2);
  }

  String get _breathLabel {
    if (!isRunning) return 'Ready when you are';
    return _isInhaling ? 'Breathe in...' : 'Breathe out...';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDone = !isRunning && secondsRemaining == 0;
    final double progress = 1 - (secondsRemaining / totalSeconds);

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Mindful Minute',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                  color: Colors.teal.shade800,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatChip(label: 'Sessions', value: '$totalSessions'),
                  const SizedBox(width: 16),
                  _StatChip(label: 'Streak', value: '$currentStreak 🔥'),
                ],
              ),
              const SizedBox(height: 32),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _breathLabel,
                  key: ValueKey(_breathLabel),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.teal.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: Duration(
                        seconds: (breathCycleSeconds / 2).round(),
                      ),
                      curve: Curves.easeInOut,
                      width: isRunning ? (_isInhaling ? 200 : 150) : 150,
                      height: isRunning ? (_isInhaling ? 200 : 150) : 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.teal.withValues(alpha: 0.15),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: Colors.teal.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.teal.shade400,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$secondsRemaining',
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w300,
                            color: Colors.teal.shade900,
                          ),
                        ),
                        Text(
                          isDone ? 'Well done!' : 'seconds',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.teal.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: isRunning ? null : _startTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: Text(
                  isRunning ? 'In Progress...' : 'Start Mindful Minute',
                ),
              ),
              if (isRunning) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _cancelTimer,
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.teal.shade700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.teal.shade800,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.teal.shade600),
          ),
        ],
      ),
    );
  }
}