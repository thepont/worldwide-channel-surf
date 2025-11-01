import 'package:worldwide_channel_surf/models/typedefs.dart';

class Channel {
  final int? id; // Nullable for new channels not yet in DB
  final String name;
  final String url;
  final RegionId targetRegionId;

  const Channel({
    this.id,
    required this.name,
    required this.url,
    required this.targetRegionId,
  });

  // Factory constructor to create a Channel from a map
  factory Channel.fromMap(Map<String, dynamic> map) {
    return Channel(
      id: map['id'] as int?,
      name: map['name'] as String,
      url: map['url'] as String,
      targetRegionId: map['targetRegionId'] as String,
    );
  }

  // Method to convert a Channel to a map (for inserting into DB)
  // Note: 'id' is omitted here because the DB will auto-increment it
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
      'targetRegionId': targetRegionId,
    };
  }
}

