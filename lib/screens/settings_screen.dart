import 'package:flutter/material.dart';

import '../services/guard_service.dart';
import '../services/usage_service.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  bool _usage = false, _overlay = false, _acc = false, _battery = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final u = await UsageService.hasUsageAccess();
    final o = await GuardService.hasOverlay();
    final a = await GuardService.hasAccessibility();
    final b = await GuardService.isIgnoringBattery();
    if (mounted) setState(() { _usage = u; _overlay = o; _acc = a; _battery = b; });
  }

  Widget _tile(String title, String sub, bool ok, VoidCallback onTap) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration:
            BoxDecoration(color: Pal.card, borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: Icon(ok ? Icons.check_circle : Icons.error_outline,
              color: ok ? Pal.accent : Colors.orange.shade400),
          title: Text(title),
          subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
          trailing: ok ? null : const Icon(Icons.chevron_right),
          onTap: ok ? null : onTap,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Permissions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text('All four are needed for the break to be a total lock.',
            style: TextStyle(color: Pal.muted, fontSize: 13)),
        const SizedBox(height: 12),
        _tile('Usage access', 'Measures time spent in your monitored apps.',
            _usage, UsageService.openUsageAccessSettings),
        _tile('Display over other apps',
            'Lets the break reopen on top of any app or the home screen.',
            _overlay, GuardService.requestOverlay),
        _tile('Accessibility: "Mindful Minute lock"',
            'Closes the notification shade, blocks Home / Recents instantly and '
            'keeps the break music volume up. Open it, pick Mindful Minute lock, '
            'turn it on.',
            _acc, GuardService.requestAccessibility),
        _tile('Unrestricted battery',
            'Stops Android from killing the background monitor.',
            _battery, GuardService.requestIgnoreBattery),
        const SizedBox(height: 20),
        const Text('How the lock works',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text(
          'When an app reaches 100% of its limit, calming music starts and '
          'Mindful Minute takes over the screen. Home, Recents, the status bar '
          'and the power button all lead straight back to it. The only way out '
          'is to finish every activity you chose. Then the music stops, the '
          "app's limit resets and you are free.\n\n"
          'Safety: calls still come through, and the lock releases by itself '
          'after 10 minutes so you can never be stuck out of your phone.',
          style: TextStyle(color: Pal.muted, height: 1.4),
        ),
      ]),
    );
  }
}
