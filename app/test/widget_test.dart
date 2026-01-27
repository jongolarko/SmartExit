// SmartExit Widget Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:smartexit_app/main.dart';

void main() {
  testWidgets('SmartExit app launches and shows role selection', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartExitApp());

    // Wait for animations to settle
    await tester.pumpAndSettle();

    // Verify the app loads with the SmartExit branding
    expect(find.text('SmartExit'), findsOneWidget);

    // Verify role selection options are present
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });
}
