import 'package:flutter_test/flutter_test.dart';

import 'package:mindful_minute/main.dart';

void main() {
  testWidgets('Mindful Minute home screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MindfulMinuteApp());

    expect(find.text('Mindful Minute'), findsOneWidget);
  });
}