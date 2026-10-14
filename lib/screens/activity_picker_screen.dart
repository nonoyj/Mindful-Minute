import 'package:flutter/material.dart';

import '../models/user_preferences.dart';
import 'activities/activity_meta.dart';
import 'activities/activity_runner.dart';

/// Lists ONLY the activities the user enabled in Preferences.
/// Nothing is recommended or auto-assigned: the user picks.
class ActivityPickerScreen extends StatefulWidget {
  final String? banner;
  const ActivityPickerScreen({super.key, this.banner});

  @override
  State<ActivityPickerScreen> createState() => _ActivityPickerScreenState();
}

class _ActivityPickerScreenState extends State<ActivityPickerScreen> {
  UserPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    UserPreferences.load(reload: true).then((p) {
      if (mounted) setState(() => _prefs = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = WellnessActivityType.values
        .where((t) => _prefs?.enabledActivities.contains(t) ?? false)
        .toList();

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text('Choose an activity'),
        backgroundColor: Colors.teal.shade50,
        foregroundColor: Colors.teal.shade800,
        elevation: 0,
      ),
      body: _prefs == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              if (widget.banner != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(widget.banner!,
                      style: TextStyle(color: Colors.orange.shade900)),
                ),
              if (enabled.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No activities are turned on.\nEnable some in Preferences.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.teal.shade600, fontSize: 16),
                  ),
                ),
              for (final t in enabled)
                Card(
                  color: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(t.icon, color: Colors.teal),
                    title: Text(t.label),
                    subtitle: Text(t.blurb),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => ActivityRunnerScreen(type: t),
                      ),
                    ),
                  ),
                ),
            ]),
    );
  }
}
