import 'package:flutter/material.dart';
import '../../models/user_preferences.dart';

extension WellnessActivityMeta on WellnessActivityType {
  IconData get icon {
    switch (this) {
      case WellnessActivityType.breathing:
        return Icons.air;
      case WellnessActivityType.miniGame:
        return Icons.sports_esports;
      case WellnessActivityType.reminders:
        return Icons.spa;
    }
  }

  String get blurb {
    switch (this) {
      case WellnessActivityType.breathing:
        return 'Follow the circle for one minute.';
      case WellnessActivityType.miniGame:
        return '15 mind-friendly games, one each break.';
      case WellnessActivityType.reminders:
        return 'Calming scenes, music, quotes, research and tips.';
    }
  }
}
