import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

const int kActivitySeconds = 60;

const List<String> kQuotes = [
  'Start before you feel ready. Momentum is built by moving.',
  'Five minutes of effort beats an hour of dreading it.',
  'You do not need to feel motivated to begin.',
  'Small steps still cover the distance.',
  'The scroll will still be there later. Your goals will not wait forever.',
  'Done imperfectly is better than perfect and unfinished.',
  'Pick one task. Only one. Begin it now.',
  'Rest is part of the work, but so is returning to it.',
];

const List<String> kReminders = [
  'Drink a glass of water.',
  'Roll your shoulders back, slowly, three times.',
  'Look at something far away for 20 seconds.',
  'Unclench your jaw and relax your hands.',
  'Stand up and stretch your arms overhead.',
  'Write down the single next thing you need to do.',
  'Take one deep breath in through your nose, out through your mouth.',
];

// ---------------------------------------------------------------- Breathing
class BreathingContent extends StatelessWidget {
  final int remaining;
  final bool running;
  const BreathingContent({super.key, required this.remaining, required this.running});

  @override
  Widget build(BuildContext context) {
    final elapsed = kActivitySeconds - remaining;
    final inhale = (elapsed % 8) < 4;
    final label = !running
        ? 'Ready when you are'
        : (inhale ? 'Breathe in...' : 'Breathe out...');
    final size = running ? (inhale ? 220.0 : 150.0) : 170.0;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.teal.shade700)),
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
                color: Colors.teal.withValues(alpha: 0.2),
                border: Border.all(color: Colors.teal.shade300, width: 3),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ------------------------------------------------- Quotes / text reminders
class RotatingTextContent extends StatefulWidget {
  final List<String> items;
  final int intervalSeconds;
  final int remaining;
  final IconData icon;
  const RotatingTextContent({
    super.key,
    required this.items,
    required this.intervalSeconds,
    required this.remaining,
    required this.icon,
  });

  @override
  State<RotatingTextContent> createState() => _RotatingTextContentState();
}

class _RotatingTextContentState extends State<RotatingTextContent> {
  late final int _offset = math.Random().nextInt(widget.items.length);

  @override
  Widget build(BuildContext context) {
    final elapsed = kActivitySeconds - widget.remaining;
    final idx = (elapsed ~/ widget.intervalSeconds + _offset) % widget.items.length;
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: Padding(
          key: ValueKey(idx),
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, size: 48, color: Colors.teal.shade300),
            const SizedBox(height: 16),
            Text(widget.items[idx],
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22, height: 1.4, color: Colors.teal.shade900)),
          ]),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------- Nature scene
class NatureScene extends StatefulWidget {
  const NatureScene({super.key});
  @override
  State<NatureScene> createState() => _NatureSceneState();
}

class _NatureSceneState extends State<NatureScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 12))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _NaturePainter(_c.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _NaturePainter extends CustomPainter {
  final double t; // 0..1 loop
  _NaturePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB2DFDB), Color(0xFFE0F7FA)],
        ).createShader(rect),
    );
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.2), 34,
        Paint()..color = Colors.amber.shade100);

    // drifting light particles
    for (var i = 0; i < 14; i++) {
      final p = (t + i / 14) % 1.0;
      final x = size.width * (((i * 37) % 100) / 100) +
          12 * math.sin(p * 2 * math.pi * 2 + i);
      final y = size.height * (0.6 - p * 0.55);
      canvas.drawCircle(Offset(x, y), 3 + (i % 3).toDouble(),
          Paint()..color = Colors.white.withValues(alpha: 0.7 * (1 - p)));
    }

    // layered waves (seamless loop: integer cycles per t)
    for (var i = 0; i < 3; i++) {
      final path = Path()..moveTo(0, size.height);
      final base = size.height * (0.58 + i * 0.12);
      for (double x = 0; x <= size.width; x += 4) {
        final y = base +
            math.sin(x / size.width * 2 * math.pi * (i + 1) +
                    t * 2 * math.pi * (i.isEven ? 1 : -1)) *
                (10 + i * 4);
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(
          path, Paint()..color = Colors.teal.withValues(alpha: 0.25 + i * 0.15));
    }
  }

  @override
  bool shouldRepaint(_NaturePainter old) => old.t != t;
}

class NatureContent extends StatelessWidget {
  const NatureContent({super.key});
  @override
  Widget build(BuildContext context) => Stack(children: [
        const Positioned.fill(child: NatureScene()),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: Text('Let your eyes follow the waves',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.teal.shade900, fontSize: 16)),
        ),
      ]);
}

// ------------------------------------------------------------------ Audio
/// Self-generated soft ambient pad (a looping WAV built in memory), so no
/// audio asset files are required.
Uint8List _calmWav() {
  const rate = 22050;
  const seconds = 12; // frequencies below are m/12 Hz => loops seamlessly
  final n = rate * seconds;
  final d = ByteData(44 + n * 2);
  void s(int o, String v) {
    for (var i = 0; i < v.length; i++) {
      d.setUint8(o + i, v.codeUnitAt(i));
    }
  }

  s(0, 'RIFF');
  d.setUint32(4, 36 + n * 2, Endian.little);
  s(8, 'WAVE');
  s(12, 'fmt ');
  d.setUint32(16, 16, Endian.little);
  d.setUint16(20, 1, Endian.little);
  d.setUint16(22, 1, Endian.little);
  d.setUint32(24, rate, Endian.little);
  d.setUint32(28, rate * 2, Endian.little);
  d.setUint16(32, 2, Endian.little);
  d.setUint16(34, 16, Endian.little);
  s(36, 'data');
  d.setUint32(40, n * 2, Endian.little);

  const freqs = [130.75, 196.0, 261.5, 329.5];
  for (var i = 0; i < n; i++) {
    final t = i / rate;
    var v = 0.0;
    for (var k = 0; k < freqs.length; k++) {
      final lfo = 0.5 + 0.5 * math.sin(2 * math.pi * ((k + 1) / 12) * t);
      v += math.sin(2 * math.pi * freqs[k] * t) * lfo * 0.17;
    }
    d.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
  }
  return d.buffer.asUint8List();
}

class AudioContent extends StatefulWidget {
  final bool running;
  const AudioContent({super.key, required this.running});
  @override
  State<AudioContent> createState() => _AudioContentState();
}

class _AudioContentState extends State<AudioContent> {
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    if (widget.running) _play();
  }

  @override
  void didUpdateWidget(AudioContent old) {
    super.didUpdateWidget(old);
    if (widget.running && !old.running) _play();
    if (!widget.running && old.running) _player.stop();
  }

  Future<void> _play() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(BytesSource(_calmWav(), mimeType: 'audio/wav'));
    } catch (_) {}
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        const Positioned.fill(child: NatureScene()),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: Text(
              widget.running
                  ? 'Close your eyes and listen'
                  : 'Tap Start to begin the sound',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.teal.shade900, fontSize: 16)),
        ),
      ]);
}
