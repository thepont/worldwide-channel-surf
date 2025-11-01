import 'package:worldwide_channel_surf/models/typedefs.dart';

class VpnConfig {
  final String id;
  final String name;
  final RegionId regionId;
  final String templateId;
  
  // Field for template-based configs
  final String? serverAddress; // e.g., "uk1234.nordvpn.com"
  
  // Field for custom .ovpn file
  final String? customOvpnContent; // The raw string of the .ovpn file

  const VpnConfig({
    required this.id,
    required this.name,
    required this.regionId,
    required this.templateId,
    this.serverAddress,
    this.customOvpnContent,
  });
}

