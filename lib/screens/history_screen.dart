import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../services/session_service.dart';
import '../theme.dart';

/// Progress tab: a calm, minimal summary of your completed breaks.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  SessionStats? _stats;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _load();
    SessionService.changes.addListener(_load);
  }

  @override
  void dispose() {
    SessionService.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final s = await SessionService.load();
    if (mounted) setState(() => _stats = s);
  }

  // ------------------------------------------------------------------ build
  @override
  Widget build(BuildContext context) {
    final d = _Data.from(_stats);
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _hero(d),
          const SizedBox(height: 12),
          Row(children: [
            _tile(Icons.self_improvement, '${d.total}', 'Sessions'),
            const SizedBox(width: 10),
            _tile(Icons.emoji_events_outlined, '${d.best}', 'Best streak'),
            const SizedBox(width: 10),
            _tile(Icons.today_outlined, '${d.today}', 'Today'),
          ]),
          const SizedBox(height: 12),
          if (d.perDay.isEmpty)
            _empty()
          else ...[
            _week(d),
            _heat(d),
            _insights(d),
          ],
          _milestones(d),
          if (d.perDay.isNotEmpty) _history(d),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------- bits
  static const _label = TextStyle(
      fontSize: 12, letterSpacing: 1.1, fontWeight: FontWeight.w600, color: Pal.muted);

  Widget _section(String title, Widget child, {String? trailing}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration:
            BoxDecoration(color: Pal.card, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title.toUpperCase(), style: _label)),
            if (trailing != null)
              Text(trailing, style: const TextStyle(fontSize: 12, color: Pal.accent)),
          ]),
          const SizedBox(height: 14),
          child,
        ]),
      );

  Widget _tile(IconData icon, String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration:
              BoxDecoration(color: Pal.card, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 18, color: Pal.accent),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            Text(label, style: const TextStyle(fontSize: 12, color: Pal.muted)),
          ]),
        ),
      );

  // ------------------------------------------------------------------- hero
  Widget _hero(_Data d) {
    final msg = d.streak == 0
        ? 'Complete a break to start your streak.'
        : d.today > 0
            ? 'Today is done. Your streak is safe.'
            : 'Finish a break today to keep your streak alive.';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Pal.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Pal.accent.withValues(alpha: 0.18)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('CURRENT STREAK', style: _label),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${d.streak}',
                  style: const TextStyle(
                      fontSize: 56, fontWeight: FontWeight.w700, height: 1)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(d.streak == 1 ? 'day 🔥' : 'days 🔥',
                    style: const TextStyle(fontSize: 16, color: Pal.muted)),
              ),
            ]),
            const SizedBox(height: 10),
            Text(msg,
                style: const TextStyle(fontSize: 13, color: Pal.muted, height: 1.35)),
          ]),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 92,
          height: 92,
          child: Stack(alignment: Alignment.center, children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: d.activeThisWeek / 7),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) =>
                  CustomPaint(size: const Size(92, 92), painter: _RingPainter(v)),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${d.activeThisWeek}/7',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const Text('this week', style: TextStyle(fontSize: 10, color: Pal.muted)),
            ]),
          ]),
        ),
      ]),
    );
  }

  // ------------------------------------------------------------- last 7 days
  Widget _week(_Data d) {
    final now = _day(DateTime.now());
    final days = [for (var i = 6; i >= 0; i--) DateTime(now.year, now.month, now.day - i)];
    final maxV = days.fold<int>(1, (m, x) => math.max(m, d.perDay[x] ?? 0));
    return _section(
      'Last 7 days',
      SizedBox(
        height: 128,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (final day in days)
            Expanded(child: _bar(day, d.perDay[day] ?? 0, maxV, day == now)),
        ]),
      ),
      trailing: '${d.week} ${d.week == 1 ? 'session' : 'sessions'}',
    );
  }

  Widget _bar(DateTime day, int v, int maxV, bool isToday) {
    final target = v == 0 ? 4.0 : 10.0 + 62.0 * (v / maxV);
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      SizedBox(
        height: 16,
        child: v > 0
            ? Text('$v', style: const TextStyle(fontSize: 11, color: Pal.muted))
            : null,
      ),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: target),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (_, h, __) => Container(
          width: 20,
          height: h,
          decoration: BoxDecoration(
            color: v == 0
                ? Pal.card2
                : isToday
                    ? Pal.accent
                    : Pal.accent.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(_wd1[day.weekday - 1],
          style: TextStyle(
              fontSize: 12,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
              color: isToday ? Pal.accent : Pal.muted)),
    ]);
  }

  // ----------------------------------------------------------- 5-week heatmap
  Widget _heat(_Data d) {
    final now = _day(DateTime.now());
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final start = DateTime(monday.year, monday.month, monday.day - 28);

    Color shade(int n) {
      if (n <= 0) return Pal.card2;
      if (n == 1) return Pal.accent.withValues(alpha: 0.35);
      if (n == 2) return Pal.accent.withValues(alpha: 0.65);
      return Pal.accent;
    }

    Widget legend(Color c) => Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
        );

    return _section(
      'Consistency',
      Column(children: [
        Row(children: [
          for (final l in _wd1)
            Expanded(
              child: Center(
                  child: Text(l,
                      style: const TextStyle(fontSize: 11, color: Pal.muted))),
            ),
        ]),
        for (var w = 0; w < 5; w++)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              for (var dow = 0; dow < 7; dow++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Builder(builder: (_) {
                      final date =
                          DateTime(start.year, start.month, start.day + w * 7 + dow);
                      final future = date.isAfter(now);
                      return AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: future ? Colors.transparent : shade(d.perDay[date] ?? 0),
                            borderRadius: BorderRadius.circular(7),
                            border: date == now
                                ? Border.all(color: Pal.accent, width: 1.5)
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
            ]),
          ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          const Text('Less', style: TextStyle(fontSize: 11, color: Pal.muted)),
          const SizedBox(width: 4),
          legend(shade(0)),
          legend(shade(1)),
          legend(shade(2)),
          legend(shade(3)),
          const SizedBox(width: 4),
          const Text('More', style: TextStyle(fontSize: 11, color: Pal.muted)),
        ]),
      ]),
      trailing: '${d.perDay.length} active ${d.perDay.length == 1 ? 'day' : 'days'}',
    );
  }

  // ---------------------------------------------------------------- insights
  Widget _insights(_Data d) {
    Widget row(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Pal.card2, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: Pal.accent),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(color: Pal.muted))),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
        );
    return _section(
      'Insights',
      Column(children: [
        row(Icons.schedule, 'Most active time', d.peak ?? '-'),
        row(Icons.show_chart, 'Average per active day', d.avg.toStringAsFixed(1)),
        row(Icons.calendar_today_outlined, 'Active days', '${d.perDay.length}'),
        row(Icons.flag_outlined, 'Started', d.first == null ? '-' : _fmtDate(d.first!)),
      ]),
    );
  }

  // -------------------------------------------------------------- milestones
  Widget _milestones(_Data d) {
    final items = <(IconData, String, bool)>[
      (Icons.spa_outlined, 'First break', d.total >= 1),
      (Icons.filter_5_outlined, '10 sessions', d.total >= 10),
      (Icons.workspace_premium_outlined, '25 sessions', d.total >= 25),
      (Icons.military_tech_outlined, '50 sessions', d.total >= 50),
      (Icons.diamond_outlined, '100 sessions', d.total >= 100),
      (Icons.local_fire_department_outlined, '3-day streak', d.best >= 3),
      (Icons.local_fire_department, '7-day streak', d.best >= 7),
      (Icons.whatshot, '30-day streak', d.best >= 30),
    ];
    final got = items.where((e) => e.$3).length;
    return _section(
      'Milestones',
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (icon, label, on) in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: on ? Pal.accent.withValues(alpha: 0.12) : Pal.card2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: on ? Pal.accent.withValues(alpha: 0.5) : Colors.transparent),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(on ? icon : Icons.lock_outline,
                  size: 16, color: on ? Pal.accent : Pal.muted),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: on ? Colors.white : Pal.muted,
                      fontWeight: on ? FontWeight.w600 : FontWeight.w400)),
            ]),
          ),
      ]),
      trailing: '$got of ${items.length}',
    );
  }

  // ----------------------------------------------------------------- history
  Widget _history(_Data d) {
    final keys = d.byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final shown = _showAll ? keys : keys.take(7).toList();
    final now = _day(DateTime.now());
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    String title(DateTime k) => k == now
        ? 'Today'
        : k == yesterday
            ? 'Yesterday'
            : '${_wd3[k.weekday - 1]}, ${_fmtDate(k)}';

    return _section(
      'History',
      Column(children: [
        for (final k in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(title(k),
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                Text(
                    '${d.byDay[k]!.length} session${d.byDay[k]!.length > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 12, color: Pal.accent)),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final t in d.byDay[k]!)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: Pal.card2, borderRadius: BorderRadius.circular(10)),
                    child: Text(_fmtTime(t),
                        style: const TextStyle(fontSize: 12, color: Pal.muted)),
                  ),
              ]),
            ]),
          ),
        if (keys.length > 7)
          TextButton(
            onPressed: () => setState(() => _showAll = !_showAll),
            child: Text(_showAll ? 'Show less' : 'Show all ${keys.length} days'),
          ),
      ]),
    );
  }

  Widget _empty() => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration:
            BoxDecoration(color: Pal.card, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          Icon(Icons.self_improvement,
              size: 48, color: Pal.accent.withValues(alpha: 0.8)),
          const SizedBox(height: 12),
          const Text('No sessions yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text(
            'Complete your first Mindful Minute and your streak, weekly '
            'chart and history will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Pal.muted, height: 1.4),
          ),
        ]),
      );
}

// ================================================================== helpers
const _wd1 = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const _wd3 = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);
String _fmtDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';
String _fmtTime(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Everything the screen shows, worked out once from the saved timestamps.
class _Data {
  final int total; // saved total
  final int streak; // current streak (from SessionService)
  final Map<DateTime, int> perDay;
  final Map<DateTime, List<DateTime>> byDay; // day -> times (newest first)
  final int best;
  final int today;
  final int week; // sessions in the last 7 days
  final int activeThisWeek; // days with a session in the last 7 days
  final String? peak;
  final double avg;
  final DateTime? first;

  _Data._(this.total, this.streak, this.perDay, this.byDay, this.best, this.today,
      this.week, this.activeThisWeek, this.peak, this.avg, this.first);

  factory _Data.from(SessionStats? s) {
    final stamps = <DateTime>[];
    for (final t in s?.timestamps ?? const <String>[]) {
      final p = DateTime.tryParse(t);
      if (p != null) stamps.add(p);
    }
    stamps.sort((a, b) => b.compareTo(a));

    final perDay = <DateTime, int>{};
    final byDay = <DateTime, List<DateTime>>{};
    final buckets = <String, int>{};
    for (final t in stamps) {
      final k = _day(t);
      perDay[k] = (perDay[k] ?? 0) + 1;
      byDay.putIfAbsent(k, () => []).add(t);
      final h = t.hour;
      final b = h >= 5 && h < 12
          ? 'Morning'
          : h >= 12 && h < 17
              ? 'Afternoon'
              : h >= 17 && h < 21
                  ? 'Evening'
                  : 'Night';
      buckets[b] = (buckets[b] ?? 0) + 1;
    }

    // best streak = longest run of consecutive days with a session
    final days = perDay.keys.toList()..sort();
    var best = 0, run = 0;
    DateTime? prev;
    for (final d in days) {
      if (prev != null && d == DateTime(prev.year, prev.month, prev.day + 1)) {
        run++;
      } else {
        run = 1;
      }
      if (run > best) best = run;
      prev = d;
    }

    final now = _day(DateTime.now());
    var week = 0, active = 0;
    for (var i = 0; i < 7; i++) {
      final c = perDay[DateTime(now.year, now.month, now.day - i)] ?? 0;
      week += c;
      if (c > 0) active++;
    }

    String? peak;
    if (buckets.isNotEmpty) {
      final top = buckets.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      peak = const {
        'Morning': 'Morning (5 AM-12 PM)',
        'Afternoon': 'Afternoon (12-5 PM)',
        'Evening': 'Evening (5-9 PM)',
        'Night': 'Night (9 PM-5 AM)',
      }[top];
    }

    final streak = s?.streak ?? 0;
    return _Data._(
      s?.total ?? 0,
      streak,
      perDay,
      byDay,
      math.max(best, streak),
      perDay[now] ?? 0,
      week,
      active,
      peak,
      perDay.isEmpty ? 0 : stamps.length / perDay.length,
      days.isEmpty ? null : days.first,
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = Pal.card2;
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = Pal.accent;
    canvas.drawArc(rect, 0, math.pi * 2, false, bg);
    if (progress > 0) {
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, fg);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
