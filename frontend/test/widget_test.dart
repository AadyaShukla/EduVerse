import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EduVerseApp());

    // Verify that the splash screen shows up.
    expect(find.text('EduVerse'), findsOneWidget);

    // Fast-forward to the end of the splash screen timer
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
