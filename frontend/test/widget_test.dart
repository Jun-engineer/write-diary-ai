// Basic Flutter widget test for Write Diary AI.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:write_diary_ai/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: WriteDiaryAiApp(),
      ),
    );

    // Verify the app title is rendered
    expect(find.text('Write Diary AI'), findsOneWidget);
  });
}
