import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/user_preferences.dart';
import '../../services/session_service.dart';
import 'content_widgets.dart';
import 'mini_games.dart';

/// Runs ANY activity for 60 seconds and records the completed session.
class ActivityRunnerScreen extends StatefulWidget {
  final WellnessActivityType type;
  final String? banner;
  const ActivityRunnerScreen({super.key, required this.type, this.banner});

  @override
  State<ActivityRunnerScreen> createState() => _ActivityRunnerScreenState();
}

class _ActivityRunnerScreenState extends State<ActivityRunnerScreen> {
  int _remaining = kActivitySeconds;
  bool _running = false;
  bool _done = false;
  Timer? _timer;

  void _start() {
    setState(() {
      _running = true;
      _remaining = kActivitySeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        setState(() {
          _remaining = 0;
          _running = false;
          _done = true;
        });
        _complete();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  Future<void> _complete() async {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.mediumImpact();
    await SessionService.recordCompletion();
  }

  void _cancel() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining = kActivitySeconds;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _content() {
    if (_done) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle, size: 96, color: Colors.teal.shade400),
          const SizedBox(height: 16),
          Text('Well done!',
              style: TextStyle(fontSize: 28, color: Colors.teal.shade800)),
          const SizedBox(height: 8),
          Text('Session saved.', style: TextStyle(color: Colors.teal.shade600)),
        ]),
      );
    }
    switch (widget.type) {
      case WellnessActivityType.breathing:
        return BreathingContent(remaining: _remaining, running: _running);
      case WellnessActivityType.quotes:
        return RotatingTextContent(
            items: kQuotes,
            intervalSeconds: 12,
            remaining: _remaining,
            icon: Icons.format_quote);
      case WellnessActivityType.textReminder:
        return RotatingTextContent(
            items: kReminders,
            intervalSeconds: 15,
            remaining: _remaining,
            icon: Icons.favorite_border);
      case WellnessActivityType.audio:
        return AudioContent(running: _running);
      case WellnessActivityType.video:
        return const NatureContent();
      case WellnessActivityType.miniGame:
        return _running
            ? const MiniGameContent(key: ValueKey('game'))
            : Center(
                child: Text('Tap Start for a one-minute game',
                    style: TextStyle(color: Colors.teal.shade700, fontSize: 16)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: Text(widget.type.label),
        backgroundColor: Colors.teal.shade50,
        foregroundColor: Colors.teal.shade800,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            if (widget.banner != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(widget.banner!,
                    style: TextStyle(color: Colors.orange.shade900)),
              ),
            Text('$_remaining s',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: Colors.teal.shade900)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: 1 - _remaining / kActivitySeconds,
              minHeight: 8,
              backgroundColor: Colors.teal.shade100,
              color: Colors.teal.shade400,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 16),
            Expanded(child: _content()),
            const SizedBox(height: 12),
            if (_done)
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: _btn(),
                child: const Text('Done'),
              )
            else ...[
              ElevatedButton(
                onPressed: _running ? null : _start,
                style: _btn(),
                child: Text(_running ? 'In Progress...' : 'Start'),
              ),
              if (_running)
                TextButton(
                  onPressed: _cancel,
                  child: Text('Cancel',
                      style: TextStyle(color: Colors.teal.shade700)),
                ),
            ],
          ]),
        ),
      ),
    );
  }

  ButtonStyle _btn() => ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: const TextStyle(fontSize: 18),
      );
}
