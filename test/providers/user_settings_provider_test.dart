import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldwide_channel_surf/providers/user_settings_provider.dart';
import 'package:worldwide_channel_surf/models/typedefs.dart';

void main() {
  group('currentRegionProvider', () {
    test('should start with null region', () {
      final container = ProviderContainer();
      final region = container.read(currentRegionProvider);

      expect(region, isNull);
    });

    test('should update current region', () {
      final container = ProviderContainer();
      final notifier = container.read(currentRegionProvider.notifier);

      notifier.state = 'UK';
      expect(container.read(currentRegionProvider), equals('UK'));

      notifier.state = 'FR';
      expect(container.read(currentRegionProvider), equals('FR'));

      notifier.state = 'AU';
      expect(container.read(currentRegionProvider), equals('AU'));
    });

    test('should allow resetting to null', () {
      final container = ProviderContainer();
      final notifier = container.read(currentRegionProvider.notifier);

      notifier.state = 'UK';
      expect(container.read(currentRegionProvider), equals('UK'));

      notifier.state = null;
      expect(container.read(currentRegionProvider), isNull);
    });

    test('should use RegionId type', () {
      final container = ProviderContainer();
      final notifier = container.read(currentRegionProvider.notifier);

      notifier.state = 'US';
      final region = container.read(currentRegionProvider);

      expect(region, isA<RegionId>());
    });
  });
}

