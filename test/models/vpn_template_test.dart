import 'package:flutter_test/flutter_test.dart';
import 'package:worldwide_channel_surf/models/vpn_template.dart';

void main() {
  group('VpnTemplate', () {
    test('should create a VpnTemplate with all required fields', () {
      const template = VpnTemplate(
        templateId: 'nordvpn',
        name: 'NordVPN',
      );

      expect(template.templateId, equals('nordvpn'));
      expect(template.name, equals('NordVPN'));
    });

    test('should support custom template types', () {
      const customTemplate = VpnTemplate(
        templateId: 'custom_ovpn',
        name: 'Custom .ovpn File',
      );

      expect(customTemplate.templateId, equals('custom_ovpn'));
      expect(customTemplate.name, equals('Custom .ovpn File'));
    });
  });
}

