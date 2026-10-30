import 'dart:async';
import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'services/background_service.dart';
import 'services/break_launcher.dart';
import 'services/notification_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init(onTap: BreakLauncher.handlePayload);
  await initBackgroundService();
  runApp(const MindfulMinuteApp());
}

class MindfulMinuteApp extends StatelessWidget {
  const MindfulMinuteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mindful Minute',
      navigatorKey: appNavigatorKey,
      theme: buildDarkTheme(),
      home: const RootNavigation(),
    );
  }
}

class RootNavigation extends StatefulWidget {
  const RootNavigation({super.key});
  @override
  State<RootNavigation> createState() => _RootNavigationState();
}

class _RootNavigationState extends State<RootNavigation> with WidgetsBindingObserver {
  int _index = 0;
  Timer? _guardTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _guardTimer = Timer.periodic(
        const Duration(seconds: 2), (_) => BreakLauncher.checkGuard());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Launched by a notification tap?
      BreakLauncher.handlePayload(await NotificationService.launchPayload());
      // Launched by the native lock (break in progress)?
      BreakLauncher.checkGuard();
    });
  }

  @override
  void dispose() {
    _guardTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The native guard brings us to the front: re-open the break if needed.
    if (state == AppLifecycleState.resumed) BreakLauncher.checkGuard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: [
        DashboardScreen(onOpenSettings: () => setState(() => _index = 2)),
        const HistoryScreen(),
        const SettingsScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.self_improvement), label: 'Breaks'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Progress'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
