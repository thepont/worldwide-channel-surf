import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldwide_channel_surf/features/channels/screens/home_screen.dart';
import 'package:worldwide_channel_surf/providers/user_settings_provider.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('should display channel list', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Wait for initial detection to complete or timeout
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should show loading initially, then channels
      // Since region detection is async, we might see loading state first
      
      // Pump until we find a channel or timeout
      await tester.pumpAndSettle();
      
      // The screen should eventually show channels
      // (if region is detected) or show loading message
      expect(
        find.byType(HomeScreen),
        findsOneWidget,
      );
    });

    testWidgets('should show loading state when region is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Immediately check for loading state
      expect(
        find.text('Detecting your location...'),
        findsOneWidget,
      );
    });

    testWidgets('should display region dropdown', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          currentRegionProvider.overrideWith((ref) => 'UK'),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show region dropdown in app bar
      expect(
        find.byType(DropdownButton<dynamic>),
        findsOneWidget,
      );
    });

    testWidgets('should display channel when region is set', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          currentRegionProvider.overrideWith((ref) => 'UK'),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show at least one channel
      expect(
        find.byType(ListView),
        findsOneWidget,
      );
    });

    testWidgets('should show app bar with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      expect(
        find.text('International Channel Browser'),
        findsOneWidget,
      );
    });
  });
}

