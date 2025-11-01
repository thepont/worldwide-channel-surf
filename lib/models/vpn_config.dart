import 'package:worldwide_channel_surf/models/typedefs.dart';

class VpnConfig {
  final int? id; // For sqflite auto-increment
  final String name;
  final RegionId regionId;
  final String templateId;
  
  // Field for template-based configs
  final String? serverAddress; // e.g., "uk1234.nordvpn.com"
  
  // Field for custom .ovpn file
  final String? customOvpnContent; // The raw string of the .ovpn file

  const VpnConfig({
    this.id,
    required this.name,
    required this.regionId,
    required this.templateId,
    this.serverAddress,
    this.customOvpnContent,
  });

  /// Convert to Map for sqflite storage
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'region_id': regionId,
      'template_id': templateId,
      'server_address': serverAddress,
      'custom_ovpn_content': customOvpnContent,
    };
  }

  /// Create from Map (sqflite result)
  factory VpnConfig.fromMap(Map<String, dynamic> map) {
    return VpnConfig(
      id: map['id'] as int?,
      name: map['name'] as String,
      regionId: map['region_id'] as String,
      templateId: map['template_id'] as String,
      serverAddress: map['server_address'] as String?,
      customOvpnContent: map['custom_ovpn_content'] as String?,
    );
  }

  /// Create a copy with updated fields
  VpnConfig copyWith({
    int? id,
    String? name,
    RegionId? regionId,
    String? templateId,
    String? serverAddress,
    String? customOvpnContent,
  }) {
    return VpnConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      regionId: regionId ?? this.regionId,
      templateId: templateId ?? this.templateId,
      serverAddress: serverAddress ?? this.serverAddress,
      customOvpnContent: customOvpnContent ?? this.customOvpnContent,
    );
  }
}

