import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldwide_channel_surf/features/browser/screens/browser_screen.dart';

void main() {
  group('BrowserScreen', () {
    testWidgets('should display browser with URL', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BrowserScreen(
              url: 'https://www.bbc.co.uk/iplayer',
              channelName: 'BBC iPlayer',
            ),
          ),
        ),
      );

      // Should show the channel name in app bar
      expect(
        find.text('BBC iPlayer'),
        findsOneWidget,
      );

      // Should show refresh button
      expect(
        find.byIcon(Icons.refresh),
        findsOneWidget,
      );
    });

    testWidgets('should display different channel names', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BrowserScreen(
              url: 'https://www.tf1.fr',
              channelName: 'TF1',
            ),
          ),
        ),
      );

      expect(
        find.text('TF1'),
        findsOneWidget,
      );
    });

    testWidgets('should have app bar with refresh action', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BrowserScreen(
              url: 'https://example.com',
              channelName: 'Test Channel',
            ),
          ),
        ),
      );

      expect(
        find.byType(AppBar),
        findsOneWidget,
      );

      expect(
        find.byIcon(Icons.refresh),
        findsOneWidget,
      );
    });
  });
}

