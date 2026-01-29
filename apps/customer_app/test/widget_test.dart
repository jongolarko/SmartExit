// Basic widget test for SmartExit Customer App

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:customer_app/main.dart';

void main() {
  testWidgets('App initializes correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: SmartExitCustomerApp()));

    // Wait for async operations
    await tester.pumpAndSettle();

    // Verify that the app loads (should show either login screen or home screen)
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('AuthWrapper renders correctly', (WidgetTester tester) async {
    // Build the AuthWrapper
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AuthWrapper(),
        ),
      ),
    );

    // Wait for async operations
    await tester.pumpAndSettle();

    // Should render without errors
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
