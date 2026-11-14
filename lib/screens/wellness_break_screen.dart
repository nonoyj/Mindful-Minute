import 'dart:async';
import 'package:flutter/material.dart';

import '../models/user_preferences.dart';
import '../services/guard_service.dart';
import '../services/usage_service.dart';
import '../theme.dart';
import 'activities/activity_music.dart';
import 'activities/activity_runner.dart';

enum _Stage { ring, activity, done }

/// "You've reached your limit" screen + the sequence of activities.
///
/// V2 behaviour
/// locked == true  : real break. You may leave at any time (Back or
///                   "Not now"), which sends you Home. The monitored app
///                   stays BLOCKED: opening it again brings you back here.
///                   Finishing every activity unblocks it and resets its limit.
/// locked == false : preview from the editor (nothing is blocked/unblocked).
class WellnessBreakScreen extends StatefulWidget {
  final MonitoredApp app;
  final bool locked;
  const WellnessBreakScreen({super.key, required this.app, required this.locked});

  @override
  State<WellnessBreakScreen> createState() => _WellnessBreakScreenState();
}

class _WellnessBreakScreenState extends State<WellnessBreakScreen>
    with WidgetsBindingObserver {
  _Stage _stage = _Stage.ring;
  int _i = 0;
  DateTime _now = DateTime.now();
  Timer? _clock;
  bool _activityRunning = false; // true only while the 60 s timer runs
  bool _inForeground = true; // music only plays while the app is on screen

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final fg = state == AppLifecycleState.resumed;
    if (fg != _inForeground) setState(() => _inForeground = fg);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    if (widget.locked) GuardService.setActivityLock(false);
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    super.dispose();
  }

  void _startBreak() => setState(() {
        _i = 0;
        _stage = _Stage.activity;
      });

  /// The activity timer started/stopped. While it runs the user cannot leave.
  void _onRunning(bool running) {
    if (widget.locked) GuardService.setActivityLock(running);
    if (mounted) setState(() => _activityRunning = running);
  }

  /// Cancel = emergency exit: back to the limit screen, where leaving is
  /// allowed again. The app stays blocked either way.
  void _cancelBreak() {
    _onRunning(false);
    setState(() => _stage = _Stage.ring);
  }

  /// Leave without finishing: the app stays blocked.
  void _leave() {
    if (mounted) Navigator.of(context).pop();
    if (widget.locked) GuardService.goHome();
  }

  Future<void> _next() async {
    final acts = widget.app.activities;
    if (_i + 1 < acts.length) {
      setState(() => _i++);
      return;
    }
    // All activities finished: unblock the app and reset its limit.
    if (widget.locked) {
      await GuardService.unblock(widget.app.packageName);
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
          locked: widget.locked && _activityRunning, // no back arrow while running
          onRunningChanged: _onRunning,
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
    final canPop = !widget.locked || _stage == _Stage.done;
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_stage == _Stage.activity) {
          if (_activityRunning) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(
                  content: Text('Tap Cancel first if you need to leave.')));
          } else {
            _cancelBreak(); // activity not started yet: back to the limit screen
          }
        } else {
          _leave(); // limit screen: Back = Home, the app stays blocked
        }
      },
      child: body,
    );
  }

  Widget _ringView() {
    final acts = widget.app.activities;
    final h = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final m = _now.minute.toString().padLeft(2, '0');
    final count = '${acts.length} ${acts.length == 1 ? 'activity' : 'activities'}';
    final screen = Scaffold(
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
                widget.locked
                    ? '${widget.app.displayName} stays blocked until you finish $count'
                    : '$count to complete',
                textAlign: TextAlign.center,
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
              TextButton(
                onPressed: _leave,
                child: Text(widget.locked ? 'Not now, take me home' : 'Close preview',
                    style: const TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ),
    );
    // Limit-screen song: loops on this screen only (real breaks, not previews).
    // It stops when the activities start (each has its own song) and starts
    // again if you cancel back here, because this view is rebuilt.
    if (!widget.locked) return screen;
    return Stack(fit: StackFit.expand, children: [
      screen,
      MusicLayer(asset: 'audio/limit_screen.mp3', running: _inForeground),
    ]);
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
                      ? '${widget.app.displayName} is unlocked and its limit has been reset.'
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
