import 'package:flutter/material.dart';

import '../services/guard_service.dart';
import '../services/usage_service.dart';
import '../theme.dart';
import 'help_screens.dart';

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
    if (state == AppLifecycleState.resumed) _load(); // back from system settings
  }

  Future<void> _load() async {
    final u = await UsageService.hasUsageAccess();
    final o = await GuardService.hasOverlay();
    final a = await GuardService.hasAccessibility();
    final b = await GuardService.isIgnoringBattery();
    if (mounted) setState(() { _usage = u; _overlay = o; _acc = a; _battery = b; });
  }

  void _hint(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 5)));
  }

  /// A switch you can flip freely. It moves right away, then takes you to the
  /// one place Android allows the change. When you come back, [_load] reads
  /// the real state, so the switch always ends up truthful.
  Widget _perm({
    required String title,
    required String sub,
    required bool on,
    required void Function(bool) set,
    required Future<void> Function() turnOn,
    required Future<void> Function() turnOff,
    String? offHint,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration:
            BoxDecoration(color: Pal.card, borderRadius: BorderRadius.circular(16)),
        child: SwitchListTile(
          value: on,
          onChanged: (want) async {
            setState(() => set(want)); // flips instantly
            if (want) {
              await turnOn();
            } else {
              if (offHint != null) _hint(offHint);
              await turnOff();
            }
            // Fast re-check for permissions that change without leaving the app.
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) _load();
          },
          activeThumbColor: Colors.white,
          activeTrackColor: Pal.accent,
          secondary: Icon(on ? Icons.check_circle : Icons.error_outline,
              color: on ? Pal.accent : Colors.orange.shade400),
          title: Text(title),
          subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        ),
      );

  /// Accessibility can be switched off right here; if Android refuses we open
  /// the system page instead.
  Future<void> _turnOffAccessibility() async {
    final ok = await GuardService.disableAccessibility();
    if (!ok) {
      _hint('Turn off "Mindful Minute lock" on the page that opens.');
      await GuardService.requestAccessibility();
    }
  }

  Widget _link(IconData icon, String title, Widget page) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration:
            BoxDecoration(color: Pal.card, borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: Icon(icon, color: Pal.accent),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => page)),
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
        const Text(
          'Flip a switch to turn a permission on or off. Android only lets '
          'the system settings page make the change for most of them, so it '
          'opens for you. The switch shows the real state when you come back.',
          style: TextStyle(color: Pal.muted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        _perm(
          title: 'Usage access',
          sub: 'Measures time spent in your monitored apps.',
          on: _usage,
          set: (v) => _usage = v,
          turnOn: GuardService.openUsageAccess,
          turnOff: GuardService.openUsageAccess,
          offHint: 'Switch "Mindful Minute" off on the page that opens.',
        ),
        _perm(
          title: 'Display over other apps',
          sub: 'Lets the break reopen on top of any app or the home screen.',
          on: _overlay,
          set: (v) => _overlay = v,
          turnOn: GuardService.requestOverlay,
          turnOff: GuardService.requestOverlay,
          offHint: 'Switch "Allow display over other apps" off on the page that opens.',
        ),
        _perm(
          title: 'Accessibility: "Mindful Minute lock"',
          sub: 'Closes the notification shade, blocks Home / Recents instantly and '
              'keeps the break music volume up.',
          on: _acc,
          set: (v) => _acc = v,
          turnOn: () async {
            _hint('Open "Mindful Minute lock" and switch it on.');
            await GuardService.requestAccessibility();
          },
          turnOff: _turnOffAccessibility,
        ),
        _perm(
          title: 'Unrestricted battery',
          sub: 'Turned on automatically when you switch a '
              'break on. Monitoring stops when every break is off.',
          on: _battery,
          set: (v) => _battery = v,
          turnOn: GuardService.requestIgnoreBattery,
          turnOff: GuardService.openBatterySettings,
          offHint: 'Choose "All apps", pick Mindful Minute, then tap "Optimize".',
        ),
        const SizedBox(height: 20),
        const Text('Help',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _link(Icons.help_outline, 'FAQ', const FaqScreen()),
        _link(Icons.verified_user_outlined, 'Why we need permissions',
            const PermissionsInfoScreen()),
        _link(Icons.science_outlined, 'The research behind it', const ResearchScreen()),
        _link(Icons.feedback_outlined, 'Send feedback', const FeedbackScreen()),
        _link(Icons.info_outline, 'About', const AboutScreen()),
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
