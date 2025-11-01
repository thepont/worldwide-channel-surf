import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldwide_channel_surf/models/vpn_template.dart';
import 'package:worldwide_channel_surf/models/vpn_config.dart';

final vpnTemplateListProvider = Provider<List<VpnTemplate>>((ref) {
  return const [
    VpnTemplate(templateId: "nordvpn", name: "NordVPN"),
    VpnTemplate(templateId: "custom_ovpn", name: "Custom .ovpn File"),
  ];
});

class VpnTemplateService {
  String generateConfigString(VpnConfig config) {
    switch (config.templateId) {
      case "custom_ovpn":
        return config.customOvpnContent ?? "";
      
      case "nordvpn":
        // Generate a placeholder NordVPN config template
        // In a real implementation, this would be more sophisticated
        final serverAddress = config.serverAddress ?? "";
        return '''
# NordVPN Configuration
# Generated for region: ${config.regionId}
# Server: $serverAddress

client
dev tun
proto udp
remote $serverAddress 1194
resolv-retry infinite
nobind
persist-key
persist-tun
verb 3
cipher AES-256-CBC
auth SHA256
''';

      default:
        return "";
    }
  }
}

final vpnTemplateServiceProvider = Provider<VpnTemplateService>((ref) => VpnTemplateService());

