import 'package:flutter_test/flutter_test.dart';
import 'package:worldwide_channel_surf/models/channel.dart';
import 'package:worldwide_channel_surf/models/typedefs.dart';

void main() {
  group('Channel', () {
    test('should create a channel with all required fields', () {
      const channel = Channel(
        name: 'BBC iPlayer',
        url: 'https://www.bbc.co.uk/iplayer',
        targetRegionId: 'UK',
      );

      expect(channel.id, isNull); // New channels don't have an ID yet
      expect(channel.name, equals('BBC iPlayer'));
      expect(channel.url, equals('https://www.bbc.co.uk/iplayer'));
      expect(channel.targetRegionId, equals('UK'));
      expect(channel.targetRegionId, isA<RegionId>());
    });

    test('should create a channel with id from database', () {
      const channel = Channel(
        id: 1,
        name: 'BBC iPlayer',
        url: 'https://www.bbc.co.uk/iplayer',
        targetRegionId: 'UK',
      );

      expect(channel.id, equals(1));
      expect(channel.name, equals('BBC iPlayer'));
    });

    test('should support different regions', () {
      const ukChannel = Channel(
        name: 'BBC iPlayer',
        url: 'https://www.bbc.co.uk/iplayer',
        targetRegionId: 'UK',
      );

      const frChannel = Channel(
        name: 'TF1',
        url: 'https://www.tf1.fr',
        targetRegionId: 'FR',
      );

      expect(ukChannel.targetRegionId, equals('UK'));
      expect(frChannel.targetRegionId, equals('FR'));
    });

    test('should extract domain from URL for favicon', () {
      const channel = Channel(
        name: 'Test Channel',
        url: 'https://www.example.com',
        targetRegionId: 'US',
      );

      final domain = Uri.parse(channel.url).host;
      expect(domain, equals('www.example.com'));
    });

    test('should convert to map correctly', () {
      const channel = Channel(
        name: 'Test Channel',
        url: 'https://example.com',
        targetRegionId: 'US',
      );

      final map = channel.toMap();

      expect(map['name'], equals('Test Channel'));
      expect(map['url'], equals('https://example.com'));
      expect(map['targetRegionId'], equals('US'));
      expect(map.containsKey('id'), isFalse); // ID should not be in map
    });

    test('should create from map correctly', () {
      final map = {
        'id': 1,
        'name': 'Test Channel',
        'url': 'https://example.com',
        'targetRegionId': 'US',
      };

      final channel = Channel.fromMap(map);

      expect(channel.id, equals(1));
      expect(channel.name, equals('Test Channel'));
      expect(channel.url, equals('https://example.com'));
      expect(channel.targetRegionId, equals('US'));
    });

    test('should create from map without id', () {
      final map = {
        'name': 'Test Channel',
        'url': 'https://example.com',
        'targetRegionId': 'US',
      };

      final channel = Channel.fromMap(map);

      expect(channel.id, isNull);
      expect(channel.name, equals('Test Channel'));
    });
  });
}

