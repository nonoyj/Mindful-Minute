import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../theme.dart';
import 'nature_scenes.dart';
import 'wellness_texts.dart';

const int kActivitySeconds = 60;

// ---------------------------------------------------------------- Breathing
class BreathingContent extends StatelessWidget {
  final int remaining;
  final bool running;
  const BreathingContent({super.key, required this.remaining, required this.running});

  @override
  Widget build(BuildContext context) {
    final inhale = ((kActivitySeconds - remaining) % 8) < 4;
    final label = !running
        ? 'Ready when you are'
        : (inhale ? 'Breathe in...' : 'Breathe out...');
    final size = running ? (inhale ? 220.0 : 150.0) : 170.0;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w500, color: Pal.accent)),
        const SizedBox(height: 24),
        SizedBox(
          height: 240,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(seconds: 4),
              curve: Curves.easeInOut,
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Pal.accent.withValues(alpha: 0.2),
                border: Border.all(color: Pal.accent, width: 3),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ------------------------------------------------------ Wellness Reminders
/// Calming animated scene (new one every 30 s, 30 variations) + rotating
/// texts (quotes, research, tips, reminders). Music is added by the runner.
class RemindersContent extends StatefulWidget {
  final int remaining;
  final bool running;
  const RemindersContent({super.key, required this.remaining, required this.running});

  @override
  State<RemindersContent> createState() => _RemindersContentState();
}

class _RemindersContentState extends State<RemindersContent> {
  final _rand = math.Random();
  late final int _startScene = _rand.nextInt(kSceneVariants);
  late final List<WellnessText> _texts =
      (List.of(kWellnessTexts)..shuffle(_rand)).take(8).toList();

  @override
  Widget build(BuildContext context) {
    final elapsed = kActivitySeconds - widget.remaining;
    final scene = (_startScene + (elapsed ~/ 30) * 7) % kSceneVariants;
    final item = _texts[(elapsed ~/ 10) % _texts.length];
    return Stack(children: [
      Positioned.fill(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 1500),
          child: NatureScene(key: ValueKey(scene), variant: scene),
        ),
      ),
      Positioned(
        left: 8,
        right: 8,
        bottom: 8,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Container(
            key: ValueKey(item.text),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.kind.toUpperCase(),
                    style: const TextStyle(
                        color: Pal.accent,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(item.text,
                    style: const TextStyle(fontSize: 16, height: 1.35, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    ]);
  }
}
