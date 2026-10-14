import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// To add more games (target is ~20): write a StatefulWidget and add one
/// entry to [miniGames]. The runner picks one at random each session.
class MiniGame {
  final String name;
  final String instructions;
  final Widget Function() build;
  const MiniGame(this.name, this.instructions, this.build);
}

final List<MiniGame> miniGames = [
  MiniGame('Bubble Pop', 'Tap the bubbles before they vanish.', () => const _BubblePop()),
  MiniGame('Tap in Order', 'Tap 1 to 9 in order.', () => const _TapInOrder()),
  MiniGame('Quick Math', 'Pick the right answer.', () => const _QuickMath()),
  MiniGame('Odd One Out', 'Find the different one.', () => const _OddOneOut()),
];

class MiniGameContent extends StatefulWidget {
  const MiniGameContent({super.key});
  @override
  State<MiniGameContent> createState() => _MiniGameContentState();
}

class _MiniGameContentState extends State<MiniGameContent> {
  late final MiniGame _game = miniGames[Random().nextInt(miniGames.length)];

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(_game.name,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
        Text(_game.instructions, style: TextStyle(color: Colors.teal.shade600)),
        const SizedBox(height: 8),
        Expanded(child: _game.build()),
      ]);
}

Widget _scoreText(int s) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('Score: $s',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
    );

// ------------------------------------------------------------- Bubble Pop
class _B {
  final double x, y;
  final DateTime born;
  _B(this.x, this.y, this.born);
}

class _BubblePop extends StatefulWidget {
  const _BubblePop();
  @override
  State<_BubblePop> createState() => _BubblePopState();
}

class _BubblePopState extends State<_BubblePop> {
  final _rand = Random();
  final List<_B> _bubbles = [];
  int _score = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final now = DateTime.now();
      setState(() {
        _bubbles.removeWhere((b) => now.difference(b.born).inMilliseconds > 2200);
        if (_bubbles.length < 6) {
          _bubbles.add(_B(_rand.nextDouble(), _rand.nextDouble(), now));
        }
      });
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        _scoreText(_score),
        Expanded(
          child: LayoutBuilder(
            builder: (_, box) => Stack(children: [
              for (final b in _bubbles)
                Positioned(
                  left: b.x * (box.maxWidth - 64),
                  top: b.y * (box.maxHeight - 64),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _bubbles.remove(b);
                      _score++;
                    }),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.teal.withValues(alpha: 0.3),
                        border: Border.all(color: Colors.teal.shade300, width: 2),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ]);
}

// ------------------------------------------------------------ Tap in Order
class _TapInOrder extends StatefulWidget {
  const _TapInOrder();
  @override
  State<_TapInOrder> createState() => _TapInOrderState();
}

class _TapInOrderState extends State<_TapInOrder> {
  List<int> _order = List.generate(9, (i) => i + 1)..shuffle();
  int _next = 1;
  int _rounds = 0;

  void _tap(int n) {
    if (n != _next) return;
    setState(() {
      _next++;
      if (_next > 9) {
        _rounds++;
        _next = 1;
        _order = List.generate(9, (i) => i + 1)..shuffle();
      }
    });
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        _scoreText(_rounds),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (final n in _order)
                ElevatedButton(
                  onPressed: n < _next ? null : () => _tap(n),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  child: Text('$n', style: const TextStyle(fontSize: 28)),
                ),
            ],
          ),
        ),
      ]);
}

// -------------------------------------------------------------- Quick Math
class _QuickMath extends StatefulWidget {
  const _QuickMath();
  @override
  State<_QuickMath> createState() => _QuickMathState();
}

class _QuickMathState extends State<_QuickMath> {
  final _r = Random();
  int _a = 0, _b = 0, _score = 0;
  List<int> _opts = [];

  @override
  void initState() {
    super.initState();
    _newQ();
  }

  void _newQ() {
    _a = _r.nextInt(20) + 1;
    _b = _r.nextInt(20) + 1;
    final ans = _a + _b;
    final s = <int>{ans};
    while (s.length < 3) {
      s.add(ans + _r.nextInt(7) - 3);
    }
    _opts = s.toList()..shuffle();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        _scoreText(_score),
        const Spacer(),
        Text('$_a + $_b = ?',
            style: TextStyle(fontSize: 44, color: Colors.teal.shade900)),
        const SizedBox(height: 24),
        Wrap(spacing: 12, children: [
          for (final o in _opts)
            ElevatedButton(
              onPressed: () => setState(() {
                if (o == _a + _b) _score++;
                _newQ();
              }),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, foregroundColor: Colors.white),
              child: Text('$o', style: const TextStyle(fontSize: 24)),
            ),
        ]),
        const Spacer(),
      ]);
}

// ------------------------------------------------------------ Odd One Out
class _OddOneOut extends StatefulWidget {
  const _OddOneOut();
  @override
  State<_OddOneOut> createState() => _OddOneOutState();
}

class _OddOneOutState extends State<_OddOneOut> {
  static const _pairs = [
    ['🌿', '🍃'], ['🐟', '🐠'], ['🌸', '🌼'], ['🌙', '🌛'], ['🐢', '🐊'],
  ];
  final _r = Random();
  int _odd = 0, _score = 0;
  late List<String> _pair;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    _pair = List<String>.from(_pairs[_r.nextInt(_pairs.length)]);
    if (_r.nextBool()) _pair = _pair.reversed.toList();
    _odd = _r.nextInt(16);
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        _scoreText(_score),
        Expanded(
          child: GridView.count(
            crossAxisCount: 4,
            children: [
              for (var i = 0; i < 16; i++)
                InkWell(
                  onTap: () {
                    if (i == _odd) setState(() { _score++; _newRound(); });
                  },
                  child: Center(
                    child: Text(i == _odd ? _pair[1] : _pair[0],
                        style: const TextStyle(fontSize: 34)),
                  ),
                ),
            ],
          ),
        ),
      ]);
}
