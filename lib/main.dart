import 'package:flutter/material.dart';

import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/preferences_screen.dart';
import 'services/background_service.dart';
import 'services/break_launcher.dart';
import 'services/notification_service.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const RootNavigation(),
    );
  }
}

class RootNavigation extends StatefulWidget {
  const RootNavigation({super.key});

  @override
  State<RootNavigation> createState() => _RootNavigationState();
}

class _RootNavigationState extends State<RootNavigation> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    HistoryScreen(),
    PreferencesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // If the 100% alert launched the app from a closed state, start the break.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final payload = await NotificationService.launchPayload();
      BreakLauncher.handlePayload(payload);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.self_improvement), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Progress'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Preferences'),
        ],
      ),
    );
  }
}
