import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldwide_channel_surf/models/typedefs.dart';
import 'package:worldwide_channel_surf/core/database_service.dart';

final currentRegionProvider = StateProvider<RegionId?>((ref) => null);

/// Provider for region usage statistics
final regionUsageProvider = FutureProvider<Map<RegionId, int>>((ref) {
  final dbService = DatabaseService();
  return dbService.getRegionUsage();
});

