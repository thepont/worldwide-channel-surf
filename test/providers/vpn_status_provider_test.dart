import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldwide_channel_surf/providers/vpn_status_provider.dart';
import 'package:worldwide_channel_surf/models/typedefs.dart';

void main() {
  group('vpnStatusProvider', () {
    test('should start with disconnected status', () {
      final container = ProviderContainer();
      final status = container.read(vpnStatusProvider);

      expect(status, equals(VpnStatus.disconnected));
    });

    test('should update VPN status', () {
      final container = ProviderContainer();
      final notifier = container.read(vpnStatusProvider.notifier);

      notifier.state = VpnStatus.connecting;
      expect(container.read(vpnStatusProvider), equals(VpnStatus.connecting));

      notifier.state = VpnStatus.connected;
      expect(container.read(vpnStatusProvider), equals(VpnStatus.connected));

      notifier.state = VpnStatus.error;
      expect(container.read(vpnStatusProvider), equals(VpnStatus.error));
    });
  });

  group('vpnConnectedRegionProvider', () {
    test('should start with null region', () {
      final container = ProviderContainer();
      final region = container.read(vpnConnectedRegionProvider);

      expect(region, isNull);
    });

    test('should update connected region', () {
      final container = ProviderContainer();
      final notifier = container.read(vpnConnectedRegionProvider.notifier);

      notifier.state = 'UK';
      expect(container.read(vpnConnectedRegionProvider), equals('UK'));

      notifier.state = 'FR';
      expect(container.read(vpnConnectedRegionProvider), equals('FR'));

      notifier.state = null;
      expect(container.read(vpnConnectedRegionProvider), isNull);
    });

    test('should use RegionId type', () {
      final container = ProviderContainer();
      final notifier = container.read(vpnConnectedRegionProvider.notifier);

      notifier.state = 'AU';
      final region = container.read(vpnConnectedRegionProvider);

      expect(region, isA<RegionId>());
    });
  });
}

