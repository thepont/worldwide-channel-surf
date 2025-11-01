import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldwide_channel_surf/providers/app_data_provider.dart';
import 'package:worldwide_channel_surf/models/channel.dart';
import 'package:worldwide_channel_surf/core/database_service.dart';

void main() {
  group('databaseServiceProvider', () {
    test('should provide a DatabaseService singleton', () {
      final container = ProviderContainer();
      final service1 = container.read(databaseServiceProvider);
      final service2 = container.read(databaseServiceProvider);

      expect(service1, isA<DatabaseService>());
      expect(service1, equals(service2)); // Should be the same instance
    });
  });

  group('channelListProvider', () {
    test('should provide a FutureProvider', () {
      final container = ProviderContainer();
      final providerValue = container.read(channelListProvider);

      expect(providerValue, isA<AsyncValue<List<Channel>>>());
    });

    test('should load channels from database', () async {
      final container = ProviderContainer();
      
      // Wait for the async provider to complete
      await container.read(channelListProvider.future);

      final asyncValue = container.read(channelListProvider);
      expect(asyncValue.hasValue, isTrue);
      
      final channels = asyncValue.value!;
      expect(channels, isA<List<Channel>>());
      expect(channels.length, greaterThan(0));
    });

    test('should include BBC iPlayer with UK region', () async {
      final container = ProviderContainer();
      
      final channels = await container.read(channelListProvider.future);

      final bbcChannel = channels.firstWhere(
        (ch) => ch.name == 'BBC iPlayer',
      );

      expect(bbcChannel.targetRegionId, equals('UK'));
      expect(bbcChannel.url, contains('bbc.co.uk'));
      expect(bbcChannel.id, isNotNull); // Should have an ID from DB
    });

    test('should include seeded channels', () async {
      final container = ProviderContainer();
      
      final channels = await container.read(channelListProvider.future);

      // Check for various seeded channels
      final channelNames = channels.map((ch) => ch.name).toList();
      
      expect(channelNames, contains('BBC iPlayer'));
      expect(channelNames, contains('ABC iview'));
      expect(channelNames, contains('10 Play'));
      expect(channelNames, contains('France.tv'));
    });

    test('should provide channels sorted by name', () async {
      final container = ProviderContainer();
      
      final channels = await container.read(channelListProvider.future);

      // Verify channels are sorted alphabetically
      for (int i = 0; i < channels.length - 1; i++) {
        expect(
          channels[i].name.compareTo(channels[i + 1].name),
          lessThanOrEqualTo(0),
          reason: 'Channels should be sorted by name',
        );
      }
    });
  });
}

