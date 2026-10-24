import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';

import '../models/user_preferences.dart';
import '../services/apps_cache.dart';
import '../theme.dart';
import 'activities/activity_meta.dart';
import 'wellness_break_screen.dart';

/// Create / edit one wellness break (like Alarmy's alarm editor).
class EditBreakScreen extends StatefulWidget {
  final MonitoredApp? existing;
  final Set<String> taken; // packages that already have a break
  const EditBreakScreen({super.key, this.existing, this.taken = const {}});

  @override
  State<EditBreakScreen> createState() => _EditBreakScreenState();
}

class _EditBreakScreenState extends State<EditBreakScreen> {
  String? _pkg;
  String? _name;
  int _limit = 60;
  late List<WellnessActivityType> _acts;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _pkg = e?.packageName;
    _name = e?.displayName;
    _limit = e?.dailyLimitMinutes ?? 60;
    _acts = List.of(e?.activities ?? [WellnessActivityType.breathing]);
    AppsCache.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  MonitoredApp _build() => MonitoredApp(
        packageName: _pkg ?? 'preview',
        displayName: _name ?? 'this app',
        dailyLimitMinutes: _limit,
        activities: _acts,
        enabled: widget.existing?.enabled ?? true,
      );

  Future<void> _pickApp() async {
    await AppsCache.load();
    if (!mounted) return;
    final r = await showModalBottomSheet<AppInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Pal.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AppPicker(taken: widget.taken),
    );
    if (r != null) {
      setState(() {
        _pkg = r.packageName;
        _name = r.name;
      });
    }
  }

  void _toggle(WellnessActivityType t) {
    setState(() {
      if (_acts.contains(t)) {
        if (_acts.length > 1) _acts.remove(t); // keep at least one
      } else {
        _acts.add(t);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _pkg != null && _acts.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New wellness break' : 'Edit wellness break'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => WellnessBreakScreen(app: _build(), locked: false),
            )),
            child: const Text('Preview'),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _box(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _pkg == null
                ? const Icon(Icons.add_circle_outline, color: Pal.accent, size: 40)
                : AppIconView(packageName: _pkg!),
            title: Text(_name ?? 'Choose an app to monitor',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            subtitle: _pkg == null ? null : Text(_pkg!, style: const TextStyle(fontSize: 11)),
            trailing: widget.existing == null ? const Icon(Icons.chevron_right) : null,
            onTap: widget.existing == null ? _pickApp : null,
          ),
        ),
        _box(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Daily limit', style: TextStyle(color: Pal.muted)),
            const SizedBox(height: 4),
            Text.rich(TextSpan(children: [
              TextSpan(
                  text: '$_limit',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700)),
              const TextSpan(
                  text: '  min / day',
                  style: TextStyle(fontSize: 18, color: Pal.muted)),
            ])),
            Slider(
              value: _limit.toDouble(),
              min: 5,
              max: 240,
              divisions: 47,
              label: '$_limit min',
              activeColor: Pal.accent,
              onChanged: (v) => setState(() => _limit = v.round()),
            ),
            const Text(
              'Warnings at 70%, 80% and 90%. At 100% the phone locks into your break.',
              style: TextStyle(color: Pal.muted, fontSize: 12),
            ),
          ]),
        ),
        _box(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('Activities',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${_acts.length}/${WellnessActivityType.values.length}',
                  style: const TextStyle(color: Pal.muted)),
            ]),
            const SizedBox(height: 4),
            const Text('Completed in the order you tap them.',
                style: TextStyle(color: Pal.muted, fontSize: 12)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in WellnessActivityType.values)
                FilterChip(
                  avatar: Icon(t.icon, size: 18),
                  label: Text(_acts.contains(t)
                      ? '${_acts.indexOf(t) + 1} · ${t.label}'
                      : t.label),
                  selected: _acts.contains(t),
                  selectedColor: Pal.accent.withValues(alpha: 0.35),
                  onSelected: (_) => _toggle(t),
                ),
            ]),
          ]),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: canSave ? () => Navigator.of(context).pop(_build()) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Pal.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            child: const Text('Save'),
          ),
        ),
      ),
    );
  }

  Widget _box({required Widget child}) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Pal.card, borderRadius: BorderRadius.circular(20)),
        child: child,
      );
}

class _AppPicker extends StatefulWidget {
  final Set<String> taken;
  const _AppPicker({required this.taken});
  @override
  State<_AppPicker> createState() => _AppPickerState();
}

class _AppPickerState extends State<_AppPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final list = AppsCache.apps
        .where((a) =>
            !widget.taken.contains(a.packageName) &&
            a.name.toLowerCase().contains(_q.toLowerCase()))
        .toList();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(children: [
          const Text('Select an app',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search installed apps...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => setState(() => _q = v),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No apps found.'))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) => ListTile(
                      leading: AppIconView(packageName: list[i].packageName, size: 36),
                      title: Text(list[i].name),
                      subtitle: Text(list[i].packageName,
                          style: const TextStyle(fontSize: 11)),
                      onTap: () => Navigator.of(context).pop(list[i]),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}
