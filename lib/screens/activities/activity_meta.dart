import 'package:flutter/material.dart';
import '../../models/user_preferences.dart';

extension WellnessActivityMeta on WellnessActivityType {
  IconData get icon {
    switch (this) {
      case WellnessActivityType.breathing:
        return Icons.air;
      case WellnessActivityType.quotes:
        return Icons.format_quote;
      case WellnessActivityType.miniGame:
        return Icons.sports_esports;
      case WellnessActivityType.audio:
        return Icons.headphones;
      case WellnessActivityType.video:
        return Icons.waves;
      case WellnessActivityType.textReminder:
        return Icons.checklist;
    }
  }

  String get blurb {
    switch (this) {
      case WellnessActivityType.breathing:
        return 'Follow the circle for one minute.';
      case WellnessActivityType.quotes:
        return 'A few nudges to get you moving.';
      case WellnessActivityType.miniGame:
        return 'A quick, calm game.';
      case WellnessActivityType.audio:
        return 'Soft ambient sound. Close your eyes.';
      case WellnessActivityType.video:
        return 'Gentle moving waves to rest your eyes.';
      case WellnessActivityType.textReminder:
        return 'Small self-care reminders.';
    }
  }
}
