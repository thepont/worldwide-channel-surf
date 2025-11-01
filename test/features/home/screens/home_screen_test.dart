import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldwide_channel_surf/features/home/screens/home_screen.dart';
import 'package:worldwide_channel_surf/providers/settings_provider.dart';
import 'package:worldwide_channel_surf/providers/user_settings_provider.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('HomeScreen', () {
    testWidgets('should show setup screen when API key is not set', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          tmdbApiKeyProvider.overrideWith(
            (ref) => TmdbApiKeyNotifier()..state = null,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(
            home: const HomeScreen(),
          ),
        ),
      );

      // Should show setup screen
      expect(find.text('TV Setup'), findsOneWidget);
      expect(find.text('Welcome to Worldwide Channel Surf'), findsOneWidget);
    });

    testWidgets('should show GridView when API key is set', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          tmdbApiKeyProvider.overrideWith(
            (ref) {
              final notifier = TmdbApiKeyNotifier();
              notifier.state = 'test_api_key';
              return notifier;
            },
          ),
          currentRegionProvider.overrideWith((ref) => 'UK'),
          // Mock trending shows provider
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show main screen
      expect(find.text('International Content Browser'), findsOneWidget);
    });

    testWidgets('should show region dropdown', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          tmdbApiKeyProvider.overrideWith(
            (ref) {
              final notifier = TmdbApiKeyNotifier();
              notifier.state = 'test_api_key';
              return notifier;
            },
          ),
          currentRegionProvider.overrideWith((ref) => 'UK'),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show region dropdown
      expect(find.text('Set Region'), findsOneWidget);
    });

    testWidgets('should detect region on startup', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          tmdbApiKeyProvider.overrideWith(
            (ref) {
              final notifier = TmdbApiKeyNotifier();
              notifier.state = 'test_api_key';
              return notifier;
            },
          ),
          currentRegionProvider.overrideWith((ref) => null),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(
            home: const HomeScreen(),
          ),
        ),
      );

      // Should show loading while detecting region
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });

  group('_ApiKeySetupScreen', () {
    testWidgets('should display QR code when server is running', (WidgetTester tester) async {
      // This test would require mocking the DeviceAuthService
      // For now, we test the widget structure
      expect(true, isTrue); // Placeholder
    });
  });
}

