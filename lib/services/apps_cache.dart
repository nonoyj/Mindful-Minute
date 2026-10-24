import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

import '../theme.dart';

/// Loads the installed-apps list (with icons) once and shares it.
class AppsCache {
  static List<AppInfo> apps = [];
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    try {
      // excludeSystemApps:false -> OEM skins flag normal apps as "system".
      apps = await InstalledApps.getInstalledApps(false, true, '');
      apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } catch (_) {
      apps = [];
    }
    _loaded = true;
  }

  static AppInfo? find(String packageName) {
    for (final a in apps) {
      if (a.packageName == packageName) return a;
    }
    return null;
  }
}

class AppIconView extends StatelessWidget {
  final String packageName;
  final double size;
  const AppIconView({super.key, required this.packageName, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final icon = AppsCache.find(packageName)?.icon;
    if (icon != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: Image.memory(icon, width: size, height: size),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Pal.card2,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: const Icon(Icons.apps, color: Pal.muted),
    );
  }
}
