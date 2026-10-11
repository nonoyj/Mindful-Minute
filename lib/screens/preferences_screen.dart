import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

import '../models/user_preferences.dart';
import '../services/usage_service.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  UserPreferences? _prefs;
  List<AppInfo> _installedApps = [];
  bool _loadingApps = true;
  bool _hasUsageAccess = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await UserPreferences.load();
    final hasAccess = await UsageService.hasUsageAccess();
    List<AppInfo> apps = [];
    try {
      // excludeSystemApps: false -> OEM skins (e.g. Infinix XOS) sometimes
      // flag normal user apps (YouTube, Facebook, etc.) as "system" apps.
      // Keeping this false ensures we don't silently filter them out.
      // withIcon: true -> lets us actually render app icons in the list.
      apps = await InstalledApps.getInstalledApps(false, true, '');
      apps.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    } catch (e) {
      apps = [];
    }
    setState(() {
      _prefs = prefs;
      _installedApps = apps;
      _hasUsageAccess = hasAccess;
      _loadingApps = false;
    });
  }

  Future<void> _requestUsageAccess() async {
    await UsageService.openUsageAccessSettings();
    final hasAccess = await UsageService.hasUsageAccess();
    setState(() {
      _hasUsageAccess = hasAccess;
    });
  }

  Future<void> _save() async {
    if (_prefs != null) {
      await _prefs!.save();
    }
  }

  void _showAddAppSheet() {
    final filtered = _installedApps.where((app) {
      final alreadyAdded = _prefs!.monitoredApps
          .any((m) => m.packageName == app.packageName);
      final matchesSearch =
      app.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return !alreadyAdded && matchesSearch;
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select an app to monitor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search installed apps...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setSheetState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _installedApps.isEmpty
                            ? const Center(
                          child: Text(
                            'No installed apps found.\nThis can happen on '
                                'an emulator with limited apps installed.',
                            textAlign: TextAlign.center,
                          ),
                        )
                            : ListView.builder(
                          controller: scrollController,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final app = filtered[index];
                            return ListTile(
                              leading: app.icon != null
                                  ? Image.memory(
                                app.icon!,
                                width: 36,
                                height: 36,
                              )
                                  : const Icon(Icons.apps),
                              title: Text(app.name),
                              subtitle: Text(
                                app.packageName,
                                style: const TextStyle(fontSize: 11),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _showLimitDialog(
                                  packageName: app.packageName,
                                  displayName: app.name,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showLimitDialog({
    required String packageName,
    required String displayName,
    MonitoredApp? existing,
  }) {
    int limitMinutes = existing?.dailyLimitMinutes ?? 60;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Set limit for $displayName'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$limitMinutes minutes per day',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: limitMinutes.toDouble(),
                    min: 5,
                    max: 240,
                    divisions: 47,
                    label: '$limitMinutes min',
                    activeColor: Colors.teal,
                    onChanged: (value) {
                      setDialogState(() {
                        limitMinutes = value.round();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _prefs!.addOrUpdateApp(
                        MonitoredApp(
                          packageName: packageName,
                          displayName: displayName,
                          dailyLimitMinutes: limitMinutes,
                        ),
                      );
                    });
                    await _save();
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeApp(String packageName) async {
    setState(() {
      _prefs!.removeApp(packageName);
    });
    await _save();
  }

  void _toggleActivity(WellnessActivityType type, bool enabled) async {
    setState(() {
      if (enabled) {
        _prefs!.enabledActivities.add(type);
      } else {
        _prefs!.enabledActivities.remove(type);
      }
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingApps || _prefs == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text('Preferences'),
        backgroundColor: Colors.teal.shade50,
        foregroundColor: Colors.teal.shade800,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_hasUsageAccess)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade800),
                      const SizedBox(width: 8),
                      Text(
                        'Usage Access Needed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mindful Minute needs permission to see app usage in '
                        'order to track your monitored apps. Tap below to grant '
                        'it in system settings, then come back here.',
                    style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _requestUsageAccess,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Grant Usage Access'),
                  ),
                ],
              ),
            ),
          Text(
            'Monitored Apps',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick apps you want Mindful Minute to watch, and set a daily '
                'time limit before a wellness break is triggered.',
            style: TextStyle(fontSize: 13, color: Colors.teal.shade600),
          ),
          const SizedBox(height: 12),
          if (_prefs!.monitoredApps.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'No apps added yet.',
                style: TextStyle(color: Colors.teal.shade600),
              ),
            )
          else
            ..._prefs!.monitoredApps.map((app) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(app.displayName),
                  subtitle: Text('${app.dailyLimitMinutes} min / day'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () {
                          _showLimitDialog(
                            packageName: app.packageName,
                            displayName: app.displayName,
                            existing: app,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _removeApp(app.packageName),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _showAddAppSheet,
              icon: const Icon(Icons.add),
              label: const Text('Add App to Monitor'),
              style: TextButton.styleFrom(foregroundColor: Colors.teal),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Wellness Break Activities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose what appears during a wellness break.',
            style: TextStyle(fontSize: 13, color: Colors.teal.shade600),
          ),
          const SizedBox(height: 12),
          ...WellnessActivityType.values.map((type) {
            final enabled = _prefs!.enabledActivities.contains(type);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: Text(type.label),
                value: enabled,
                activeThumbColor: Colors.teal,
                onChanged: (value) => _toggleActivity(type, value),
              ),
            );
          }),
        ],
      ),
    );
  }
}