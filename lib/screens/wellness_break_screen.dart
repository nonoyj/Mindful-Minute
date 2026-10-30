import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user_preferences.dart';
import '../services/guard_service.dart';
import '../services/usage_service.dart';
import '../theme.dart';
import 'activities/activity_runner.dart';

enum _Stage { ring, activity, done }

/// "You've reached your limit" screen + the sequence of activities.
///
/// locked == true  : real break. Native lock keeps the phone here, music plays
///                   on the ring screen, and finishing everything resets the
///                   app's limit and unlocks the phone.
/// locked == false : preview from the editor (no lock, no music).
class WellnessBreakScreen extends StatefulWidget {
  final MonitoredApp app;
  final bool locked;
  const WellnessBreakScreen({super.key, required this.app, required this.locked});

  @override
  State<WellnessBreakScreen> createState() => _WellnessBreakScreenState();
}

class _WellnessBreakScreenState extends State<WellnessBreakScreen> {
  _Stage _stage = _Stage.ring;
  int _i = 0;
  DateTime _now = DateTime.now();
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    if (widget.locked) {
      // Hide status + navigation bars (a swipe only reveals them briefly).
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      GuardService.setMusic(true);
    }
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    if (widget.locked) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  void _startBreak() {
    if (widget.locked) GuardService.setMusic(false); // music pauses during activities
    setState(() {
      _i = 0;
      _stage = _Stage.activity;
    });
  }

  void _cancelBreak() {
    // Cancelled mid-break -> back to the limit screen, music resumes.
    if (widget.locked) GuardService.setMusic(true);
    setState(() => _stage = _Stage.ring);
  }

  Future<void> _next() async {
    final acts = widget.app.activities;
    if (_i + 1 < acts.length) {
      setState(() => _i++);
      return;
    }
    // All activities finished: unlock, stop music, reset this app's limit.
    if (widget.locked) {
      await GuardService.stop();
      await UsageService.resetApp(widget.app.packageName);
      await GuardService.cancelWarnings(widget.app.packageName);
    }
    if (mounted) setState(() => _stage = _Stage.done);
  }

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context) {
    final acts = widget.app.activities;
    Widget body;
    switch (_stage) {
      case _Stage.activity:
        body = ActivityRunnerScreen(
          key: ValueKey('act$_i'),
          type: acts[_i],
          stepLabel: '${_i + 1} / ${acts.length}',
          locked: widget.locked,
          onComplete: _next,
          onCancel: _cancelBreak,
          doneLabel: _i == acts.length - 1 ? 'Finish' : 'Next',
        );
        break;
      case _Stage.done:
        body = _doneView();
        break;
      case _Stage.ring:
        body = _ringView();
        break;
    }
    return PopScope(canPop: !widget.locked || _stage == _Stage.done, child: body);
  }

  Widget _ringView() {
    final acts = widget.app.activities;
    final h = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final m = _now.minute.toString().padLeft(2, '0');
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E1F24), Color(0xFF14504F), Color(0xFF2DD4BF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const SizedBox(height: 40),
              Text('${_months[_now.month - 1]} ${_now.day} ${_days[_now.weekday - 1]}',
                  style: const TextStyle(fontSize: 18, color: Colors.white70)),
              Text('$h:$m',
                  style: const TextStyle(
                      fontSize: 96, fontWeight: FontWeight.w700, color: Colors.white)),
              const Spacer(),
              const Icon(Icons.self_improvement, size: 72, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                widget.locked
                    ? "You've reached your limit for ${widget.app.displayName}"
                    : 'Preview: this is what you will see',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                '${acts.length} ${acts.length == 1 ? 'activity' : 'activities'} to complete',
                style: const TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startBreak,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Pal.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Start Wellness Break'),
                ),
              ),
              if (!widget.locked)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close preview',
                      style: TextStyle(color: Colors.white70)),
                ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _doneView() => Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle, size: 100, color: Pal.accent),
                const SizedBox(height: 16),
                const Text('Wellness break complete',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  widget.locked
                      ? "You're free. Your ${widget.app.displayName} limit has been reset."
                      : 'Preview finished.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Pal.muted),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Pal.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                  child: const Text('Back to dashboard'),
                ),
              ]),
            ),
          ),
        ),
      );
}
