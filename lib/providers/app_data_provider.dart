import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldwide_channel_surf/core/database_service.dart';
import 'package:worldwide_channel_surf/models/channel.dart';

// Provider for the database service singleton
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// New provider that ASYNCHRONOUSLY loads channels from the database
final channelListProvider = FutureProvider<List<Channel>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getChannels();
});

