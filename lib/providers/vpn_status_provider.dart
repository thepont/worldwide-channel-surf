import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldwide_channel_surf/models/typedefs.dart';

enum VpnStatus {
  disconnected,
  connecting,
  connected,
  error,
}

final vpnStatusProvider = StateProvider<VpnStatus>((ref) => VpnStatus.disconnected);

final vpnConnectedRegionProvider = StateProvider<RegionId?>((ref) => null);

