// This is a basic Flutter widget test.
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_coach/data/providers/connectivity_provider.dart';
import 'package:ai_coach/data/providers/recording_provider.dart';
import 'package:ai_coach/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final connectivity = ConnectivityProvider();
    final recording = RecordingProvider();
    await tester.pumpWidget(MyApp(
      connectivityProvider: connectivity,
      recordingProvider: recording,
    ));
    // Just verify the app renders without crashing
    expect(find.byType(MyApp), findsOneWidget);
  });
}
