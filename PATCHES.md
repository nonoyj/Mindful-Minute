# Small edits to existing files

## pubspec.yaml  (add under dependencies)
    flutter_background_service: ^5.1.0
    audioplayers: ^6.1.0
Then: flutter pub get

## lib/screens/history_screen.dart
Add import:   import '../services/session_service.dart';
In initState(), after _load();   SessionService.changes.addListener(_load);
Add:
    @override
    void dispose() {
      SessionService.changes.removeListener(_load);
      super.dispose();
    }

## lib/screens/preferences_screen.dart
1. import '../screens/activities/activity_meta.dart';   (optional, for icons)
2. In _showLimitDialog(), under `int limitMinutes = ...;` add:
       WellnessActivityType? chosenActivity = existing?.activity;
3. In the dialog's Column children, after the Slider, add:
       const SizedBox(height: 12),
       const Align(
         alignment: Alignment.centerLeft,
         child: Text('Break activity at 100%'),
       ),
       DropdownButton<WellnessActivityType?>(
         isExpanded: true,
         value: _prefs!.enabledActivities.contains(chosenActivity)
             ? chosenActivity
             : null,
         items: [
           const DropdownMenuItem(
               value: null, child: Text('Let me choose each time')),
           for (final t in _prefs!.enabledActivities)
             DropdownMenuItem(value: t, child: Text(t.label)),
         ],
         onChanged: (v) => setDialogState(() => chosenActivity = v),
       ),
4. In the Save button, add to MonitoredApp(...):   activity: chosenActivity,
5. (optional) list subtitle:
       subtitle: Text('${app.dailyLimitMinutes} min / day · ${app.activity?.label ?? 'choose each time'}'),

## test/widget_test.dart
The default test pumps the whole app, which now needs plugins (background
service). Delete it or mock the plugins.
