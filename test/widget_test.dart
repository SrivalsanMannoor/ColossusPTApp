import 'package:flutter_test/flutter_test.dart';
import 'package:colossus_pt/main.dart';
import 'package:colossus_pt/providers/workout_provider.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    final provider = WorkoutProvider();
    // Build our app and trigger a frame.
    await tester.pumpWidget(ColossusApp(provider: provider));

    // Verify the app launches (login screen displays)
    expect(find.byType(ColossusApp), findsOneWidget);
  });
}
