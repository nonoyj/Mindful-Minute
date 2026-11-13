import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme.dart';

/// 10 games in total. The player PICKS one before pressing Start.
/// To add a game: write a StatefulWidget and add one entry to [miniGames].
///
/// [preview] (optional) is shown BEFORE Start, with no timer. The Research
/// Quiz uses it as a study screen. The 60-second timer only begins when the
/// player presses Start in the runner.
class MiniGame {
  final String name;
  final String instructions;
  final IconData icon;
  final Widget Function() build;
  final Widget Function()? preview;
  const MiniGame(this.name, this.instructions, this.icon, this.build,
      {this.preview});
}

final List<MiniGame> miniGames = [
  MiniGame('Research Quiz', 'Study the cards, then take a 1-minute quiz.', Icons.quiz,
      () => const _ResearchQuiz(),
      preview: () => const _QuizStudy()),
  MiniGame('Bubble Pop', 'Tap the bubbles before they vanish.', Icons.bubble_chart,
      () => const _BubblePop()),
  MiniGame('Memory Match', 'Match the pairs. Trains working memory.', Icons.grid_view,
      () => const _MemoryMatch()),
  MiniGame('Color Sequence', 'Repeat the pattern. Builds focus.', Icons.palette,
      () => const _ColorSequence()),
  MiniGame('Color vs Word', 'Tap the ink color. Trains self-control.', Icons.text_fields,
      () => const _ColorWord()),
  MiniGame('Grow the Garden', 'Tap to nurture. Calm and relaxing.', Icons.local_florist,
      () => const _Garden()),
  MiniGame('Rhythm Ring', 'Tap with the ring. Mindful timing.', Icons.radio_button_checked,
      () => const _RhythmRing()),
  MiniGame('Calm Words', 'Unscramble positive words.', Icons.spellcheck,
      () => const _CalmWords()),
  MiniGame('Light Up', 'Light every tile. Gentle problem solving.', Icons.lightbulb_outline,
      () => const _LightUp()),
  MiniGame('Digit Memory', 'Remember the digits. Sharpens recall.', Icons.dialpad,
      () => const _DigitMemory()),
];

/// What the runner shows inside the white card for a mini-game activity.
///  - no game picked yet  -> the picker
///  - picked, not running -> preview (study screen for the quiz)
///  - running             -> the game itself
class MiniGameContent extends StatelessWidget {
  final MiniGame? game;
  final bool running;
  final ValueChanged<MiniGame?> onPick;
  const MiniGameContent({
    super.key,
    required this.game,
    required this.running,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final g = game;
    if (g == null) return _GamePicker(onPick: onPick);

    if (running) {
      return Column(children: [
        Text(g.name,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(g.instructions,
            textAlign: TextAlign.center, style: const TextStyle(color: Pal.muted)),
        const SizedBox(height: 8),
        Expanded(child: KeyedSubtree(key: ValueKey(g.name), child: g.build())),
      ]);
    }

    return Column(children: [
      Row(children: [
        Icon(g.icon, color: Pal.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(g.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        TextButton(onPressed: () => onPick(null), child: const Text('Change game')),
      ]),
      const SizedBox(height: 4),
      Expanded(
        child: g.preview != null
            ? g.preview!()
            : Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(g.icon, size: 64, color: Pal.accent),
                  const SizedBox(height: 16),
                  Text(g.instructions,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Tap Start for a one-minute game',
                      style: TextStyle(color: Pal.muted)),
                ]),
              ),
      ),
    ]);
  }
}

class _GamePicker extends StatelessWidget {
  final ValueChanged<MiniGame?> onPick;
  const _GamePicker({required this.onPick});

  @override
  Widget build(BuildContext context) => Column(children: [
        const Text('Choose your game',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
            children: [
              for (var i = 0; i < miniGames.length; i++)
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onPick(miniGames[i]),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Pal.card2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: i == 0 ? Pal.accent : Colors.transparent, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(miniGames[i].icon, size: 28, color: Pal.accent),
                        const SizedBox(height: 6),
                        Text(miniGames[i].name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(miniGames[i].instructions,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Pal.muted)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ]);
}

Widget _scoreText(int s) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('Score: $s',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
    );

Widget _mutedText(String t) =>
    Text(t, textAlign: TextAlign.center, style: const TextStyle(color: Pal.muted));

ButtonStyle get _neutralBtn => ElevatedButton.styleFrom(
      backgroundColor: Pal.card2,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    );

// ======================================================== Research Quiz
// A small Quizlet-style set built from the research behind Mindful Minute
// (same studies as wellness_texts.dart and "The research behind it").
// Please double-check the wording against the papers before publishing.
class _QCard {
  final String term, def;
  const _QCard(this.term, this.def);
}

const _quizCards = [
  _QCard('Doomscrolling',
      'Persistently scrolling negative or distressing content and struggling to stop.'),
  _QCard('Negativity bias',
      'Our brains give extra weight to negative information. Bad-news feeds exploit it.'),
  _QCard('Passive scrolling',
      'Watching others without interacting. Linked with lower well-being than active use.'),
  _QCard('Variable rewards',
      'Unpredictable payoffs, like not knowing when the next great post appears. The most habit-forming kind.'),
  _QCard('Bedtime procrastination',
      'Going to sleep later than planned for no outside reason.'),
  _QCard('If-then plan',
      'Example: "If I feel the urge to scroll, then I will stand up." Makes follow-through more likely.'),
  _QCard('Urge surfing',
      'Urges rise, peak and fade within minutes if you do not act on them.'),
  _QCard('Slow breathing',
      'About six breaths a minute can raise heart-rate variability, a marker of calm.'),
  _QCard('Task-switch cost',
      'After an interruption it can take roughly 23 minutes to fully return to the task.'),
  _QCard('Procrastination',
      'Largely an emotion-regulation problem: we avoid tasks to escape bad feelings.'),
  _QCard('Attrition',
      'About a quarter (24.7%) of participants drop out of mindfulness app trials.'),
  _QCard('30-minute limit',
      'Limiting social media to about 30 minutes a day reduced loneliness and depression.'),
];

/// STUDY phase: no timer. Flip through the flashcards as long as you like.
class _QuizStudy extends StatefulWidget {
  const _QuizStudy();
  @override
  State<_QuizStudy> createState() => _QuizStudyState();
}

class _QuizStudyState extends State<_QuizStudy> {
  late List<_QCard> _deck = List.of(_quizCards);
  int _i = 0;
  bool _back = false;

  void _go(int d) => setState(() {
        _i = (_i + d).clamp(0, _deck.length - 1);
        _back = false;
      });

  @override
  Widget build(BuildContext context) {
    final c = _deck[_i];
    return Column(children: [
      _mutedText('Study and memorize. There is no timer yet. '
          'Your 1-minute quiz starts when you tap Start.'),
      const SizedBox(height: 10),
      Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _back = !_back),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Container(
              key: ValueKey('$_i-$_back'),
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _back ? Pal.accent.withValues(alpha: 0.15) : Pal.card2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Pal.accent.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_back ? 'DEFINITION' : 'TERM',
                        style: const TextStyle(
                            color: Pal.accent,
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    Text(_back ? c.def : c.term,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: _back ? 18 : 28,
                            height: 1.35,
                            fontWeight: _back ? FontWeight.w400 : FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(
            onPressed: _i > 0 ? () => _go(-1) : null,
            icon: const Icon(Icons.arrow_back)),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${_i + 1} / ${_deck.length}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          TextButton.icon(
            onPressed: () => setState(() {
              _deck = List.of(_quizCards)..shuffle();
              _i = 0;
              _back = false;
            }),
            icon: const Icon(Icons.shuffle, size: 16),
            label: const Text('Shuffle'),
          ),
        ]),
        IconButton(
            onPressed: _i < _deck.length - 1 ? () => _go(1) : null,
            icon: const Icon(Icons.arrow_forward)),
      ]),
      const Text('Tap the card to flip it',
          style: TextStyle(color: Pal.muted, fontSize: 12)),
    ]);
  }
}

/// QUIZ phase: runs inside the runner's 60-second timer.
/// Shows a definition, pick the matching term (Quizlet "Learn" style).
class _ResearchQuiz extends StatefulWidget {
  const _ResearchQuiz();
  @override
  State<_ResearchQuiz> createState() => _ResearchQuizState();
}

class _ResearchQuizState extends State<_ResearchQuiz> {
  final _r = Random();
  late final List<_QCard> _order = List.of(_quizCards)..shuffle(_r);
  int _q = 0, _score = 0;
  List<_QCard> _opts = [];
  _QCard? _picked;

  _QCard get _cur => _order[_q % _order.length];

  @override
  void initState() {
    super.initState();
    _newOptions();
  }

  void _newOptions() {
    final cur = _cur;
    final others = List.of(_quizCards)
      ..remove(cur)
      ..shuffle(_r);
    _opts = [cur, ...others.take(3)]..shuffle(_r);
    _picked = null;
  }

  void _answer(_QCard c) {
    if (_picked != null) return;
    final ok = c == _cur;
    setState(() {
      _picked = c;
      if (ok) _score++;
    });
    Future.delayed(Duration(milliseconds: ok ? 600 : 1400), () {
      if (!mounted) return;
      setState(() {
        _q++;
        if (_q % _order.length == 0) _order.shuffle(_r);
        _newOptions();
      });
    });
  }

  Color _bg(_QCard o) {
    if (_picked == null) return Pal.card2;
    if (o == _cur) return Pal.accent;
    if (o == _picked) return Pal.danger;
    return Pal.card2;
  }

  Color _fg(_QCard o) {
    if (_picked != null && o == _cur) return Colors.black;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        _scoreText(_score),
        Expanded(
          child: SingleChildScrollView(
            child: Column(children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Pal.card2, borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  const Text('WHICH TERM MATCHES?',
                      style: TextStyle(
                          color: Pal.accent,
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(_cur.def,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 17, height: 1.35)),
                ]),
              ),
              const SizedBox(height: 12),
              for (final o in _opts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _answer(o),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _bg(o),
                        foregroundColor: _fg(o),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(o.term, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ]);
}

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
