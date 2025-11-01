import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:worldwide_channel_surf/models/channel.dart';
import 'package:worldwide_channel_surf/models/typedefs.dart';
import 'package:worldwide_channel_surf/providers/app_data_provider.dart';
import 'package:worldwide_channel_surf/providers/user_settings_provider.dart';
import 'package:worldwide_channel_surf/core/geo_ip_service.dart';
import 'package:worldwide_channel_surf/core/vpn_orchestrator_service.dart';
import 'package:worldwide_channel_surf/features/browser/screens/browser_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger the initial IP lookup on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectInitialRegion();
    });
  }

  Future<void> _detectInitialRegion() async {
    // Only detect if no region is already set
    if (ref.read(currentRegionProvider) == null && mounted) {
      final region = await ref.read(geoIpServiceProvider).getRegionFromIp();
      if (mounted && region != null) {
        ref.read(currentRegionProvider.notifier).state = region;
      }
    }
  }

  Future<void> _onChannelTap(BuildContext context, Channel channel) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final orchestrator = ref.read(vpnOrchestratorProvider);
      final result = await orchestrator.connectToRegion(
        ref,
        channel.targetRegionId,
      );

      // Pop loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Handle result
      switch (result) {
        case VpnConnectionResult.successVpn:
        case VpnConnectionResult.successNoVpnNeeded:
          // Navigate to browser screen
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BrowserScreen(
                  url: channel.url,
                  channelName: channel.name,
                ),
              ),
            );
          }
          break;

        case VpnConnectionResult.errorNoConfigFound:
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'No VPN configured for region ${channel.targetRegionId}',
                ),
              ),
            );
          }
          break;

        case VpnConnectionResult.errorFailedToConnect:
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to connect to VPN'),
              ),
            );
          }
          break;
      }
    } catch (e) {
      // Pop loading dialog if still showing
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the new FutureProvider for the channel list
    final channelListAsync = ref.watch(channelListProvider);
    
    // Watch the user's current region
    final currentRegion = ref.watch(currentRegionProvider);

    // Get available regions from the channel list for the dropdown
    // We need to extract this from the async value when data is available
    List<RegionId> availableRegions = [];
    if (channelListAsync.hasValue) {
      availableRegions = channelListAsync.value!
          .map((ch) => ch.targetRegionId)
          .toSet()
          .toList()
        ..sort();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('International Channel Browser'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<RegionId?>(
              value: currentRegion,
              hint: const Text('Set Region', style: TextStyle(color: Colors.white)),
              underline: Container(), // Hides the underline
              icon: const Icon(Icons.public, color: Colors.white),
              dropdownColor: Colors.blueGrey[800],
              style: const TextStyle(color: Colors.white),
              onChanged: (RegionId? newValue) {
                ref.read(currentRegionProvider.notifier).state = newValue;
              },
              items: [
                const DropdownMenuItem<RegionId?>(
                  value: null,
                  child: Text('Auto-Detect'),
                ),
                ...availableRegions.map((region) => DropdownMenuItem<RegionId?>(
                      value: region,
                      child: Text(region),
                    )),
              ],
            ),
          ),
        ],
      ),
      body: channelListAsync.when(
        data: (channels) {
          // --- THIS IS THE FAVICON LOGIC FROM v8 ---
          return ListView.builder(
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              final domain = Uri.parse(channel.url).host;
              final faviconUrl = 'https://www.google.com/s2/favicons?domain=$domain&sz=64';

              return ListTile(
                title: Text(channel.name),
                subtitle: Text(channel.targetRegionId), // Good for debugging
                leading: SizedBox(
                  width: 40,
                  height: 40,
                  child: CachedNetworkImage(
                    imageUrl: faviconUrl,
                    placeholder: (context, url) => const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.tv,
                      color: Colors.grey,
                    ),
                    fadeInDuration: const Duration(milliseconds: 150),
                  ),
                ),
                trailing: channel.targetRegionId == currentRegion
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.vpn_key, color: Colors.orange),
                onTap: () => _onChannelTap(context, channel),
              );
            },
          );
        },
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading channels: ${err.toString()}'),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

