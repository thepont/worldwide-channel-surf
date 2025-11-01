import 'package:flutter_test/flutter_test.dart';
import 'package:worldwide_channel_surf/core/database_service.dart';
import 'package:worldwide_channel_surf/models/channel.dart';

void main() {
  group('DatabaseService', () {
    late DatabaseService service;

    setUp(() {
      service = DatabaseService();
    });

    test('should be a singleton', () {
      final service1 = DatabaseService();
      final service2 = DatabaseService();

      expect(service1, equals(service2));
    });

    test('should initialize database', () async {
      final db = await service.database;
      expect(db, isNotNull);
      expect(db.isOpen, isTrue);
    });

    test('should seed database with default channels', () async {
      final channels = await service.getChannels();

      expect(channels.length, greaterThan(0));

      // Check that seeded channels exist
      final channelNames = channels.map((ch) => ch.name).toList();
      expect(channelNames, contains('BBC iPlayer'));
      expect(channelNames, contains('ABC iview'));
      expect(channelNames, contains('10 Play'));
      expect(channelNames, contains('France.tv'));
    });

    test('should return channels sorted by name', () async {
      final channels = await service.getChannels();

      // Verify channels are sorted
      for (int i = 0; i < channels.length - 1; i++) {
        expect(
          channels[i].name.compareTo(channels[i + 1].name),
          lessThanOrEqualTo(0),
        );
      }
    });

    test('should return channels with database IDs', () async {
      final channels = await service.getChannels();

      for (final channel in channels) {
        expect(channel.id, isNotNull);
        expect(channel.id, isA<int>());
        expect(channel.id, greaterThan(0));
      }
    });

    test('should include all required channel properties', () async {
      final channels = await service.getChannels();

      for (final channel in channels) {
        expect(channel.name, isNotEmpty);
        expect(channel.url, isNotEmpty);
        expect(channel.targetRegionId, isNotEmpty);
        expect(channel.url, startsWith('http'));
      }
    });

    test('should include channels from all regions', () async {
      final channels = await service.getChannels();

      final regions = channels.map((ch) => ch.targetRegionId).toSet();
      
      expect(regions, contains('UK'));
      expect(regions, contains('FR'));
      expect(regions, contains('AU'));
    });
  });
}

