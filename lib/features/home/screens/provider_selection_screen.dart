import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:worldwide_channel_surf/models/show_details.dart';
import 'package:worldwide_channel_surf/models/typedefs.dart';
import 'package:worldwide_channel_surf/features/browser/screens/browser_screen.dart';
import 'package:worldwide_channel_surf/core/vpn_orchestrator_service.dart';
import 'package:worldwide_channel_surf/providers/vpn_config_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen to display all available watch providers and regions for a show
/// Allows user to select which provider/region to use before opening browser
class ProviderSelectionScreen extends ConsumerStatefulWidget {
  final ShowSummary show;
  final List<WatchProvider> providers;

  const ProviderSelectionScreen({
    super.key,
    required this.show,
    required this.providers,
  });

  @override
  ConsumerState<ProviderSelectionScreen> createState() => _ProviderSelectionScreenState();
}

class _ProviderSelectionScreenState extends ConsumerState<ProviderSelectionScreen> {
  bool _isConnecting = false;
  String? _error;

  /// Group providers by region
  Map<RegionId, List<WatchProvider>> _groupProvidersByRegion() {
    final Map<RegionId, List<WatchProvider>> grouped = {};
    
    for (final provider in widget.providers) {
      if (!grouped.containsKey(provider.regionId)) {
        grouped[provider.regionId] = [];
      }
      grouped[provider.regionId]!.add(provider);
    }
    
    return grouped;
  }

  Future<void> _onProviderSelected(WatchProvider provider) async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
      _error = null;
    });

    // Check if VPN config exists for this region
    final vpnConfigs = ref.read(vpnConfigListProvider);
    final hasVpnConfig = vpnConfigs.any((config) => config.regionId == provider.regionId);

    if (!hasVpnConfig) {
      setState(() {
        _error = 'No VPN configured for region ${provider.regionId}. Please configure a VPN for this region first.';
        _isConnecting = false;
      });
      return;
    }

    try {
      // Connect to VPN if needed
      final orchestrator = ref.read(vpnOrchestratorProvider);
      final result = await orchestrator.connectToRegion(
        ref,
        provider.regionId,
      );

      // Handle VPN connection result
      switch (result) {
        case VpnConnectionResult.successVpn:
        case VpnConnectionResult.successNoVpnNeeded:
          // Navigate to browser screen
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => BrowserScreen(
                  url: provider.deepLink,
                  channelName: widget.show.name,
                ),
              ),
            );
          }
          break;

        case VpnConnectionResult.errorNoConfigFound:
          setState(() {
            _error = 'No VPN configured for region ${provider.regionId}';
            _isConnecting = false;
          });
          break;

        case VpnConnectionResult.errorFailedToConnect:
          setState(() {
            _error = 'Failed to connect to VPN for region ${provider.regionId}';
            _isConnecting = false;
          });
          break;
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedProviders = _groupProvidersByRegion();
    final regions = groupedProviders.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.show.name),
      ),
      body: _isConnecting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Connecting to VPN...'),
                ],
              ),
            )
          : _buildContent(groupedProviders, regions),
    );
  }

  Widget _buildContent(Map<RegionId, List<WatchProvider>> groupedProviders, List<RegionId> regions) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                });
              },
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
    }

    if (groupedProviders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No watch providers found for this content',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: regions.length,
      itemBuilder: (context, regionIndex) {
        final region = regions[regionIndex];
        final providers = groupedProviders[region]!;
        
        // Check if VPN config exists for this region
        final vpnConfigs = ref.read(vpnConfigListProvider);
        final hasVpnConfig = vpnConfigs.any((config) => config.regionId == region);

        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: ExpansionTile(
            leading: Icon(
              hasVpnConfig ? Icons.vpn_key : Icons.vpn_key_off,
              color: hasVpnConfig ? Colors.green : Colors.grey,
            ),
            title: Text(
              'Region: $region',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: hasVpnConfig ? null : Colors.grey,
              ),
            ),
            subtitle: Text(
              hasVpnConfig 
                  ? '${providers.length} provider${providers.length != 1 ? 's' : ''} available'
                  : 'No VPN configured',
              style: TextStyle(
                color: hasVpnConfig ? Colors.grey[600] : Colors.red[300],
              ),
            ),
            children: providers.map((provider) {
              return ListTile(
                enabled: hasVpnConfig,
                leading: provider.logoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: provider.logoUrl!,
                        width: 40,
                        height: 40,
                        placeholder: (context, url) => const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.movie),
                      )
                    : const Icon(Icons.movie),
                title: Text(provider.name),
                subtitle: Text('Region: ${provider.regionId}'),
                trailing: hasVpnConfig
                    ? const Icon(Icons.arrow_forward)
                    : const Icon(Icons.info_outline, color: Colors.grey),
                onTap: hasVpnConfig
                    ? () => _onProviderSelected(provider)
                    : null,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

