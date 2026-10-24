import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../models/user_preferences.dart';
import '../services/apps_cache.dart';
import '../services/break_launcher.dart';
import '../services/guard_service.dart';
import '../services/monitoring_service.dart';
import '../services/session_service.dart';
import '../services/usage_service.dart';
import '../theme.dart';
import 'activities/activity_meta.dart';
import 'edit_break_screen.dart';

/// Main dashboard (Alarmy-style): one card per monitored app = one wellness break.
class DashboardScreen extends StatefulWidget {
  final VoidCallback onOpenSettings;
  const DashboardScreen({super.key, required this.onOpenSettings});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserPreferences? _prefs;
  Map<String, int> _usage = {};
  int _missing = 0;
  int _total = 0;
  int _streak = 0;
  Timer? _timer;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    AppsCache.load().then((_) {
      if (mounted) setState(() {});
    });
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _refresh());
    SessionService.changes.addListener(_refresh);
    _sub = FlutterBackgroundService().on('warning').listen((data) {
      if (data == null) return;
      final tier = data['tier'] as String;
      if (tier == WarningTier.limitReached.name) {
        BreakLauncher.openBreakFor(data['package'] as String);
      } else {
        _snack(data['message'] as String, tier);
      }
      _refresh();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    SessionService.changes.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _refresh() async {
    final prefs = await UserPreferences.load(reload: true);
    final access = await UsageService.hasUsageAccess();
    final overlay = await GuardService.hasOverlay();
    final acc = await GuardService.hasAccessibility();
    final usage = access && prefs.monitoredApps.isNotEmpty
        ? await UsageService.getTodayUsageForApps(
            prefs.monitoredApps.map((a) => a.packageName).toList())
        : <String, int>{};
    final stats = await SessionService.load();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _usage = usage;
      _missing = (access ? 0 : 1) + (overlay ? 0 : 1) + (acc ? 0 : 1);
      _total = stats.total;
      _streak = stats.streak;
    });
  }

  void _snack(String message, String tier) {
    if (!mounted) return;
    final color = {
          'seventy': Colors.amber.shade800,
          'eighty': Colors.orange.shade800,
          'ninety': Colors.deepOrange.shade800,
        }[tier] ??
        Pal.card2;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 5),
    ));
  }

  Future<void> _edit(MonitoredApp? existing) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final taken = prefs.monitoredApps.map((a) => a.packageName).toSet();
    final r = await Navigator.of(context).push<MonitoredApp>(MaterialPageRoute(
      builder: (_) => EditBreakScreen(existing: existing, taken: taken),
    ));
    if (r != null) {
      prefs.addOrUpdateApp(r);
      await prefs.save();
      _refresh();
    }
  }

  Future<void> _update(MonitoredApp a) async {
    _prefs!.addOrUpdateApp(a);
    await _prefs!.save();
    _refresh();
  }

  Future<void> _delete(MonitoredApp a) async {
    _prefs!.removeApp(a.packageName);
    await _prefs!.save();
    // Deleting a break also resets that app's usage tracking.
    await UsageService.resetApp(a.packageName);
    _refresh();
  }

  String _headline() {
    final apps = (_prefs?.monitoredApps ?? []).where((a) => a.enabled).toList();
    if (apps.isEmpty) return 'No wellness breaks yet';
    MonitoredApp? best;
    var bestLeft = 1 << 30;
    for (final a in apps) {
      final left = a.dailyLimitMinutes - (_usage[a.packageName] ?? 0);
      if (left < bestLeft) {
        bestLeft = left;
        best = a;
      }
    }
    if (bestLeft <= 0) return '${best!.displayName}: limit reached';
    return '${best!.displayName}: $bestLeft min left';
  }

  Color _barColor(double f) {
    if (f >= 1) return Colors.red.shade400;
    if (f >= 0.9) return Colors.deepOrange.shade400;
    if (f >= 0.8) return Colors.orange.shade400;
    if (f >= 0.7) return Colors.amber.shade400;
    return Pal.accent;
  }

  @override
  Widget build(BuildContext context) {
    final apps = _prefs?.monitoredApps ?? [];
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(null),
        backgroundColor: Pal.accent,
        foregroundColor: Colors.black,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.black, borderRadius: BorderRadius.circular(20)),
                child: const Text('Next break', style: TextStyle(fontSize: 13)),
              ),
            ]),
            const SizedBox(height: 16),
            Text(_headline(),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('$_total sessions  ·  $_streak day streak 🔥',
                style: const TextStyle(color: Pal.muted)),
            const SizedBox(height: 16),
            if (_missing > 0)
              InkWell(
                onTap: widget.onOpenSettings,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade700),
                  ),
                  child: Row(children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade400),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          'Finish setup ($_missing): allow permissions so breaks can '
                          'track usage and lock the screen.',
                          style: const TextStyle(fontSize: 13)),
                    ),
                    const Icon(Icons.chevron_right),
                  ]),
                ),
              ),
            if (_prefs != null && apps.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Pal.card, borderRadius: BorderRadius.circular(20)),
                child: const Text(
                  'Tap + to choose an app (like Instagram or TikTok), set its daily '
                  'limit and pick the wellness activities you want to do when you '
                  'reach it.',
                  style: TextStyle(color: Pal.muted, height: 1.4),
                ),
              ),
            for (final a in apps) _card(a),
          ],
        ),
      ),
    );
  }

  Widget _card(MonitoredApp a) {
    final used = _usage[a.packageName] ?? 0;
    final f = a.dailyLimitMinutes <= 0 ? 0.0 : used / a.dailyLimitMinutes;
    final dim = a.enabled ? 1.0 : 0.5;
    return Opacity(
      opacity: dim,
      child: InkWell(
        onTap: () => _edit(a),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration:
              BoxDecoration(color: Pal.card, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              AppIconView(packageName: a.packageName, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Every day',
                      style: TextStyle(
                          fontSize: 12, color: a.enabled ? Pal.accent : Pal.muted)),
                  Text.rich(TextSpan(children: [
                    TextSpan(
                        text: '${a.dailyLimitMinutes}',
                        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700)),
                    const TextSpan(
                        text: ' min',
                        style: TextStyle(fontSize: 16, color: Pal.muted)),
                  ])),
                  Text(a.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Pal.muted)),
                ]),
              ),
              Switch(
                value: a.enabled,
                activeThumbColor: Colors.white,
                activeTrackColor: Pal.accent,
                onChanged: (v) => _update(a.copyWith(enabled: v)),
              ),
              PopupMenuButton<String>(
                onSelected: (v) => v == 'edit' ? _edit(a) : _delete(a),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ]),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: math.min(1.0, f),
              minHeight: 6,
              backgroundColor: Pal.card2,
              color: _barColor(f),
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 6),
            Text('$used / ${a.dailyLimitMinutes} min today',
                style: const TextStyle(fontSize: 12, color: Pal.muted)),
            const SizedBox(height: 10),
            Row(children: [
              const Text('Break', style: TextStyle(color: Pal.muted)),
              const SizedBox(width: 10),
              for (final t in a.activities)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Tooltip(
                      message: t.label, child: Icon(t.icon, size: 18, color: Pal.muted)),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}
