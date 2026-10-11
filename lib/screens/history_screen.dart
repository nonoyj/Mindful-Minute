import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<String> _timestamps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _timestamps = prefs.getStringList('sessionTimestamps') ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final sorted = List<String>.from(_timestamps)
      ..sort((a, b) => b.compareTo(a));

    final Map<String, List<DateTime>> grouped = {};
    for (final ts in sorted) {
      final dt = DateTime.parse(ts);
      final dateKey =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(dateKey, () => []).add(dt);
    }

    final dateKeys = grouped.keys.toList();

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text('Session History'),
        backgroundColor: Colors.teal.shade50,
        foregroundColor: Colors.teal.shade800,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loading = true;
              });
              _load();
            },
          ),
        ],
      ),
      body: dateKeys.isEmpty
          ? Center(
        child: Text(
          'No sessions yet.\nComplete your first Mindful Minute!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.teal.shade600, fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dateKeys.length,
        itemBuilder: (context, index) {
          final dateKey = dateKeys[index];
          final sessions = grouped[dateKey]!;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateKey,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.teal.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${sessions.length} session${sessions.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.teal.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: sessions.map((dt) {
                      final hh = dt.hour.toString().padLeft(2, '0');
                      final mm = dt.minute.toString().padLeft(2, '0');
                      return Chip(
                        label: Text('$hh:$mm'),
                        backgroundColor: Colors.teal.shade50,
                        labelStyle: TextStyle(
                          color: Colors.teal.shade700,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}