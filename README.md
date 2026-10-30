# Mindful Minute update v8

1. Copy `lib/` and `android/` over your project (same paths, replace files).
2. NEW files: lib/screens/help_screens.dart, android/.../MonitorService.kt,
   android/.../BootReceiver.kt
3. Open lib/screens/help_screens.dart and edit the 3 lines at the top:
   kAppVersion and kFeedbackEmail (feedback goes to that email).
   Developer names are in `kDevelopers` in the same file.
4. pubspec.yaml: you can now DELETE the line `flutter_background_service: ...`
   (it is no longer used). Then:
       flutter clean
       flutter pub get
       flutter run
5. On the phone: Settings tab -> grant permissions. Then add/turn on a break.
   You can now swipe the app away; the monitor keeps running.

If monitoring still stops on your phone after swiping the app away (common on
Infinix/XOS, Xiaomi, Oppo, Vivo, Huawei): phone Settings -> Apps -> Mindful
Minute -> allow "Autostart", battery "No restrictions", and lock the app in
Recents. Android phones differ; the FAQ in the app explains the same steps.
