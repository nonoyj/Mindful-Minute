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

  /// A switch that shows the REAL permission state. Android never lets an app
  /// grant or revoke these itself, so flipping it opens the system page where
  /// you turn it on OR off; the switch updates when you come back.
  Widget _perm(String title, String sub, bool on, VoidCallback openSystemPage) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration:
            BoxDecoration(color: Pal.card, borderRadius: BorderRadius.circular(16)),
        child: SwitchListTile(
          value: on,
          onChanged: (_) => openSystemPage(),
          activeThumbColor: Colors.white,
          activeTrackColor: Pal.accent,
          secondary: Icon(on ? Icons.check_circle : Icons.error_outline,
              color: on ? Pal.accent : Colors.orange.shade400),
          title: Text(title),
          subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        ),
      );


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
          'Tap a switch to open the system page where you can turn the '
          'permission on or off. The switch updates when you come back.',
          style: TextStyle(color: Pal.muted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        _perm('Usage access', 'Measures time spent in your monitored apps.',
            _usage, UsageService.openUsageAccessSettings),
        _perm('Display over other apps',
            'Lets the break reopen on top of any app or the home screen.',
            _overlay, GuardService.requestOverlay),
        _perm('Accessibility: "Mindful Minute lock"',
            'Closes the notification shade, blocks Home / Recents instantly and '
            'keeps the break music volume up.',
            _acc, GuardService.requestAccessibility),
        _perm('Unrestricted battery',
            'Turned on automatically when you switch a '
            'break on. Monitoring stops when every break is off.',
            _battery,
            _battery ? GuardService.openBatterySettings : GuardService.requestIgnoreBattery),
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
