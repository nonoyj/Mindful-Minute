import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 10 palettes x 3 scene types = 30 distinct calming animations.
const int kSceneVariants = 30;

class _Pal {
  final Color top, bottom, a, b, orb;
  const _Pal(this.top, this.bottom, this.a, this.b, this.orb);
}

const _pals = [
  _Pal(Color(0xFF0A1822), Color(0xFF134048), Color(0xFF2DD4BF), Color(0xFF1B8A7A), Color(0xFFE6F4F1)), // lagoon
  _Pal(Color(0xFF1B1030), Color(0xFF4A2B6B), Color(0xFFB388FF), Color(0xFF7E57C2), Color(0xFFFFE0F7)), // violet dusk
  _Pal(Color(0xFF2B1A12), Color(0xFF8A4B2D), Color(0xFFFFB74D), Color(0xFFE65100), Color(0xFFFFF3C4)), // desert sunset
  _Pal(Color(0xFF0D2818), Color(0xFF1F5B3A), Color(0xFF81C784), Color(0xFF2E7D32), Color(0xFFF1F8E9)), // forest dawn
  _Pal(Color(0xFF0B1D3A), Color(0xFF1F4E8C), Color(0xFF64B5F6), Color(0xFF1976D2), Color(0xFFE3F2FD)), // ocean
  _Pal(Color(0xFF2A1220), Color(0xFF8C3B5E), Color(0xFFF48FB1), Color(0xFFC2185B), Color(0xFFFFEBEE)), // rose dusk
  _Pal(Color(0xFF10242A), Color(0xFF2F6F73), Color(0xFF80DEEA), Color(0xFF00838F), Color(0xFFE0F7FA)), // glacier
  _Pal(Color(0xFF1C1A0B), Color(0xFF5E5A1F), Color(0xFFDCE775), Color(0xFF9E9D24), Color(0xFFFFFDE7)), // moss gold
  _Pal(Color(0xFF1A1A2E), Color(0xFF3D3B6B), Color(0xFF9FA8DA), Color(0xFF3F51B5), Color(0xFFE8EAF6)), // indigo night
  _Pal(Color(0xFF2B1B0E), Color(0xFF7A5230), Color(0xFFFFCC80), Color(0xFF8D6E63), Color(0xFFFFF8E1)), // warm earth
];

class NatureScene extends StatefulWidget {
  final int variant; // 0..29
  const NatureScene({super.key, required this.variant});
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
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(
            painter: _ScenePainter(_c.value, widget.variant % kSceneVariants),
            size: Size.infinite,
          ),
        ),
      );
}

class _ScenePainter extends CustomPainter {
  final double t; // 0..1, loops seamlessly
  final int variant;
  _ScenePainter(this.t, this.variant);

  @override
  void paint(Canvas canvas, Size size) {
    final pal = _pals[(variant ~/ 3) % _pals.length];
    final layout = variant % 3;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [pal.top, pal.bottom],
        ).createShader(rect),
    );
    final orb = Offset(size.width * (0.2 + 0.6 * (((variant * 7) % 10) / 10)),
        size.height * 0.2);
    canvas.drawCircle(orb, 54, Paint()..color = pal.orb.withValues(alpha: 0.10));
    canvas.drawCircle(orb, 30, Paint()..color = pal.orb.withValues(alpha: 0.9));

    if (layout == 0) {
      _waves(canvas, size, pal);
    } else if (layout == 1) {
      _hills(canvas, size, pal);
    } else {
      _aurora(canvas, size, pal);
    }
  }

  void _waves(Canvas canvas, Size size, _Pal pal) {
    for (var i = 0; i < 14; i++) {
      final p = (t + i / 14) % 1.0;
      final x = size.width * (((i * 37) % 100) / 100) +
          12 * math.sin(p * 2 * math.pi * 2 + i);
      canvas.drawCircle(Offset(x, size.height * (0.6 - p * 0.55)), 3 + (i % 3).toDouble(),
          Paint()..color = Colors.white.withValues(alpha: 0.7 * (1 - p)));
    }
    for (var i = 0; i < 3; i++) {
      final path = Path()..moveTo(0, size.height);
      final base = size.height * (0.58 + i * 0.12);
      for (double x = 0; x <= size.width; x += 4) {
        path.lineTo(
            x,
            base +
                math.sin(x / size.width * 2 * math.pi * (i + 1) +
                        t * 2 * math.pi * (i.isEven ? 1 : -1)) *
                    (10 + i * 4));
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = pal.a.withValues(alpha: 0.14 + i * 0.12));
    }
  }

  void _hills(Canvas canvas, Size size, _Pal pal) {
    for (var i = 0; i < 3; i++) {
      final path = Path()..moveTo(0, size.height);
      final base = size.height * (0.55 + i * 0.12);
      final ph = variant * 0.9 + i * 1.7;
      for (double x = 0; x <= size.width; x += 4) {
        final u = x / size.width;
        path.lineTo(
            x,
            base -
                26 * math.sin(u * math.pi * (1.5 + i * 0.5) + ph) -
                14 * math.sin(u * math.pi * 3.7 + ph * 2));
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(
          path, Paint()..color = Color.lerp(pal.b, Colors.black, 0.15 + i * 0.25)!);
    }
    for (var i = 0; i < 3; i++) {
      final x = (((t + i / 3) % 1.0) * 1.5 - 0.25) * size.width;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(x, size.height * (0.5 + 0.08 * i)), width: 180, height: 30),
          const Radius.circular(20),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.10),
      );
    }
    for (var i = 0; i < 10; i++) {
      final bx = size.width * (((i * 53) % 100) / 100) +
          8 * math.sin(2 * math.pi * (t + i / 10));
      final by = size.height * (0.45 + ((i * 29) % 40) / 100);
      final a = 0.2 + 0.6 * (0.5 + 0.5 * math.sin(2 * math.pi * (t * 2 + i / 10)));
      canvas.drawCircle(Offset(bx, by), 2.5, Paint()..color = pal.a.withValues(alpha: a));
    }
  }

  void _aurora(Canvas canvas, Size size, _Pal pal) {
    for (var i = 0; i < 45; i++) {
      final x = size.width * (((i * 73) % 100) / 100);
      final y = size.height * (((i * 47) % 60) / 100);
      final a = 0.25 + 0.55 * (0.5 + 0.5 * math.sin(2 * math.pi * (t * 2 + i / 9)));
      canvas.drawCircle(Offset(x, y), 1.2 + (i % 3) * 0.5,
          Paint()..color = Colors.white.withValues(alpha: a));
    }
    for (var i = 0; i < 3; i++) {
      final path = Path();
      for (double x = 0; x <= size.width; x += 6) {
        final y = size.height * (0.25 + 0.07 * i) +
            22 * math.sin(x / size.width * 2 * math.pi * (1 + i) +
                t * 2 * math.pi * (i.isEven ? 1 : -1));
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 28
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
          ..color = (i.isEven ? pal.a : pal.b).withValues(alpha: 0.35),
      );
    }
    final g = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 6) {
      g.lineTo(x, size.height * 0.86 - 10 * math.sin(x / size.width * math.pi * 2 + variant));
    }
    g
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(g, Paint()..color = Color.lerp(pal.bottom, Colors.black, 0.6)!);
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.t != t || old.variant != variant;
}
