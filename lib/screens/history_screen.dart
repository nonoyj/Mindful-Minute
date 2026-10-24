import 'package:flutter/material.dart';

import '../services/session_service.dart';
import '../theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  SessionStats? _stats;

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

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final sorted = List<String>.from(stats?.timestamps ?? [])
      ..sort((a, b) => b.compareTo(a));
    final Map<String, List<DateTime>> grouped = {};
    for (final ts in sorted) {
      final d = DateTime.parse(ts);
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(d);
    }
    final keys = grouped.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          _stat('Sessions', '${stats?.total ?? 0}'),
          const SizedBox(width: 12),
          _stat('Streak', '${stats?.streak ?? 0} 🔥'),
        ]),
        const SizedBox(height: 20),
        if (keys.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Text('No sessions yet.\nComplete your first Mindful Minute!',
                textAlign: TextAlign.center, style: TextStyle(color: Pal.muted)),
          ),
        for (final k in keys)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration:
                BoxDecoration(color: Pal.card, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(k, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                  '${grouped[k]!.length} session${grouped[k]!.length > 1 ? 's' : ''}',
                  style: const TextStyle(color: Pal.accent, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final d in grouped[k]!)
                  Chip(
                    label: Text(
                        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 12)),
                    backgroundColor: Pal.card2,
                    side: BorderSide.none,
                  ),
              ]),
            ]),
          ),
      ]),
    );
  }

  Widget _stat(String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration:
              BoxDecoration(color: Pal.card, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Pal.muted, fontSize: 12)),
          ]),
        ),
      );
}
