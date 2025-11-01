class VpnTemplate {
  final String templateId; // e.g., "nordvpn", "custom_ovpn"
  final String name;       // e.g., "NordVPN", "Custom .ovpn File"
  
  const VpnTemplate({
    required this.templateId,
    required this.name,
  });
}

