import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../theme.dart';
import 'nature_scenes.dart';
import 'wellness_texts.dart';

const int kActivitySeconds = 60;

// ---------------------------------------------------------------- Breathing
const _ballTop = Color(0xFF8FF0E0); // light teal (top of the ball)
const _ballShade = Pal.accent; // darker teal (curved shade at the bottom)
const _faceInk = Color(0xFF0B2B2A);
const _phaseLabels = ['Breathe in', 'Hold', 'Breathe out', 'Hold'];

/// Box breathing: 4 s in, 4 s hold, 4 s out, 4 s hold. A friendly face-ball
/// grows while you inhale and shrinks while you exhale; four dots count each
/// phase and a bar fills/empties with the breath.
class BreathingContent extends StatefulWidget {
  final int remaining;
  final bool running;
  const BreathingContent({super.key, required this.remaining, required this.running});

  @override
  State<BreathingContent> createState() => _BreathingContentState();
}

class _BreathingContentState extends State<BreathingContent>
    with SingleTickerProviderStateMixin {
  static const _phaseSeconds = 4;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: _phaseSeconds * 4),
  );

  @override
  void initState() {
    super.initState();
    if (widget.running) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant BreathingContent old) {
    super.didUpdateWidget(old);
    if (widget.running && !old.running) {
      _c.value = 0;
      _c.repeat();
    } else if (!widget.running && old.running) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final secs = _c.value * _phaseSeconds * 4;
        final phase = (secs ~/ _phaseSeconds).clamp(0, 3);
        final local = (secs - phase * _phaseSeconds) / _phaseSeconds;
        final eased = Curves.easeInOut.transform(local.clamp(0.0, 1.0));

        // t: 0 = smallest ball, 1 = biggest ball.
        final double t;
        switch (phase) {
          case 0:
            t = eased;
            break;
          case 1:
            t = 1;
            break;
          case 2:
            t = 1 - eased;
            break;
          default:
            t = 0;
        }

        final running = widget.running;
        final label = running ? _phaseLabels[phase] : 'Ready when you are';
        final lit = running ? ((local * 4).floor().clamp(0, 3) + 1) : 0;

        return Column(
          children: [
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (i) {
                final on = i < lit;
                return Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on ? Pal.accent : Colors.white24,
                  ),
                );
              }),
            ),
            Expanded(
              child: SizedBox.expand(
                child: CustomPaint(painter: _BallPainter(running ? t : 0.35)),
              ),
            ),
            // Breath bar: fills while inhaling, empties while exhaling.
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 14,
                color: Pal.card2,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.04 + 0.96 * (running ? t : 0.35),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _ballTop,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _BallPainter extends CustomPainter {
  final double t; // 0..1
  _BallPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final maxR = math.min(size.width, size.height) / 2 - 8;
    if (maxR <= 0) return;
    final r = maxR * (0.62 + 0.38 * t);
    final c = size.center(Offset.zero);

    // Soft halo.
    canvas.drawCircle(
        c, r * 1.12, Paint()..color = Pal.accent.withValues(alpha: 0.10));

    // Ball body (light top + darker curved shade underneath).
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    canvas.drawRect(Offset.zero & size, Paint()..color = _ballTop);
    final shade = Path()
      ..moveTo(c.dx - r, c.dy + r * 0.09)
      ..quadraticBezierTo(c.dx, c.dy + r * 0.95, c.dx + r, c.dy + r * 0.09)
      ..lineTo(c.dx + r * 1.3, c.dy + r * 1.3)
      ..lineTo(c.dx - r * 1.3, c.dy + r * 1.3)
      ..close();
    canvas.drawPath(shade, Paint()..color = _ballShade);
    canvas.restore();

    // Face: sleepy eyes + brows; mouth goes from flat (full) to smile (small).
    final s = r;
    final fc = Offset(c.dx, c.dy - s * (0.30 + 0.20 * t));
    final ink = Paint()
      ..color = _faceInk
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(2.0, s * 0.03);

    for (final side in const [-1.0, 1.0]) {
      final ex = fc.dx + side * s * 0.14;
      canvas.drawPath(
        Path()
          ..moveTo(ex - s * 0.075, fc.dy)
          ..quadraticBezierTo(ex, fc.dy + s * 0.09, ex + s * 0.075, fc.dy),
        ink,
      );
      final by = fc.dy - s * 0.09;
      final tilt = s * 0.035 * t; // brows look more "effortful" when full
      canvas.drawLine(
        Offset(ex - side * s * 0.08, by - tilt), // inner end
        Offset(ex + side * s * 0.08, by + tilt), // outer end
        ink,
      );
    }

    final my = fc.dy + s * 0.18;
    final mw = s * 0.10;
    final bulge = s * 0.15 * (1 - t) - s * 0.01 * t;
    canvas.drawPath(
      Path()
        ..moveTo(fc.dx - mw, my)
        ..quadraticBezierTo(fc.dx, my + bulge * 1.0, fc.dx + mw, my),
      ink,
    );
  }

  @override
  bool shouldRepaint(covariant _BallPainter old) => old.t != t;
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
