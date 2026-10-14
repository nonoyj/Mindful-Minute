import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../services/break_launcher.dart';
import '../services/monitoring_service.dart';
import '../services/session_service.dart';
import 'activity_picker_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _total = 0;
  int _streak = 0;
  StreamSubscription? _warningSub;

  @override
  void initState() {
    super.initState();
    _loadStats();
    SessionService.changes.addListener(_loadStats);

    // Usage monitoring now lives in the background service. When it fires a
    // warning and the UI happens to be alive, show the in-app message too.
    _warningSub = FlutterBackgroundService().on('warning').listen((data) {
      if (data == null) return;
      _showInApp(data['message'] as String, data['tier'] as String);
      if (data['tier'] == WarningTier.limitReached.name) {
        BreakLauncher.openBreakFor(data['package'] as String);
      }
    });
  }

  Future<void> _loadStats() async {
    final s = await SessionService.load();
    if (!mounted) return;
    setState(() {
      _total = s.total;
      _streak = s.streak;
    });
  }

  void _showInApp(String message, String tier) {
    if (!mounted) return;
    final color = {
          'seventy': Colors.amber.shade700,
          'eighty': Colors.orange.shade700,
          'ninety': Colors.deepOrange.shade700,
          'limitReached': Colors.red.shade700,
        }[tier] ??
        Colors.teal;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'Start',
        textColor: Colors.white,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ActivityPickerScreen()),
        ),
      ),
    ));
  }

  @override
  void dispose() {
    SessionService.changes.removeListener(_loadStats);
    _warningSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: SafeArea(
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Mindful Minute',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: Colors.teal.shade800)),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _StatChip(label: 'Sessions', value: '$_total'),
              const SizedBox(width: 16),
              _StatChip(label: 'Streak', value: '$_streak 🔥'),
            ]),
            const SizedBox(height: 48),
            Icon(Icons.self_improvement, size: 96, color: Colors.teal.shade300),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ActivityPickerScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Start a Mindful Minute'),
            ),
            const SizedBox(height: 12),
            Text('Monitoring runs in the background',
                style: TextStyle(fontSize: 12, color: Colors.teal.shade600)),
          ]),
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
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.teal.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 20, color: Colors.teal.shade800)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.teal.shade600)),
        ]),
      );
}
