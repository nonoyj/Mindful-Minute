import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme.dart';

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
  MiniGame('Memory Match', 'Match the pairs. Trains working memory.', () => const _MemoryMatch()),
  MiniGame('Color Sequence', 'Repeat the pattern. Builds focus.', () => const _ColorSequence()),
  MiniGame('Color vs Word', 'Tap the ink color. Trains self-control.', () => const _ColorWord()),
  MiniGame('Gratitude Tap', 'Notice the good. Boosts mood.', () => const _Gratitude()),
  MiniGame('Grow the Garden', 'Tap to nurture. Calm and relaxing.', () => const _Garden()),
  MiniGame('Rhythm Ring', 'Tap with the ring. Mindful timing.', () => const _RhythmRing()),
  MiniGame('Calm Words', 'Unscramble positive words.', () => const _CalmWords()),
  MiniGame('Name the Feeling', 'Naming emotions helps calm them.', () => const _NameFeeling()),
  MiniGame('Light Up', 'Light every tile. Gentle problem solving.', () => const _LightUp()),
  MiniGame('Digit Memory', 'Remember the digits. Sharpens recall.', () => const _DigitMemory()),
  MiniGame('Pick a Card', 'Pick a card for a kind affirmation.', () => const _PickCard()),
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
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(_game.instructions, style: TextStyle(color: Pal.muted)),
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
                        color: Pal.accent.withValues(alpha: 0.3),
                        border: Border.all(color: Pal.accent, width: 2),
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
                      backgroundColor: Pal.accent, foregroundColor: Colors.black),
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
            style: TextStyle(fontSize: 44, color: Colors.white)),
        const SizedBox(height: 24),
        Wrap(spacing: 12, children: [
          for (final o in _opts)
            ElevatedButton(
              onPressed: () => setState(() {
                if (o == _a + _b) _score++;
                _newQ();
              }),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Pal.accent, foregroundColor: Colors.black),
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

// ============================================================ NEW GAMES (5-15)

Widget _mutedText(String t) =>
    Text(t, textAlign: TextAlign.center, style: const TextStyle(color: Pal.muted));

ButtonStyle get _neutralBtn => ElevatedButton.styleFrom(
      backgroundColor: Pal.card2,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    );

// ------------------------------------------------------------ Memory Match
class _MemoryMatch extends StatefulWidget {
  const _MemoryMatch();
  @override
  State<_MemoryMatch> createState() => _MemoryMatchState();
}

class _MemoryMatchState extends State<_MemoryMatch> {
  static const _emoji = ['🌿', '🌸', '🐢', '🌙', '☀️', '🐟'];
  late List<String> _cards;
  late List<bool> _up;
  int? _first;
  bool _busy = false;
  int _pairs = 0;

  @override
  void initState() {
    super.initState();
    _deal();
  }

  void _deal() {
    _cards = [..._emoji, ..._emoji]..shuffle();
    _up = List.filled(12, false);
    _first = null;
  }

  Future<void> _tap(int i) async {
    if (_busy || _up[i]) return;
    setState(() => _up[i] = true);
    if (_first == null) {
      _first = i;
      return;
    }
    final a = _first!;
    _first = null;
    if (_cards[a] == _cards[i]) {
      setState(() => _pairs++);
      if (_up.every((e) => e)) {
        _busy = true;
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) setState(() { _deal(); _busy = false; });
      }
    } else {
      _busy = true;
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() { _up[a] = false; _up[i] = false; _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        _scoreText(_pairs),
        Expanded(
          child: GridView.count(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (var i = 0; i < 12; i++)
                InkWell(
                  onTap: () => _tap(i),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _up[i] ? Pal.card2 : Pal.accent.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_up[i] ? _cards[i] : '?',
                        style: const TextStyle(fontSize: 30)),
                  ),
                ),
            ],
          ),
        ),
      ]);
}

// ---------------------------------------------------------- Color Sequence
class _ColorSequence extends StatefulWidget {
  const _ColorSequence();
  @override
  State<_ColorSequence> createState() => _ColorSequenceState();
}

class _ColorSequenceState extends State<_ColorSequence> {
  static const _cols = [
    Color(0xFF2DD4BF), Color(0xFFFFB74D), Color(0xFFF48FB1), Color(0xFF64B5F6)
  ];
  final _r = Random();
  List<int> _seq = [];
  int _idx = 0, _score = 0, _lit = -1;
  bool _showing = true;

  @override
  void initState() {
    super.initState();
    _seq = [_r.nextInt(4)];
    _play();
  }

  Future<void> _play() async {
    setState(() { _showing = true; _idx = 0; });
    await Future.delayed(const Duration(milliseconds: 600));
    for (final c in List<int>.from(_seq)) {
      if (!mounted) return;
      setState(() => _lit = c);
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() => _lit = -1);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (mounted) setState(() => _showing = false);
  }

  void _press(int c) {
    if (_showing) return;
    setState(() => _lit = c);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _lit = -1);
    });
    if (c == _seq[_idx]) {
      _idx++;
      if (_idx == _seq.length) {
        _score = _seq.length;
        _seq.add(_r.nextInt(4));
        _play();
      }
    } else {
      _seq = [_r.nextInt(4)];
      _play();
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        _scoreText(_score),
        _mutedText(_showing ? 'Watch...' : 'Your turn'),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              for (var i = 0; i < 4; i++)
                GestureDetector(
                  onTap: () => _press(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    decoration: BoxDecoration(
                      color: _lit == i ? _cols[i] : _cols[i].withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ]);
}

// ------------------------------------------------------------ Color vs Word
class _ColorWord extends StatefulWidget {
  const _ColorWord();
  @override
  State<_ColorWord> createState() => _ColorWordState();
}

class _ColorWordState extends State<_ColorWord> {
  static const _names = ['RED', 'BLUE', 'GREEN', 'YELLOW'];
  static const _cols = [
    Color(0xFFEF5350), Color(0xFF42A5F5), Color(0xFF66BB6A), Color(0xFFFFEE58)
  ];
  final _r = Random();
  int _word = 0, _ink = 0, _score = 0;

  @override
  void initState() {
    super.initState();
    _new();
  }

  void _new() {
    _word = _r.nextInt(4);
    _ink = _r.nextInt(4);
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        _scoreText(_score),
        const Spacer(),
        Text(_names[_word],
            style: TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: _cols[_ink])),
        const SizedBox(height: 12),
        _mutedText('Tap the name of the COLOR the word is written in'),
        const Spacer(),
        Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
          for (var i = 0; i < 4; i++)
            ElevatedButton(
              style: _neutralBtn,
              onPressed: () => setState(() {
                if (i == _ink) _score++;
                _new();
              }),
              child: Text(_names[i]),
            ),
        ]),
        const SizedBox(height: 16),
      ]);
}

// -------------------------------------------------------------- Gratitude
class _Gratitude extends StatefulWidget {
  const _Gratitude();
  @override
  State<_Gratitude> createState() => _GratitudeState();
}

class _GratitudeState extends State<_Gratitude> {
  static const _items = [
    ('👪', 'Family'), ('🧑‍🤝‍🧑', 'Friends'), ('💪', 'Health'),
    ('☀️', 'Sunshine'), ('🎵', 'Music'), ('🍲', 'Food'),
    ('🏠', 'Home'), ('🐾', 'Pets'), ('📚', 'Learning'),
  ];
  final Set<int> _sel = {};

  @override
  Widget build(BuildContext context) => Column(children: [
        _mutedText('Tap what you feel grateful for today'),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            children: [
              for (var i = 0; i < _items.length; i++)
                InkWell(
                  onTap: () => setState(() {
                    if (!_sel.remove(i)) _sel.add(i);
                  }),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _sel.contains(i)
                          ? Pal.accent.withValues(alpha: 0.3)
                          : Pal.card2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: _sel.contains(i) ? Pal.accent : Colors.transparent),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(_items[i].$1, style: const TextStyle(fontSize: 30)),
                      const SizedBox(height: 4),
                      Text(_items[i].$2, style: const TextStyle(fontSize: 12)),
                    ]),
                  ),
                ),
            ],
          ),
        ),
        _mutedText(_sel.isEmpty
            ? ''
            : '${_sel.length} good thing${_sel.length > 1 ? 's' : ''}. Notice how that feels.'),
      ]);
}

// ------------------------------------------------------------ Grow Garden
class _Garden extends StatefulWidget {
  const _Garden();
  @override
  State<_Garden> createState() => _GardenState();
}

class _GardenState extends State<_Garden> {
  static const _icons = ['🟫', '🌱', '🌿', '🌸'];
  final List<int> _stage = List.filled(12, 0);
  int _blooms = 0;

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('Blooms: $_blooms',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (var i = 0; i < 12; i++)
                InkWell(
                  onTap: () => setState(() {
                    if (_stage[i] == 3) {
                      _stage[i] = 0;
                    } else {
                      _stage[i]++;
                      if (_stage[i] == 3) _blooms++;
                    }
                  }),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Pal.card2, borderRadius: BorderRadius.circular(12)),
                    child: Text(_icons[_stage[i]], style: const TextStyle(fontSize: 30)),
                  ),
                ),
            ],
          ),
        ),
        _mutedText('Tap a plot to nurture it'),
      ]);
}

// ------------------------------------------------------------ Rhythm Ring
class _RhythmRing extends StatefulWidget {
  const _RhythmRing();
  @override
  State<_RhythmRing> createState() => _RhythmRingState();
}

class _RhythmRingState extends State<_RhythmRing> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
        ..repeat();
  int _score = 0;
  String _msg = 'Tap when the ring meets the circle';

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _tap() {
    final t = _c.value;
    setState(() {
      if (t > 0.86) {
        _score++;
        _msg = 'Perfect. Stay with your breath.';
      } else {
        _msg = t < 0.5 ? 'A little early. Breathe and wait.' : 'Almost. Breathe and try again.';
      }
    });
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        _scoreText(_score),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _tap,
            child: Center(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) {
                  final ring = 80 + (1 - _c.value) * 140;
                  return SizedBox(
                    width: 230,
                    height: 230,
                    child: Stack(alignment: Alignment.center, children: [
                      Container(
                        width: ring,
                        height: ring,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Pal.accent, width: 4)),
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Pal.accent.withValues(alpha: 0.35)),
                      ),
                    ]),
                  );
                },
              ),
            ),
          ),
        ),
        _mutedText(_msg),
        const SizedBox(height: 12),
      ]);
}

// -------------------------------------------------------------- Calm Words
class _CalmWords extends StatefulWidget {
  const _CalmWords();
  @override
  State<_CalmWords> createState() => _CalmWordsState();
}

class _CalmWordsState extends State<_CalmWords> {
  static const _words = [
    'CALM', 'PEACE', 'HAPPY', 'SMILE', 'BREATHE', 'GENTLE', 'RELAX',
    'HOPE', 'KIND', 'JOY', 'LOVE', 'REST', 'TRUST', 'GRACE'
  ];
  final _r = Random();
  late String _word;
  late List<String> _letters;
  List<int> _picked = [];
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _new();
  }

  void _new() {
    _word = _words[_r.nextInt(_words.length)];
    do {
      _letters = _word.split('')..shuffle(_r);
    } while (_letters.join() == _word);
    _picked = [];
  }

  void _tap(int i) => setState(() {
        _picked.add(i);
        if (_picked.length == _word.length) {
          final guess = _picked.map((k) => _letters[k]).join();
          if (guess == _word) {
            _score++;
            _new();
          } else {
            _picked = [];
          }
        }
      });

  @override
  Widget build(BuildContext context) => Column(children: [
        _scoreText(_score),
        _mutedText('Unscramble the calming word'),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: Center(
            child: Text(_picked.map((k) => _letters[k]).join(' '),
                style: const TextStyle(
                    fontSize: 36, letterSpacing: 4, color: Pal.accent)),
          ),
        ),
        const Spacer(),
        Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
          for (var i = 0; i < _letters.length; i++)
            ElevatedButton(
              style: _neutralBtn,
              onPressed: _picked.contains(i) ? null : () => _tap(i),
              child: Text(_letters[i], style: const TextStyle(fontSize: 22)),
            ),
        ]),
        TextButton(
          onPressed: () => setState(() => _picked = []),
          child: const Text('Clear'),
        ),
        const Spacer(),
      ]);
}

// -------------------------------------------------------- Name the Feeling
class _NameFeeling extends StatefulWidget {
  const _NameFeeling();
  @override
  State<_NameFeeling> createState() => _NameFeelingState();
}

class _NameFeelingState extends State<_NameFeeling> {
  static const _f = [
    ('😊', 'Happy'), ('😢', 'Sad'), ('😠', 'Angry'), ('😰', 'Anxious'),
    ('😌', 'Calm'), ('😴', 'Tired'), ('😮', 'Surprised'), ('🤩', 'Excited'),
  ];
  final _r = Random();
  int _cur = 0, _score = 0;
  List<int> _opts = [];

  @override
  void initState() {
    super.initState();
    _new();
  }

  void _new() {
    _cur = _r.nextInt(_f.length);
    final s = <int>{_cur};
    while (s.length < 3) {
      s.add(_r.nextInt(_f.length));
    }
    _opts = s.toList()..shuffle(_r);
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        _scoreText(_score),
        const Spacer(),
        Text(_f[_cur].$1, style: const TextStyle(fontSize: 90)),
        const SizedBox(height: 8),
        _mutedText('Which feeling is this?'),
        const Spacer(),
        Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
          for (final o in _opts)
            ElevatedButton(
              style: _neutralBtn,
              onPressed: () => setState(() {
                if (o == _cur) _score++;
                _new();
              }),
              child: Text(_f[o].$2, style: const TextStyle(fontSize: 18)),
            ),
        ]),
        const SizedBox(height: 12),
        _mutedText('Naming a feeling helps calm it.'),
        const SizedBox(height: 8),
      ]);
}

// ---------------------------------------------------------------- Light Up
class _LightUp extends StatefulWidget {
  const _LightUp();
  @override
  State<_LightUp> createState() => _LightUpState();
}

class _LightUpState extends State<_LightUp> {
  final _r = Random();
  List<bool> _on = List.filled(9, true);
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _scramble();
  }

  void _toggle(List<bool> l, int i) {
    final r = i ~/ 3, c = i % 3;
    for (final (dr, dc) in const [(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final nr = r + dr, nc = c + dc;
      if (nr >= 0 && nr < 3 && nc >= 0 && nc < 3) l[nr * 3 + nc] = !l[nr * 3 + nc];
    }
  }

  void _scramble() {
    do {
      _on = List.filled(9, true);
      for (var k = 0; k < 5; k++) {
        _toggle(_on, _r.nextInt(9));
      }
    } while (_on.every((e) => e));
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        _scoreText(_score),
        _mutedText('Tap a tile to flip it and its neighbors. Light them all.'),
        const SizedBox(height: 8),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var i = 0; i < 9; i++)
                    GestureDetector(
                      onTap: () => setState(() {
                        _toggle(_on, i);
                        if (_on.every((e) => e)) {
                          _score++;
                          _scramble();
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: _on[i] ? Pal.accent : Pal.card2,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ]);
}

// ------------------------------------------------------------ Digit Memory
class _DigitMemory extends StatefulWidget {
  const _DigitMemory();
  @override
  State<_DigitMemory> createState() => _DigitMemoryState();
}

class _DigitMemoryState extends State<_DigitMemory> {
  final _r = Random();
  String _digits = '', _input = '';
  bool _show = true;
  int _len = 3, _score = 0;

  @override
  void initState() {
    super.initState();
    _round();
  }

  Future<void> _round() async {
    _digits = List.generate(_len, (_) => _r.nextInt(10)).join();
    _input = '';
    setState(() => _show = true);
    await Future.delayed(Duration(milliseconds: 1200 + _len * 450));
    if (mounted) setState(() => _show = false);
  }

  void _press(String d) {
    if (_show) return;
    setState(() => _input += d);
    if (_input.length == _digits.length) {
      if (_input == _digits) {
        _score++;
        _len = min(_len + 1, 7);
      } else {
        _len = max(3, _len - 1);
      }
      _round();
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        _scoreText(_score),
        _mutedText(_show ? 'Remember the digits' : 'Type them back'),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: Center(
            child: Text(_show ? _digits : _input,
                style: const TextStyle(
                    fontSize: 44, letterSpacing: 8, color: Pal.accent)),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 1.8,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final d in const ['1','2','3','4','5','6','7','8','9','','0'])
                d.isEmpty
                    ? const SizedBox()
                    : ElevatedButton(
                        style: _neutralBtn,
                        onPressed: _show ? null : () => _press(d),
                        child: Text(d, style: const TextStyle(fontSize: 22)),
                      ),
            ],
          ),
        ),
      ]);
}

// -------------------------------------------------------------- Pick a Card
class _PickCard extends StatefulWidget {
  const _PickCard();
  @override
  State<_PickCard> createState() => _PickCardState();
}

class _PickCardState extends State<_PickCard> {
  static const _aff = [
    'I am doing my best, and that is enough.',
    'I can take this one step at a time.',
    "My worth is not measured by productivity.",
    'I choose calm over chaos.',
    'This feeling will pass.',
    'I am allowed to rest.',
    'I can begin again at any moment.',
    'I am present and I am capable.',
    "I let go of what I can't control.",
    'I deserve kindness, especially from myself.',
    'Small progress is still progress.',
    'I am more than my worries.',
  ];
  final _r = Random();
  late List<String> _texts;
  int _open = -1, _score = 0;

  @override
  void initState() {
    super.initState();
    _deal();
  }

  void _deal() {
    _texts = (List.of(_aff)..shuffle(_r)).take(3).toList();
    _open = -1;
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        _scoreText(_score),
        _mutedText('Pick a card'),
        const SizedBox(height: 8),
        Expanded(
          child: Row(children: [
            for (var i = 0; i < 3; i++)
              Expanded(
                child: InkWell(
                  onTap: () => setState(() {
                    if (_open == -1) {
                      _open = i;
                      _score++;
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.all(6),
                    padding: const EdgeInsets.all(8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _open == i ? Pal.accent.withValues(alpha: 0.25) : Pal.card2,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(_open == i ? _texts[i] : '✨',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: _open == i ? 15 : 36)),
                  ),
                ),
              ),
          ]),
        ),
        if (_open != -1)
          ElevatedButton(
            style: _neutralBtn,
            onPressed: () => setState(_deal),
            child: const Text('New cards'),
          ),
      ]);
}
