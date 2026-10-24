import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/user_preferences.dart';
import '../../services/session_service.dart';
import '../../theme.dart';
import 'activity_music.dart';
import 'content_widgets.dart';
import 'mini_games.dart';

/// Runs one activity for 60 seconds (dark UI, same look as the dashboard).
class ActivityRunnerScreen extends StatefulWidget {
  final WellnessActivityType type;
  final String? stepLabel; // e.g. "1 / 3"
  final bool locked; // real break: no back button
  final VoidCallback? onComplete; // Next / Finish pressed
  final VoidCallback? onCancel; // Cancel pressed while running
  final String doneLabel;
  const ActivityRunnerScreen({
    super.key,
    required this.type,
    this.stepLabel,
    this.locked = false,
    this.onComplete,
    this.onCancel,
    this.doneLabel = 'Done',
  });

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
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      setState(() {
        _running = false;
        _remaining = kActivitySeconds;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Each activity has its OWN music file (assets/audio/...).
  String get _musicAsset {
    switch (widget.type) {
      case WellnessActivityType.breathing:
        return 'audio/breathing.mp3';
      case WellnessActivityType.miniGame:
        return 'audio/mini_game.mp3';
      case WellnessActivityType.reminders:
        return 'audio/wellness_reminders.mp3';
    }
  }

  Widget _content() {
    if (_done) return _inner();
    return Stack(fit: StackFit.expand, children: [
      _inner(),
      MusicLayer(asset: _musicAsset, running: _running),
    ]);
  }

  Widget _inner() {
    if (_done) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: const [
          Icon(Icons.check_circle, size: 96, color: Pal.accent),
          SizedBox(height: 16),
          Text('Well done!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('Session saved.', style: TextStyle(color: Pal.muted)),
        ]),
      );
    }
    switch (widget.type) {
      case WellnessActivityType.breathing:
        return BreathingContent(remaining: _remaining, running: _running);
      case WellnessActivityType.reminders:
        return RemindersContent(remaining: _remaining, running: _running);
      case WellnessActivityType.miniGame:
        return _running
            ? const MiniGameContent(key: ValueKey('game'))
            : const Center(
                child: Text('Tap Start for a one-minute game',
                    style: TextStyle(color: Pal.muted, fontSize: 16)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.locked,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.locked,
          title: Text(widget.type.label),
          actions: [
            if (widget.stepLabel != null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(widget.stepLabel!,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Pal.accent)),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(children: [
              Text.rich(TextSpan(children: [
                TextSpan(
                    text: '$_remaining',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700)),
                const TextSpan(
                    text: '  sec', style: TextStyle(fontSize: 16, color: Pal.muted)),
              ])),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 1 - _remaining / kActivitySeconds,
                minHeight: 6,
                backgroundColor: Pal.card2,
                color: Pal.accent,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Pal.card, borderRadius: BorderRadius.circular(24)),
                  child: _content(),
                ),
              ),
              const SizedBox(height: 16),
              if (_done)
                _btn(widget.doneLabel, () {
                  if (widget.onComplete != null) {
                    widget.onComplete!();
                  } else {
                    Navigator.of(context).pop();
                  }
                })
              else if (_running)
                _btn('Cancel', _cancel, secondary: true)
              else
                _btn('Start', _start),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _btn(String label, VoidCallback onTap, {bool secondary = false}) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: secondary ? Pal.card2 : Pal.accent,
            foregroundColor: secondary ? Colors.white : Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          child: Text(label),
        ),
      );
}
