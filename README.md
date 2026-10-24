# Mindful Minute update v6: a different song for every screen

## 1. Where each song plays

| File name (exact)           | Plays on                                     | Behavior                                                                 |
|-----------------------------|----------------------------------------------|--------------------------------------------------------------------------|
| `limit_screen.mp3`          | "You've reached your limit for {app}" screen | Loops, can't be turned off (even Home / screen off). Stops when you press Start Wellness Break. Resumes if you cancel back to this screen. Stops for good when you finish all activities. |
| `breathing.mp3`             | Breathing Exercise                           | Loops during the 60 seconds                                              |
| `mini_game.mp3`             | Minute Mini-Game                             | Loops during the 60 seconds                                              |
| `wellness_reminders.mp3`    | Wellness Reminders                           | Loops during the 60 seconds                                              |

Use 4 DIFFERENT songs so each one sounds distinct.

## 2. Set it up (one time)

1. In your project root (the folder with pubspec.yaml) create:
       assets/audio/
2. Copy your 4 mp3 files into it and rename them EXACTLY as in the table
   (lowercase, underscores, `.mp3`).
3. Open pubspec.yaml and add the `assets:` lines under `flutter:`
   (`assets:` must line up with `uses-material-design:`):

       flutter:
         uses-material-design: true
         assets:
           - assets/audio/

   The trailing `/` includes every file in the folder.
4. Run:
       flutter clean
       flutter pub get
       flutter run

## 3. Change a song later

Replace the mp3 in assets/audio/ (keep the same file name), then run
`flutter clean` and `flutter run` again. (`flutter clean` matters: without it
the old song can stay in the build.)

## 4. Troubleshooting

- **A screen plays soft synthetic tones instead of your song** -> that file is
  missing or misnamed (check spelling/case) or the `assets:` lines in
  pubspec.yaml are wrong. The app never crashes; it just falls back to the tones.
- **Silence on the limit screen** -> turn the phone's ALARM volume up
  (the limit-screen music uses the alarm channel so it works with media muted).
  The app also raises it automatically to about 70%.
- **Song doesn't start in an activity** -> it starts when you press Start,
  not before.
- Tips: mp3 (or m4a/ogg) works; keep each file under ~10 MB; a song that
  loops cleanly (no long silence at the end) sounds best.

## 5. Where the files go in this zip

Copy everything over your project (same paths). New/changed this time:
  lib/screens/activities/activity_music.dart   (NEW)
  lib/screens/activities/content_widgets.dart  (replace)
  lib/screens/activities/activity_runner.dart  (replace)
  android/.../BreakGuard.kt                    (replace)
